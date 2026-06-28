include("shared.lua")

local labelColor = Color(245, 245, 245)
local shadowColor = Color(0, 0, 0, 220)
local backgroundColor = Color(0, 0, 0, 120)

local function GetSettingBool(name, default)
    local convar = GetConVar(name)
    if not convar then return default end

    return convar:GetBool()
end

local function GetSettingFloat(name, default)
    local convar = GetConVar(name)
    if not convar then return default end

    return convar:GetFloat()
end

local function GetSettingString(name, default)
    local convar = GetConVar(name)
    if not convar then return default end

    return convar:GetString()
end

local function ShouldDrawLabel(entity)
    if not GetSettingBool("fb_pickup_label_enabled", true) then return false end

    local ply = LocalPlayer()
    if not IsValid(ply) then return false end

    local maxDistance = GetSettingFloat("fb_pickup_label_distance", 768)
    if maxDistance <= 0 then return true end

    return ply:GetPos():DistToSqr(entity:GetPos()) <= maxDistance * maxDistance
end

local function DrawFloatingLabel(entity)
    if not ShouldDrawLabel(entity) then return end

    local text = entity.FB_LabelText or GetSettingString("fb_pickup_label_text", "Flashlight Battery")
    if text == "" then return end

    local height = GetSettingFloat("fb_pickup_label_height", 36)
    local scale = GetSettingFloat("fb_pickup_label_scale", 0.1)
    local position = entity:GetPos() + Vector(0, 0, height)
    local angle = LocalPlayer():EyeAngles()

    angle:RotateAroundAxis(angle:Right(), 90)
    angle:RotateAroundAxis(angle:Up(), -90)

    cam.Start3D2D(position, angle, scale)
        surface.SetFont("DermaDefaultBold")
        local textWidth, textHeight = surface.GetTextSize(text)
        draw.RoundedBox(4, -textWidth * 0.5 - 8, -textHeight * 0.5 - 4, textWidth + 16, textHeight + 8, backgroundColor)
        draw.SimpleText(text, "DermaDefaultBold", 1, 1, shadowColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        draw.SimpleText(text, "DermaDefaultBold", 0, 0, labelColor, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    cam.End3D2D()
end

function ENT:DrawTranslucent()
    self:DrawModel()
    DrawFloatingLabel(self)
end
