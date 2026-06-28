local clientConvars = FlashlightBattery.ClientConVars
local nw = FlashlightBattery.NW

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
local lowBatteryColorThreshold = 20

local function GetReplicatedConVarValue(name, default, valueType)
    local convar = GetConVar(name)
    if not convar then return default end

    if valueType == "string" then
        return convar:GetString()
    end

    return convar:GetFloat()
end

local function ServerForcesHud()
    local convar = GetConVar("fb_admin_hud_enabled")
    return convar and convar:GetBool()
end

local function GetChoiceValue(localName, adminName, default, choices)
    local value

    if ServerForcesHud() then
        value = GetReplicatedConVarValue(adminName, default, "string")
    else
        value = clientConvars[localName]:GetString()
    end

    if choices[value] then return value end
    return default
end

local function GetNumberValue(localName, adminName, default, minValue, maxValue)
    local value

    if ServerForcesHud() then
        value = GetReplicatedConVarValue(adminName, default, "number")
    else
        value = clientConvars[localName]:GetFloat()
    end

    return math.Clamp(value, minValue, maxValue)
end

local function GetBatteryColor(battery)
    if battery <= lowBatteryColorThreshold then
        return lowColor
    end

    if battery <= 50 then
        return midColor
    end

    return highColor
end

local function GetHudVisibility()
    return GetChoiceValue(
        "fb_hud_visibility",
        "fb_admin_hud_visibility",
        "auto",
        FlashlightBattery.HudVisibilityModes
    )
end

local function ShouldDrawHUD(ply, battery, cooling)
    local enabled = GetConVar("fb_enabled")
    if enabled and not enabled:GetBool() then return false end

    local visibility = GetHudVisibility()
    if visibility == "hidden" then return false end
    if visibility == "always" then return true end
    if visibility == "active" then
        return FlashlightBattery.IsFlashlightOn(ply)
    end

    if cooling then return true end
    if battery < FlashlightBattery.HudVisibleBatteryThreshold then return true end
    return FlashlightBattery.IsFlashlightOn(ply)
end

local function GetHudAnchor()
    return GetChoiceValue(
        "fb_hud_anchor",
        "fb_admin_hud_anchor",
        "bottom_right",
        FlashlightBattery.HudAnchors
    )
end

local function GetHudScale()
    return GetNumberValue("fb_hud_scale", "fb_admin_hud_scale", 100, 75, 150)
end

local function GetHudOpacity()
    return GetNumberValue("fb_hud_opacity", "fb_admin_hud_opacity", 100, 20, 100)
end

local function GetHudLayout(sw, sh)
    local anchor = GetHudAnchor()
    local isLeft = anchor == "top_left" or anchor == "bottom_left"
    local isTop = anchor == "top_left" or anchor == "top_right"
    local scale = GetHudScale() / 100
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

local function DrawBatteryBar(x, y, width, height, battery, color, alphaScale)
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

    local battery = math.Clamp(math.floor(ply:GetNW2Float(nw.Battery, 100) + 0.5), 0, 100)
    local cooling = ply:GetNW2Bool(nw.Cooldown, false)
    local cooldownEnd = ply:GetNW2Float(nw.CooldownEnd, 0)
    local cooldownLeft = math.max(0, cooldownEnd - CurTime())
    if not ShouldDrawHUD(ply, battery, cooling) then return end

    local x, y, textX, textY, textXAlign, textYAlign, width, height = GetHudLayout(ScrW(), ScrH())
    local color = GetBatteryColor(battery)
    local alphaScale = GetHudOpacity() / 100
    local label = string.format("Flashlight %d%%", battery)

    if cooling then
        label = string.format("%s  Cooldown %.1fs", label, cooldownLeft)
    end

    draw.SimpleText(label, "DermaDefaultBold", textX + 1, textY + 1, shadowColor, textXAlign, textYAlign)
    labelColor.a = 255 * alphaScale
    draw.SimpleText(label, "DermaDefaultBold", textX, textY, labelColor, textXAlign, textYAlign)
    labelColor.a = 255

    DrawBatteryBar(x, y, width, height, battery, color, alphaScale)
end)
