local convars = FlashlightBattery.ConVars
local nw = FlashlightBattery.NW

local TICK_NAME = "FB_Tick"
local TICK_INTERVAL = 0.1

local notifyConVars = {
    depleted = "fb_notify_depleted",
    ready = "fb_notify_ready",
    blocked = "fb_notify_blocked",
    low = "fb_notify_low_battery",
    pickup = "fb_notify_pickup_refill"
}

local function RoundValue(value, decimals)
    local multiplier = 10 ^ decimals
    return math.floor(value * multiplier + 0.5) / multiplier
end

local function IsEnabled()
    return convars.fb_enabled:GetBool()
end

local function ShouldNotify(notificationType)
    local convarName = notifyConVars[notificationType]
    local convar = convarName and convars[convarName]

    return convars.fb_center_notifications:GetBool() and (not convar or convar:GetBool())
end

local function Notify(ply, notificationType, message)
    if not ShouldNotify(notificationType) or not IsValid(ply) then return end

    ply:PrintMessage(HUD_PRINTTALK, message)
end

local function SetCooldown(ply, active, endTime)
    if ply.__fb_cooling == active and ply.__fb_cooldown_end == endTime then return end

    ply.__fb_cooling = active
    ply.__fb_cooldown_end = endTime
    ply:SetNW2Bool(nw.Cooldown, active)
    ply:SetNW2Float(nw.CooldownEnd, endTime)
end

local function SetBattery(ply, battery)
    battery = math.Clamp(battery, 0, 100)
    ply.__fb_battery = battery

    local networkedBattery = RoundValue(battery, 1)
    if ply.__fb_networked_battery == networkedBattery then return end

    ply.__fb_networked_battery = networkedBattery
    ply:SetNW2Float(nw.Battery, networkedBattery)
end

local function InitPlayer(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    ply.__fb_next_recharge = 0
    ply.__fb_last_tick = CurTime()
    ply.__fb_depleted_notified = false
    ply.__fb_minimum_notified = false
    ply.__fb_low_battery_notified = false
    ply.__fb_networked_battery = nil

    SetBattery(ply, 100)
    SetCooldown(ply, false, 0)
end

local function GetBattery(ply)
    if ply.__fb_battery == nil then
        InitPlayer(ply)
    end

    return ply.__fb_battery or 100
end

function FlashlightBattery.GetBattery(ply)
    if not IsValid(ply) or not ply:IsPlayer() then return 100 end

    return GetBattery(ply)
end

function FlashlightBattery.SetBattery(ply, battery)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end

    local oldBattery = GetBattery(ply)
    SetBattery(ply, battery)

    return GetBattery(ply) - oldBattery
end

function FlashlightBattery.RefillBatteryFromPickup(ply, modeOverride, ignorePickupEnabled)
    if not IsValid(ply) or not ply:IsPlayer() then return 0 end
    if not ignorePickupEnabled and not convars.fb_pickup_enabled:GetBool() then return 0 end

    local currentBattery = GetBattery(ply)
    if currentBattery >= 100 then return 0 end

    local mode = modeOverride or convars.fb_pickup_refill_mode:GetString()
    local targetBattery

    if mode == "full" then
        targetBattery = 100
    elseif mode == "missing_percent" then
        local percent = convars.fb_pickup_refill_missing_percent:GetFloat() / 100
        targetBattery = currentBattery + (100 - currentBattery) * percent
    elseif mode == "multiplier" then
        targetBattery = currentBattery * convars.fb_pickup_refill_multiplier:GetFloat()
    else
        targetBattery = currentBattery + convars.fb_pickup_refill_amount:GetFloat()
    end

    targetBattery = math.Clamp(targetBattery, currentBattery, 100)
    if targetBattery <= currentBattery then return 0 end

    SetBattery(ply, targetBattery)

    if targetBattery > 0 then
        ply.__fb_depleted_notified = false
    end

    if targetBattery >= convars.fb_min_battery_to_turn_on:GetFloat() then
        ply.__fb_minimum_notified = false
    end

    if targetBattery > convars.fb_low_battery_warning_threshold:GetFloat() then
        ply.__fb_low_battery_notified = false
    end

    return targetBattery - currentBattery
end

function FlashlightBattery.NotifyPickupRefill(ply, restored)
    if restored <= 0 then return end

    Notify(ply, "pickup", string.format("Flashlight battery +%d%%", math.floor(restored + 0.5)))
end

hook.Add("PlayerInitialSpawn", "FB_InitPlayer", function(ply)
    InitPlayer(ply)
end)

hook.Add("PlayerSpawn", "FB_ResetOnSpawn", function(ply)
    InitPlayer(ply)
end)

hook.Add("PlayerSwitchFlashlight", "FB_BlockFlashlightWhenDepletedOrCooling", function(ply, enabled)
    if not IsValid(ply) then return nil end
    if not IsEnabled() then return nil end

    if enabled then
        local battery = GetBattery(ply)
        local cooling = ply.__fb_cooling or false
        local minimumBattery = convars.fb_min_battery_to_turn_on:GetFloat()

        if cooling then
            Notify(ply, "blocked", "Flashlight battery cooling down")
            return false
        end

        if battery <= 0 then
            Notify(ply, "blocked", "Flashlight battery depleted")
            return false
        end

        if battery < minimumBattery then
            if not ply.__fb_minimum_notified then
                Notify(ply, "blocked", string.format("Flashlight requires %d%% battery", math.floor(minimumBattery + 0.5)))
                ply.__fb_minimum_notified = true
            end

            return false
        end

        ply.__fb_minimum_notified = false
    end

    return nil
end)

timer.Create(TICK_NAME, TICK_INTERVAL, 0, function()
    if not IsEnabled() then return end

    local drainTime = convars.fb_drain_time:GetFloat()
    local rechargeStep = convars.fb_recharge_step:GetFloat()
    local rechargeInterval = convars.fb_recharge_interval:GetFloat()
    local cooldownDuration = convars.fb_cooldown:GetFloat()
    local minimumBattery = convars.fb_min_battery_to_turn_on:GetFloat()
    local lowBatteryThreshold = convars.fb_low_battery_warning_threshold:GetFloat()
    local now = CurTime()

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local battery = GetBattery(ply)
            local cooling = ply.__fb_cooling or false
            local cooldownEnd = ply.__fb_cooldown_end or 0
            local lastTick = ply.__fb_last_tick or now
            local elapsed = math.Clamp(now - lastTick, 0, 1)

            ply.__fb_last_tick = now

            if cooling and now >= cooldownEnd then
                cooling = false
                SetCooldown(ply, false, 0)
                ply.__fb_depleted_notified = false
                ply.__fb_minimum_notified = false
                ply.__fb_low_battery_notified = false
                Notify(ply, "ready", "Flashlight battery ready")
            end

            if FlashlightBattery.IsFlashlightOn(ply) then
                ply.__fb_next_recharge = now + rechargeInterval

                if battery > 0 then
                    battery = math.max(0, battery - (elapsed / drainTime) * 100)
                    SetBattery(ply, battery)

                    if lowBatteryThreshold > 0 and battery <= lowBatteryThreshold and not ply.__fb_low_battery_notified then
                        Notify(ply, "low", string.format("Flashlight battery low (%d%%)", math.floor(battery + 0.5)))
                        ply.__fb_low_battery_notified = true
                    end
                end

                if battery <= 0 then
                    FlashlightBattery.ForceFlashlightOff(ply)

                    if not ply.__fb_depleted_notified then
                        Notify(ply, "depleted", "Flashlight battery depleted")
                        ply.__fb_depleted_notified = true
                    end

                    if cooldownDuration > 0 and not cooling then
                        SetCooldown(ply, true, now + cooldownDuration)
                    end
                end
            elseif not cooling and battery < 100 then
                ply.__fb_next_recharge = ply.__fb_next_recharge or (now + rechargeInterval)

                if not convars.fb_recharge_requires_pickups:GetBool() and now >= ply.__fb_next_recharge then
                    ply.__fb_next_recharge = now + rechargeInterval
                    battery = math.min(100, battery + rechargeStep)
                    SetBattery(ply, battery)
                end

                if battery >= minimumBattery and battery > 0 then
                    ply.__fb_depleted_notified = false
                    ply.__fb_minimum_notified = false
                end

                if lowBatteryThreshold <= 0 or battery > lowBatteryThreshold then
                    ply.__fb_low_battery_notified = false
                end
            else
                ply.__fb_next_recharge = now + rechargeInterval
            end
        end
    end
end)
