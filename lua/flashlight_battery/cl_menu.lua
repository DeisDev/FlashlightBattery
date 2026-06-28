local clientConvars = FlashlightBattery.ClientConVars
local pendingSettings = {}

local links = {
    repository = "https://github.com/DeisDev/FlashlightBattery",
    issue = "https://github.com/DeisDev/FlashlightBattery/issues/new?template=flashlight_compatibility.yml",
    workshop = "https://steamcommunity.com/sharedfiles/filedetails/comments/3599388816",
    moreAddons = "https://steamcommunity.com/workshop/filedetails/?id=3551812511",
    author = "https://steamcommunity.com/profiles/76561199216202475"
}

local AUTHOR_STEAM_ID = "76561199216202475"

local function CanConfigure()
    local ply = LocalPlayer()
    return game.SinglePlayer() or (IsValid(ply) and (ply:IsAdmin() or (ply.IsListenServerHost and ply:IsListenServerHost())))
end

local function ServerForcesHud()
    local convar = GetConVar("fb_admin_hud_enabled")
    return convar and convar:GetBool()
end

local function SendSetting(name, value)
    net.Start(FlashlightBattery.NetSetConVar)
        net.WriteString(name)
        net.WriteString(tostring(value))
    net.SendToServer()
end

local function GetSettingValue(name, default, valueType)
    local convar = GetConVar(name)
    if not convar then return default end

    if valueType == "string" then
        return convar:GetString()
    end

    return convar:GetFloat()
end

local function FormatSliderLabel(setting)
    if setting.suffix then
        return string.format("%s (%s)", setting.label, setting.suffix)
    end

    return setting.label
end

local function AddForm(cpanel, title)
    local form = vgui.Create("DForm", cpanel)
    form:SetName(title)
    form:SetExpanded(true)
    cpanel:AddItem(form)

    return form
end

local function AddChoiceSetting(form, setting, current, enabled, onSelect)
    local label = vgui.Create("DLabel", form)
    label:SetText(setting.label)
    label:SizeToContents()
    form:AddItem(label)

    local combo = vgui.Create("DComboBox", form)
    local currentChoice = setting.choices[current] or setting.choices[setting.default]

    combo:SetEnabled(enabled)
    combo:SetValue(currentChoice.label)

    for _, choiceName in ipairs(setting.order) do
        local choice = setting.choices[choiceName]
        combo:AddChoice(choice.label, choiceName, choiceName == current)
    end

    combo.OnSelect = function(_, _, _, data)
        if not setting.choices[data] then return end

        onSelect(data)
    end

    form:AddItem(combo)
    form:Help(setting.description)
end

local function AddNumberSetting(form, setting, value, enabled, onChanged)
    local slider = vgui.Create("DNumSlider", form)
    slider:SetText(FormatSliderLabel(setting))
    slider:SetMinMax(setting.min, setting.max)
    slider:SetDecimals(setting.decimals)
    slider:SetEnabled(enabled)
    slider:SetValue(value)
    slider.__fb_ready = true
    slider.OnValueChanged = function(_, newValue)
        if not slider.__fb_ready then return end

        onChanged(newValue)
    end

    form:AddItem(slider)
    form:Help(setting.description)
end

local function AddBoolSetting(form, setting, checked, enabled, onChanged)
    local checkbox = vgui.Create("DCheckBoxLabel", form)
    checkbox:SetText(setting.label)
    checkbox:SetEnabled(enabled)
    checkbox:SetChecked(checked)
    checkbox:SizeToContents()
    checkbox.OnChange = function(_, newChecked)
        onChanged(newChecked)
    end

    form:AddItem(checkbox)
    form:Help(setting.description)
end

local function AddStringSetting(form, setting, value, enabled, onChanged)
    local entry = vgui.Create("DTextEntry", form)
    entry:SetEnabled(enabled)
    entry:SetText(value)
    entry:SetUpdateOnType(false)
    entry.OnEnter = function(panel)
        onChanged(panel:GetValue())
    end
    entry.OnLoseFocus = function(panel)
        onChanged(panel:GetValue())
    end

    form:AddItem(entry)
    form:Help(setting.description)
end

local function AddLinkButton(form, label, url)
    local button = vgui.Create("DButton", form)
    button:SetText(label)
    button.DoClick = function()
        gui.OpenURL(url)
    end

    form:AddItem(button)
end

local function AddCredits(form)
    local panel = vgui.Create("DPanel", form)
    panel:SetTall(72)
    panel.Paint = nil

    local avatar = vgui.Create("AvatarImage", panel)
    avatar:Dock(LEFT)
    avatar:SetWide(64)
    avatar:SetSteamID(AUTHOR_STEAM_ID, 64)

    local text = vgui.Create("DLabel", panel)
    text:Dock(FILL)
    text:DockMargin(8, 0, 0, 0)
    text:SetText("Author: cat sniffer")
    text:SizeToContents()

    form:AddItem(panel)
    AddLinkButton(form, "Steam Profile", links.author)
end

local function AddClientSetting(form, setting, enabled)
    if setting.type == "choice" then
        AddChoiceSetting(form, setting, clientConvars[setting.name]:GetString(), enabled, function(data)
            RunConsoleCommand(setting.name, data)
        end)
    elseif setting.type == "number" then
        AddNumberSetting(form, setting, clientConvars[setting.name]:GetFloat(), enabled, function(value)
            RunConsoleCommand(setting.name, tostring(value))
        end)
    end
end

local function AddServerSetting(form, setting, canConfigure)
    if setting.type == "bool" then
        AddBoolSetting(
            form,
            setting,
            GetSettingValue(setting.name, setting.default, "number") >= 0.5,
            canConfigure,
            function(checked)
                if not CanConfigure() then return end

                SendSetting(setting.name, checked and 1 or 0)
            end
        )
    elseif setting.type == "choice" then
        AddChoiceSetting(
            form,
            setting,
            GetSettingValue(setting.name, setting.default, "string"),
            canConfigure,
            function(data)
                if not CanConfigure() then return end

                SendSetting(setting.name, data)
            end
        )
    elseif setting.type == "string" then
        AddStringSetting(
            form,
            setting,
            GetSettingValue(setting.name, setting.default, "string"),
            canConfigure,
            function(value)
                if not CanConfigure() then return end

                SendSetting(setting.name, value)
            end
        )
    else
        AddNumberSetting(
            form,
            setting,
            GetSettingValue(setting.name, setting.default, "number"),
            canConfigure,
            function(value)
                if not CanConfigure() then return end

                pendingSettings[setting.name] = value
                local timerName = "FB_SendSetting_" .. setting.name
                timer.Remove(timerName)
                timer.Create(timerName, 0.15, 1, function()
                    SendSetting(setting.name, pendingSettings[setting.name])
                end)
            end
        )
    end
end

local function PopulateClientSettings(cpanel)
    cpanel:ClearControls()

    local hudForced = ServerForcesHud()
    if hudForced then
        cpanel:Help("Server HUD settings are active. Local preferences are visible here but cannot be changed.")
    else
        cpanel:Help("Tune how the flashlight battery HUD appears for you on servers that allow local HUD preferences.")
    end

    local form = AddForm(cpanel, "Local Preferences")

    for _, setting in ipairs(FlashlightBattery.ClientSettings) do
        AddClientSetting(form, setting, not hudForced)
    end

    local resetClient = cpanel:Button("Reset Client Defaults")
    resetClient:SetEnabled(not hudForced)
    resetClient.DoClick = function()
        if ServerForcesHud() then return end

        for _, setting in ipairs(FlashlightBattery.ClientSettings) do
            RunConsoleCommand(setting.name, tostring(setting.default))
        end

        timer.Simple(0, function()
            if IsValid(cpanel) then
                PopulateClientSettings(cpanel)
            end
        end)
    end
end

local function PopulateAdminSettings(cpanel)
    cpanel:ClearControls()

    local canConfigure = CanConfigure()
    local forms = {}

    if canConfigure then
        cpanel:Help("Server settings apply to all players. HUD settings only override clients when Force HUD settings is enabled.")
    else
        cpanel:Help("Only server admins can change these settings. Replicated values are shown read-only.")
    end

    for _, setting in ipairs(FlashlightBattery.ServerSettings) do
        local section = setting.section or "Settings"
        forms[section] = forms[section] or AddForm(cpanel, section)
        AddServerSetting(forms[section], setting, canConfigure)
    end

    local resetServer = cpanel:Button("Reset Server Defaults")
    resetServer:SetEnabled(canConfigure)
    resetServer.DoClick = function()
        if not CanConfigure() then return end

        for _, setting in ipairs(FlashlightBattery.ServerSettings) do
            timer.Remove("FB_SendSetting_" .. setting.name)
            pendingSettings[setting.name] = nil
            SendSetting(setting.name, setting.default)
        end

        timer.Simple(0.3, function()
            if IsValid(cpanel) then
                PopulateAdminSettings(cpanel)
            end
        end)
    end
end

local function PopulateAbout(cpanel)
    cpanel:ClearControls()

    local about = AddForm(cpanel, "About")
    about:Help("Flashlight Battery")
    about:Help("Version " .. FlashlightBattery.Version)
    about:Help("Adds battery drain, recharge, cooldown, pickups, and a simple HUD for flashlights.")
    AddLinkButton(about, "GitHub Repository", links.repository)

    local compatibility = AddForm(cpanel, "Compatibility")
    compatibility:Help("Works with the default flashlight and supports several popular flashlight addons.")
    compatibility:Help("Need another addon supported? Link it and say what is not working.")
    AddLinkButton(compatibility, "Request Compatibility", links.issue)

    local support = AddForm(cpanel, "Support")
    support:Help("For bugs, include your settings and what you expected to happen.")
    AddLinkButton(support, "Workshop Comments", links.workshop)
    AddLinkButton(support, "More Addons", links.moreAddons)

    local credits = AddForm(cpanel, "Credits")
    AddCredits(credits)
end

hook.Add("AddToolMenuTabs", "FB_AddSettingsTab", function()
    spawnmenu.AddToolTab("Options", "Options", "icon16/wrench.png")
end)

hook.Add("AddToolMenuCategories", "FB_AddSettingsCategories", function()
    spawnmenu.AddToolCategory("Options", "FlashlightBattery", "Flashlight Battery")
end)

hook.Add("PopulateToolMenu", "FB_PopulateSettings", function()
    spawnmenu.AddToolMenuOption(
        "Options",
        "FlashlightBattery",
        "FB_ClientSettingsPanel",
        "Client HUD",
        "",
        "",
        PopulateClientSettings
    )

    spawnmenu.AddToolMenuOption(
        "Options",
        "FlashlightBattery",
        "FB_AdminSettingsPanel",
        "Server Settings",
        "",
        "",
        PopulateAdminSettings
    )

    spawnmenu.AddToolMenuOption(
        "Options",
        "FlashlightBattery",
        "FB_AboutPanel",
        "About",
        "",
        "",
        PopulateAbout
    )
end)
