-- Flashlight Battery - Server Logic

if SERVER then
    AddCSLuaFile("autorun/client/flashlight_battery_cl.lua")

    -- ConVars (server-side configurable)
    -- Total time (in seconds) to drain from 100% to 0% while flashlight is ON (default: 60 seconds = 1 minute)
    local cv_drain_time = CreateConVar("fb_drain_time", "50", FCVAR_ARCHIVE, "Time in seconds to fully drain flashlight from 100% to 0% while ON.")
    -- Recharge step in percent per tick (default: 2% per tick)
    local cv_recharge_step = CreateConVar("fb_recharge_step", "2", FCVAR_ARCHIVE, "Recharge step in percentage per recharge tick when OFF and not cooling.")
    -- Recharge tick interval in seconds (default: 0.5 seconds)
    local cv_recharge_interval = CreateConVar("fb_recharge_interval", "0.5", FCVAR_ARCHIVE, "Recharge interval in seconds when OFF and not cooling.")
    -- Cooldown (in seconds) before recharge begins after battery hits 0% (default: 5 seconds)
    local cv_cooldown = CreateConVar("fb_cooldown", "10", FCVAR_ARCHIVE, "Cooldown in seconds after full drain before recharging starts.")

    -- Networked var keys
    local NW_BATTERY = "FB_Battery"
    local NW_COOLDOWN = "FB_Cooldown"
    local NW_COOLDOWN_END = "FB_CooldownEnd"

    -- Utility: Initialize battery/cooldown for a player
    local function FB_InitPlayer(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end
        ply:SetNWFloat(NW_BATTERY, 100)
        ply:SetNWBool(NW_COOLDOWN, false)
        ply:SetNWFloat(NW_COOLDOWN_END, 0)
    end

    hook.Add("PlayerInitialSpawn", "FB_InitPlayer", function(ply)
        FB_InitPlayer(ply)
    end)

    hook.Add("PlayerSpawn", "FB_ResetOnSpawn", function(ply)
        -- Always spawn with full battery and no cooldown
        FB_InitPlayer(ply)
        ply.__fb_tick_acc = 0
    end)

    -- Enforce toggle rules based on battery/cooldown
    hook.Add("PlayerSwitchFlashlight", "FB_BlockFlashlightWhenDepletedOrCooling", function(ply, enabled)
        if not IsValid(ply) then return end
        local battery = ply:GetNWFloat(NW_BATTERY, 100)
        local cooling = ply:GetNWBool(NW_COOLDOWN, false)

        -- Only block when trying to turn ON
        if enabled then
            if cooling or battery <= 0 then
                return false -- block enabling flashlight
            end
        end

        -- return nil to defer to default behavior
    end)

    -- Main tick: handle draining, cooldown, and recharge
    local TICK_NAME = "FB_Tick"
    local TICK_INTERVAL = 0.5 -- seconds; ties to default recharge interval for simplicity

    timer.Create(TICK_NAME, TICK_INTERVAL, 0, function()
        local drainTime = math.max(cv_drain_time:GetFloat(), 0.1)
        local rechargeStep = cv_recharge_step:GetFloat()
        local rechargeInterval = math.max(cv_recharge_interval:GetFloat(), 0.05)
        local cooldownDur = math.max(cv_cooldown:GetFloat(), 0)

        -- Compute drain per TICK_INTERVAL in percentage
        local drainPerTick = (TICK_INTERVAL / drainTime) * 100.0

        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                -- Ensure NWVars exist
                if ply:GetNWFloat(NW_BATTERY, -1) < 0 then
                    FB_InitPlayer(ply)
                end

                local battery = ply:GetNWFloat(NW_BATTERY, 100)
                local cooling = ply:GetNWBool(NW_COOLDOWN, false)
                local cooldownEnd = ply:GetNWFloat(NW_COOLDOWN_END, 0)
                local now = CurTime()

                -- Cooling expiration
                if cooling and now >= cooldownEnd then
                    ply:SetNWBool(NW_COOLDOWN, false)
                    cooling = false
                end

                if ply:FlashlightIsOn() then
                    -- Drain while ON
                    if battery > 0 then
                        battery = math.max(0, battery - drainPerTick)
                        ply:SetNWFloat(NW_BATTERY, battery)
                    end

                    -- If reached 0, force OFF and start cooldown (but don't reset if already cooling)
                    if battery <= 0 then
                        if ply:FlashlightIsOn() then
                            ply:Flashlight(false)
                        end
                        if cooldownDur > 0 and not cooling then
                            ply:SetNWBool(NW_COOLDOWN, true)
                            ply:SetNWFloat(NW_COOLDOWN_END, now + cooldownDur)
                        end
                    end
                else
                    -- Flashlight OFF: recharge if not cooling
                    if not cooling and battery < 100 then
                        -- Apply recharge every rechargeInterval: since our tick is fixed at 0.5s, scale step if different
                        local ticksPerRecharge = math.max(1, math.floor(rechargeInterval / TICK_INTERVAL + 0.5))
                        -- Store a per-player accumulator to handle arbitrary recharge intervals
                        ply.__fb_tick_acc = (ply.__fb_tick_acc or 0) + 1
                        if ply.__fb_tick_acc >= ticksPerRecharge then
                            ply.__fb_tick_acc = 0
                            battery = math.min(100, battery + rechargeStep)
                            ply:SetNWFloat(NW_BATTERY, battery)
                        end
                    else
                        -- Reset accumulator while cooling
                        ply.__fb_tick_acc = 0
                    end
                end
            end
        end
    end)
end
