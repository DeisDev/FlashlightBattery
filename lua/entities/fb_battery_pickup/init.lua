AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local MODEL = "models/items/car_battery01.mdl"

local function GetSetting(name, default)
    local convar = GetConVar(name)
    if not convar then return default end

    return convar:GetFloat()
end

local function GetSettingString(name, default)
    local convar = GetConVar(name)
    if not convar then return default end

    return convar:GetString()
end

local function PlayPickupSound(position)
    if GetSetting("fb_pickup_sound_enabled", 1) < 0.5 then return end

    local soundPath = GetSettingString("fb_pickup_sound_path", "items/battery_pickup.wav")
    if soundPath == "" then return end

    sound.Play(
        soundPath,
        position,
        GetSetting("fb_pickup_sound_level", 70),
        GetSetting("fb_pickup_sound_pitch", 100),
        GetSetting("fb_pickup_sound_volume", 1)
    )
end

function ENT:ApplyPickupSettings()
    local radius = GetSetting("fb_pickup_trigger_radius", 24)
    local alpha = math.Clamp(GetSetting("fb_pickup_alpha", 180), 0, 255)
    local modelScale = GetSetting("fb_pickup_model_scale", 1)
    local tintColor = self.FB_TintColor or Color(255, 255, 255)

    self:SetModelScale(modelScale, 0)
    self:SetRenderMode(RENDERMODE_TRANSCOLOR)
    self:SetColor(Color(tintColor.r, tintColor.g, tintColor.b, alpha))
    self:SetCollisionBounds(Vector(-radius, -radius, -12), Vector(radius, radius, 36))
end

function ENT:Initialize()
    if not self.FB_AutoSpawned then
        self:SetPos(self:GetPos() + Vector(0, 0, GetSetting("fb_pickup_float_height", 18)))
    end

    self:SetModel(MODEL)
    self:SetMoveType(MOVETYPE_NONE)
    self:SetSolid(SOLID_BBOX)
    self:ApplyPickupSettings()
    self:SetCollisionGroup(COLLISION_GROUP_DEBRIS_TRIGGER)
    self:SetTrigger(true)
    self:SetUseType(SIMPLE_USE)
    self:DrawShadow(false)

    self.__fb_spin_offset = math.Rand(0, 360)
end

function ENT:Think()
    local spinSpeed = GetSetting("fb_pickup_spin_speed", 35)
    self:SetAngles(Angle(0, (self.__fb_spin_offset + CurTime() * spinSpeed) % 360, 0))
    self:NextThink(CurTime() + 0.05)

    return true
end

function ENT:TryPickup(ply)
    if self.__fb_picked_up then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end
    if not FlashlightBattery or not FlashlightBattery.RefillBatteryFromPickup then return end

    local restored = FlashlightBattery.RefillBatteryFromPickup(ply, self.FB_RefillMode)
    if restored <= 0 then return end

    self.__fb_picked_up = true
    PlayPickupSound(self:GetPos())
    FlashlightBattery.NotifyPickupRefill(ply, restored)

    if self.FB_AutoSpawned and FlashlightBattery.SchedulePickupRespawn then
        FlashlightBattery.SchedulePickupRespawn()
    end

    self:Remove()
end

function ENT:Touch(entity)
    self:TryPickup(entity)
end

function ENT:Use(activator)
    self:TryPickup(activator)
end
