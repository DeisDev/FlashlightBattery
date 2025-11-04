-- Flashlight Battery - Client HUD

if CLIENT then
    local NW_BATTERY = "FB_Battery"
    local NW_COOLDOWN = "FB_Cooldown"
    local NW_COOLDOWN_END = "FB_CooldownEnd"

    local margin = 16
    local lowColor = Color(220, 50, 47)
    local midColor = Color(203, 75, 22)
    local highColor = Color(133, 153, 0)
    local textColor = Color(255, 255, 255)
    local shadowColor = Color(0, 0, 0, 180)

    hook.Add("HUDPaint", "FB_DrawBatteryHUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local battery = math.floor(ply:GetNWFloat(NW_BATTERY, 100) + 0.5)
        local cooling = ply:GetNWBool(NW_COOLDOWN, false)
        local cooldownEnd = ply:GetNWFloat(NW_COOLDOWN_END, 0)
        local now = CurTime()
        local cooldownLeft = math.max(0, cooldownEnd - now)

        local sw, sh = ScrW(), ScrH()
        local x = sw - margin
        local y = sh - margin

        local color = highColor
        if battery <= 20 then
            color = lowColor
        elseif battery <= 50 then
            color = midColor
        end

        local label
        if cooling then
            label = string.format("Flashlight: %d%% (cooldown %.1fs)", battery, cooldownLeft)
        else
            label = string.format("Flashlight: %d%%", battery)
        end

        -- Drop shadow
        draw.SimpleText(label, "DermaDefaultBold", x + 1, y + 1, shadowColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(label, "DermaDefaultBold", x, y, color, TEXT_ALIGN_RIGHT, TEXT_ALIGN_BOTTOM)
    end)

    -- Spawnmenu: Settings tab and config panel
    -- Add a top-level tab called "settings" (if it already exists, this is harmless)
    hook.Add("AddToolMenuTabs", "FB_AddSettingsTab", function()
        spawnmenu.AddToolTab("settings", "Settings", "icon16/wrench.png")
    end)

    -- Add category inside the "settings" tab
    hook.Add("AddToolMenuCategories", "FB_AddSettingsCategories", function()
        spawnmenu.AddToolCategory("settings", "FlashlightBattery", "Flashlight Battery")
    end)

    -- Populate the settings category with our control panel
    hook.Add("PopulateToolMenu", "FB_PopulateSettings", function()
        spawnmenu.AddToolMenuOption(
            "settings",                -- tab
            "FlashlightBattery",       -- category
            "FB_SettingsPanel",        -- internal name
            "settings",                -- displayed name in category
            "",                        -- command
            "",                        -- config file
            function(cpanel)
                cpanel:ClearControls()
                cpanel:Help("Configure Flashlight Battery. On dedicated servers, changes may require admin permissions.")

                -- Sliders bound to server convars
                cpanel:NumSlider("Drain time (seconds)", "fb_drain_time", 10, 600, 0)
                cpanel:NumSlider("Recharge step (% per tick)", "fb_recharge_step", 0, 10, 1)
                cpanel:NumSlider("Recharge interval (seconds)", "fb_recharge_interval", 0.05, 5, 2)
                cpanel:NumSlider("Cooldown after full drain (seconds)", "fb_cooldown", 0, 60, 0)

                cpanel:Help("")
                local btn = cpanel:Button("Reset to defaults")
                btn.DoClick = function()
                    -- Canonical defaults for this addon
                    RunConsoleCommand("fb_drain_time", "60")
                    RunConsoleCommand("fb_recharge_step", "1")
                    RunConsoleCommand("fb_recharge_interval", "0.5")
                    RunConsoleCommand("fb_cooldown", "5")
                end
            end
        )
    end)
end
