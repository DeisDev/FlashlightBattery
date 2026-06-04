if CLIENT then
    include("flashlight_battery/sh_config.lua")

    local NW_BATTERY = "FB_Battery"
    local NW_COOLDOWN = "FB_Cooldown"
    local NW_COOLDOWN_END = "FB_CooldownEnd"

    local margin = 16
    local barWidth = 220
    local barHeight = 14
    local bgColor = Color(12, 14, 18, 190)
    local borderColor = Color(255, 255, 255, 45)
    local lowColor = Color(220, 50, 47)
    local midColor = Color(203, 75, 22)
    local highColor = Color(133, 153, 0)
    local labelColor = Color(245, 245, 245)
    local shadowColor = Color(0, 0, 0, 180)
    local pendingSettings = {}
    local clientConvars = {}
    local lowBatteryColorThreshold = 20

    for _, setting in ipairs(FlashlightBattery.ClientSettings) do
        clientConvars[setting.name] = CreateClientConVar(setting.name, tostring(setting.default), true, false, setting.description)
    end

    local function FB_CanConfigure()
        local ply = LocalPlayer()
        return game.SinglePlayer() or (IsValid(ply) and (ply:IsAdmin() or (ply.IsListenServerHost and ply:IsListenServerHost())))
    end

    local function FB_SendSetting(name, value)
        net.Start(FlashlightBattery.NetSetConVar)
            net.WriteString(name)
            net.WriteFloat(value)
        net.SendToServer()
    end

    local function FB_GetSettingValue(name, default)
        local convar = GetConVar(name)
        if not convar then return default end

        return convar:GetFloat()
    end

    local function FB_GetBatteryColor(battery)
        if battery <= lowBatteryColorThreshold then
            return lowColor
        end

        if battery <= 50 then
            return midColor
        end

        return highColor
    end

    local function FB_GetHudVisibility()
        local visibility = clientConvars.fb_hud_visibility:GetString()
        if FlashlightBattery.HudVisibilityModes[visibility] then return visibility end

        return "auto"
    end

    local function FB_ShouldDrawHUD(ply, battery, cooling)
        local enabled = GetConVar("fb_enabled")
        if enabled and not enabled:GetBool() then return false end

        local visibility = FB_GetHudVisibility()
        if visibility == "hidden" then return false end
        if visibility == "always" then return true end
        if visibility == "active" then
            return ply.FlashlightIsOn and ply:FlashlightIsOn()
        end

        if cooling then return true end
        if battery < FlashlightBattery.HudVisibleBatteryThreshold then return true end
        return ply.FlashlightIsOn and ply:FlashlightIsOn()
    end

    local function FB_GetHudAnchor()
        local anchor = clientConvars.fb_hud_anchor:GetString()
        if FlashlightBattery.HudAnchors[anchor] then return anchor end

        return "bottom_right"
    end

    local function FB_GetHudLayout(sw, sh)
        local anchor = FB_GetHudAnchor()
        local isLeft = anchor == "top_left" or anchor == "bottom_left"
        local isTop = anchor == "top_left" or anchor == "top_right"
        local scale = math.Clamp(clientConvars.fb_hud_scale:GetFloat() / 100, 0.75, 1.5)
        local width = math.floor(barWidth * scale)
        local height = math.floor(barHeight * scale)
        local x = isLeft and margin or (sw - margin - width)
        local y = isTop and margin or (sh - margin - height)
        local textX = isLeft and x or (x + width)
        local textY = isTop and (y + height + 4) or (y - 4)
        local textXAlign = isLeft and TEXT_ALIGN_LEFT or TEXT_ALIGN_RIGHT
        local textYAlign = isTop and TEXT_ALIGN_TOP or TEXT_ALIGN_BOTTOM

        return x, y, textX, textY, textXAlign, textYAlign, width, height
    end

    local function FB_DrawBatteryBar(x, y, width, height, battery, color, alphaScale)
        local fillWidth = math.floor((width - 4) * (battery / 100))

        surface.SetDrawColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a * alphaScale)
        surface.DrawRect(x, y, width, height)
        surface.SetDrawColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a * alphaScale)
        surface.DrawOutlinedRect(x, y, width, height)

        if fillWidth <= 0 then return end

        surface.SetDrawColor(color.r, color.g, color.b, 235 * alphaScale)
        surface.DrawRect(x + 2, y + 2, fillWidth, height - 4)
    end

    hook.Add("HUDPaint", "FB_DrawBatteryHUD", function()
        local ply = LocalPlayer()
        if not IsValid(ply) then return end

        local battery = math.Clamp(math.floor(ply:GetNWFloat(NW_BATTERY, 100) + 0.5), 0, 100)
        local cooling = ply:GetNWBool(NW_COOLDOWN, false)
        local cooldownEnd = ply:GetNWFloat(NW_COOLDOWN_END, 0)
        local now = CurTime()
        local cooldownLeft = math.max(0, cooldownEnd - now)
        if not FB_ShouldDrawHUD(ply, battery, cooling) then return end

        local sw, sh = ScrW(), ScrH()
        local x, y, textX, textY, textXAlign, textYAlign, width, height = FB_GetHudLayout(sw, sh)
        local color = FB_GetBatteryColor(battery)
        local alphaScale = math.Clamp(clientConvars.fb_hud_opacity:GetFloat() / 100, 0.2, 1)

        local label
        if cooling then
            label = string.format("Flashlight %d%%  Cooldown %.1fs", battery, cooldownLeft)
        else
            label = string.format("Flashlight %d%%", battery)
        end

        draw.SimpleText(label, "DermaDefaultBold", textX + 1, textY + 1, shadowColor, textXAlign, textYAlign)
        labelColor.a = 255 * alphaScale
        draw.SimpleText(label, "DermaDefaultBold", textX, textY, labelColor, textXAlign, textYAlign)
        labelColor.a = 255
        FB_DrawBatteryBar(x, y, width, height, battery, color, alphaScale)
    end)

    hook.Add("AddToolMenuTabs", "FB_AddSettingsTab", function()
        spawnmenu.AddToolTab("Options", "Options", "icon16/wrench.png")
    end)

    hook.Add("AddToolMenuCategories", "FB_AddSettingsCategories", function()
        spawnmenu.AddToolCategory("Options", "FlashlightBattery", "Flashlight Battery")
    end)

    local function FB_PopulateClientSettings(cpanel)
        cpanel:ClearControls()

        for _, setting in ipairs(FlashlightBattery.ClientSettings) do
            if setting.type == "choice" then
                local combo = vgui.Create("DComboBox", cpanel)
                local convar = clientConvars[setting.name]
                local current = convar:GetString()
                local currentChoice = setting.choices[current] or setting.choices[setting.default]

                cpanel:Help(setting.label)
                combo:Dock(TOP)
                combo:DockMargin(0, 2, 0, 6)
                combo:SetValue(currentChoice.label)

                for _, choiceName in ipairs(setting.order) do
                    local choice = setting.choices[choiceName]
                    combo:AddChoice(choice.label, choiceName, choiceName == current)
                end

                combo.OnSelect = function(_, _, _, data)
                    if not setting.choices[data] then return end

                    RunConsoleCommand(setting.name, data)
                end

                cpanel:AddItem(combo)
            elseif setting.type == "number" then
                local slider = vgui.Create("DNumSlider", cpanel)
                slider:Dock(TOP)
                slider:DockMargin(0, 2, 0, 6)
                slider:SetText(string.format("%s (%s)", setting.label, setting.suffix))
                slider:SetMinMax(setting.min, setting.max)
                slider:SetDecimals(setting.decimals)
                slider:SetValue(clientConvars[setting.name]:GetFloat())
                slider.__fb_ready = true
                slider.OnValueChanged = function(_, value)
                    if not slider.__fb_ready then return end

                    RunConsoleCommand(setting.name, tostring(value))
                end

                cpanel:AddItem(slider)
            end

            cpanel:ControlHelp(setting.description)
        end

        local resetClient = cpanel:Button("Reset Client Defaults")
        resetClient.DoClick = function()
            for _, setting in ipairs(FlashlightBattery.ClientSettings) do
                RunConsoleCommand(setting.name, tostring(setting.default))
            end

            timer.Simple(0, function()
                if IsValid(cpanel) then
                    FB_PopulateClientSettings(cpanel)
                end
            end)
        end
    end

    local function FB_PopulateAdminSettings(cpanel)
        cpanel:ClearControls()
        local canConfigure = FB_CanConfigure()

        if not canConfigure then
            cpanel:ControlHelp("Only server admins can change these settings. Current replicated server values are shown where available.")
        end

        for _, setting in ipairs(FlashlightBattery.ServerSettings) do
            if setting.type == "bool" then
                local checkbox = vgui.Create("DCheckBoxLabel", cpanel)
                checkbox:Dock(TOP)
                checkbox:DockMargin(0, 2, 0, 6)
                checkbox:SetText(setting.label)
                checkbox:SetEnabled(canConfigure)
                checkbox:SetChecked(FB_GetSettingValue(setting.name, setting.default) >= 0.5)
                checkbox:SizeToContents()
                checkbox.OnChange = function(_, checked)
                    if not FB_CanConfigure() then return end

                    FB_SendSetting(setting.name, checked and 1 or 0)
                end

                cpanel:AddItem(checkbox)
            else
                local slider = vgui.Create("DNumSlider", cpanel)
                slider:Dock(TOP)
                slider:DockMargin(0, 2, 0, 6)
                slider:SetText(string.format("%s (%s)", setting.label, setting.suffix))
                slider:SetMinMax(setting.min, setting.max)
                slider:SetDecimals(setting.decimals)
                slider:SetEnabled(canConfigure)
                slider:SetValue(FB_GetSettingValue(setting.name, setting.default))
                slider.__fb_ready = true
                slider.OnValueChanged = function(_, value)
                    if not slider.__fb_ready or not FB_CanConfigure() then return end

                    pendingSettings[setting.name] = value
                    local timerName = "FB_SendSetting_" .. setting.name
                    timer.Remove(timerName)
                    timer.Create(timerName, 0.15, 1, function()
                        FB_SendSetting(setting.name, pendingSettings[setting.name])
                    end)
                end

                cpanel:AddItem(slider)
            end

            cpanel:ControlHelp(setting.description)
        end

        cpanel:Help("")
        local btn = cpanel:Button("Reset Server Defaults")
        btn:SetEnabled(canConfigure)
        btn.DoClick = function()
            if not FB_CanConfigure() then return end

            for _, setting in ipairs(FlashlightBattery.ServerSettings) do
                timer.Remove("FB_SendSetting_" .. setting.name)
                pendingSettings[setting.name] = nil
                FB_SendSetting(setting.name, setting.default)
            end

            timer.Simple(0.3, function()
                if IsValid(cpanel) then
                    FB_PopulateAdminSettings(cpanel)
                end
            end)
        end
    end

    hook.Add("PopulateToolMenu", "FB_PopulateSettings", function()
        spawnmenu.AddToolMenuOption(
            "Options",
            "FlashlightBattery",
            "FB_ClientSettingsPanel",
            "Client Settings",
            "",
            "",
            FB_PopulateClientSettings
        )

        spawnmenu.AddToolMenuOption(
            "Options",
            "FlashlightBattery",
            "FB_AdminSettingsPanel",
            "Admin Settings",
            "",
            "",
            FB_PopulateAdminSettings
        )
    end)
end
