if SERVER then
    AddCSLuaFile("autorun/client/flashlight_battery_cl.lua")
    AddCSLuaFile("flashlight_battery/sh_config.lua")
    include("flashlight_battery/sh_config.lua")

    util.AddNetworkString(FlashlightBattery.NetSetConVar)

    local CVAR_FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
    local convars = {}

    for _, setting in ipairs(FlashlightBattery.ServerSettings) do
        convars[setting.name] = CreateConVar(
            setting.name,
            tostring(setting.default),
            CVAR_FLAGS,
            setting.description,
            setting.min,
            setting.max
        )
    end

    local NW_BATTERY = "FB_Battery"
    local NW_COOLDOWN = "FB_Cooldown"
    local NW_COOLDOWN_END = "FB_CooldownEnd"

    local function FB_CanConfigure(ply)
        return game.SinglePlayer() or (IsValid(ply) and (ply:IsAdmin() or (ply.IsListenServerHost and ply:IsListenServerHost())))
    end

    local function FB_RoundValue(value, decimals)
        local multiplier = 10 ^ decimals
        return math.floor(value * multiplier + 0.5) / multiplier
    end

    net.Receive(FlashlightBattery.NetSetConVar, function(_, ply)
        if not FB_CanConfigure(ply) then return end

        local name = net.ReadString()
        local value = net.ReadFloat()
        local setting = FlashlightBattery.ServerSettingByName[name]
        if not setting or not isnumber(value) then return end

        value = FB_RoundValue(math.Clamp(value, setting.min, setting.max), setting.decimals)
        RunConsoleCommand(name, tostring(value))
    end)

    local function FB_InitPlayer(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        ply:SetNWFloat(NW_BATTERY, 100)
        ply:SetNWBool(NW_COOLDOWN, false)
        ply:SetNWFloat(NW_COOLDOWN_END, 0)
        ply.__fb_next_recharge = 0
        ply.__fb_last_tick = CurTime()
        ply.__fb_depleted_notified = false
        ply.__fb_minimum_notified = false
    end

    local function FB_IsEnabled()
        return convars.fb_enabled:GetBool()
    end

    local function FB_ShouldNotify()
        return convars.fb_center_notifications:GetBool()
    end

    local function FB_Notify(ply, message)
        if not FB_ShouldNotify() or not IsValid(ply) then return end

        ply:PrintMessage(HUD_PRINTTALK, message)
    end

    hook.Add("PlayerInitialSpawn", "FB_InitPlayer", function(ply)
        FB_InitPlayer(ply)
    end)

    hook.Add("PlayerSpawn", "FB_ResetOnSpawn", function(ply)
        FB_InitPlayer(ply)
    end)

    hook.Add("PlayerSwitchFlashlight", "FB_BlockFlashlightWhenDepletedOrCooling", function(ply, enabled)
        if not IsValid(ply) then return end
        if not FB_IsEnabled() then return end

        local battery = ply:GetNWFloat(NW_BATTERY, 100)
        local cooling = ply:GetNWBool(NW_COOLDOWN, false)
        local minimumBattery = convars.fb_min_battery_to_turn_on:GetFloat()

        if enabled then
            if cooling or battery <= 0 then
                FB_Notify(ply, "Flashlight battery cooling down")
                return false
            end

            if battery < minimumBattery then
                if not ply.__fb_minimum_notified then
                    FB_Notify(ply, string.format("Flashlight requires %d%% battery", math.floor(minimumBattery + 0.5)))
                    ply.__fb_minimum_notified = true
                end

                return false
            end
        end

        if enabled then
            ply.__fb_minimum_notified = false
        end

    end)

    local TICK_NAME = "FB_Tick"
    local TICK_INTERVAL = 0.1

    timer.Create(TICK_NAME, TICK_INTERVAL, 0, function()
        local drainTime = convars.fb_drain_time:GetFloat()
        local rechargeStep = convars.fb_recharge_step:GetFloat()
        local rechargeInterval = convars.fb_recharge_interval:GetFloat()
        local cooldownDur = convars.fb_cooldown:GetFloat()
        local minimumBattery = convars.fb_min_battery_to_turn_on:GetFloat()
        local now = CurTime()

        if not FB_IsEnabled() then return end

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                if ply:GetNWFloat(NW_BATTERY, -1) < 0 then
                    FB_InitPlayer(ply)
                end

                local battery = ply:GetNWFloat(NW_BATTERY, 100)
                local cooling = ply:GetNWBool(NW_COOLDOWN, false)
                local cooldownEnd = ply:GetNWFloat(NW_COOLDOWN_END, 0)
                local lastTick = ply.__fb_last_tick or now
                local elapsed = math.Clamp(now - lastTick, 0, 1)
                ply.__fb_last_tick = now

                if cooling and now >= cooldownEnd then
                    ply:SetNWBool(NW_COOLDOWN, false)
                    cooling = false
                    ply.__fb_depleted_notified = false
                    ply.__fb_minimum_notified = false
                    FB_Notify(ply, "Flashlight battery ready")
                end

                if ply:FlashlightIsOn() then
                    ply.__fb_next_recharge = now + rechargeInterval

                    if battery > 0 then
                        battery = math.max(0, battery - (elapsed / drainTime) * 100)
                        ply:SetNWFloat(NW_BATTERY, battery)
                    end

                    if battery <= 0 then
                        if ply:FlashlightIsOn() then
                            ply:Flashlight(false)
                        end

                        if not ply.__fb_depleted_notified then
                            FB_Notify(ply, "Flashlight battery depleted")
                            ply.__fb_depleted_notified = true
                        end

                        if cooldownDur > 0 and not cooling then
                            ply:SetNWBool(NW_COOLDOWN, true)
                            ply:SetNWFloat(NW_COOLDOWN_END, now + cooldownDur)
                        end
                    end
                else
                    if not cooling and battery < 100 then
                        ply.__fb_next_recharge = ply.__fb_next_recharge or (now + rechargeInterval)
                        if now >= ply.__fb_next_recharge then
                            ply.__fb_next_recharge = now + rechargeInterval
                            battery = math.min(100, battery + rechargeStep)
                            ply:SetNWFloat(NW_BATTERY, battery)
                        end

                        if battery >= minimumBattery and battery > 0 then
                            ply.__fb_depleted_notified = false
                            ply.__fb_minimum_notified = false
                        end
                    else
                        ply.__fb_next_recharge = now + rechargeInterval
                    end
                end
            end
        end
    end)
end
