local BETTER_FLASHLIGHT_CONVAR = "sv_betterflashlight_override_default"
local BETTER_FLASHLIGHT_STATE = "FlashlightIsOn"
local DYNAMIC_FLASHLIGHT_CONVAR = "df_flashlight"
local DYNAMIC_FLASHLIGHT_STATE = "DynamicFlashlight"
local THIRD_PERSON_FLASHLIGHT_CONVAR = "tpf_enabled"
local THIRD_PERSON_FLASHLIGHT_STATE = "TPF_FlashlightOn"
local IFL_FLASHLIGHT_STATE = "ifl_state"
local SHAKY_FLASHLIGHT_CLASS = "shaky_flashlight"

local function IsConVarEnabled(name)
    local convar = GetConVar(name)
    return convar and convar:GetBool()
end

local function IsNWFlashlightOn(ply, convarName, stateName)
    return IsConVarEnabled(convarName) and ply:GetNWBool(stateName, false)
end

local function GetShakyFlashlight(ply)
    local weapon = ply:GetActiveWeapon()
    if not IsValid(weapon) or weapon:GetClass() ~= SHAKY_FLASHLIGHT_CLASS then return nil end

    return weapon
end

local function IsShakyFlashlightOn(ply)
    local weapon = GetShakyFlashlight(ply)
    return IsValid(weapon) and weapon.GetFlashlightOn and weapon:GetFlashlightOn()
end

local function GetClientFlashlightSource(ply)
    if not ply.__fb_client_flashlight_states then return nil end

    for source, active in pairs(ply.__fb_client_flashlight_states) do
        if active then return source end
    end

    return nil
end

local function IsLocalClientFlashlightOn(ply)
    return CLIENT and ply == LocalPlayer() and _G.WBK_FlashlightIsActive == true
end

function FlashlightBattery.IsFlashlightOn(ply)
    if not IsValid(ply) then return false end
    if ply.FlashlightIsOn and ply:FlashlightIsOn() then return true end
    if IsNWFlashlightOn(ply, BETTER_FLASHLIGHT_CONVAR, BETTER_FLASHLIGHT_STATE) then return true end
    if IsNWFlashlightOn(ply, DYNAMIC_FLASHLIGHT_CONVAR, DYNAMIC_FLASHLIGHT_STATE) then return true end
    if IsNWFlashlightOn(ply, THIRD_PERSON_FLASHLIGHT_CONVAR, THIRD_PERSON_FLASHLIGHT_STATE) then return true end
    if ply:GetNWBool(IFL_FLASHLIGHT_STATE, false) then return true end
    if IsShakyFlashlightOn(ply) then return true end
    if GetClientFlashlightSource(ply) then return true end
    if IsLocalClientFlashlightOn(ply) then return true end

    return false
end

if SERVER then
    local function SetNWFlashlightOff(ply, stateName)
        if not ply:GetNWBool(stateName, false) then return false end

        ply:SetNWBool(stateName, false)
        return true
    end

    local function ForceShakyFlashlightOff(ply)
        local weapon = GetShakyFlashlight(ply)
        if not IsValid(weapon) or not weapon.GetFlashlightOn or not weapon:GetFlashlightOn() then return false end

        if weapon.SetLight then
            weapon:SetLight(false)
        elseif weapon.SetFlashlightOn then
            weapon:SetFlashlightOn(false)
        end

        return true
    end

    function FlashlightBattery.ForceFlashlightOff(ply)
        if not IsValid(ply) then return end

        local turnedOff = false
        local shouldEmitSound = ply:GetNWBool(BETTER_FLASHLIGHT_STATE, false)
            or ply:GetNWBool(DYNAMIC_FLASHLIGHT_STATE, false)
            or ply:GetNWBool(THIRD_PERSON_FLASHLIGHT_STATE, false)
            or IsShakyFlashlightOn(ply)
            or GetClientFlashlightSource(ply) ~= nil

        if ply.FlashlightIsOn and ply:FlashlightIsOn() then
            ply:Flashlight(false)
            turnedOff = true
        end

        turnedOff = SetNWFlashlightOff(ply, BETTER_FLASHLIGHT_STATE) or turnedOff
        turnedOff = SetNWFlashlightOff(ply, DYNAMIC_FLASHLIGHT_STATE) or turnedOff
        turnedOff = SetNWFlashlightOff(ply, THIRD_PERSON_FLASHLIGHT_STATE) or turnedOff
        turnedOff = ForceShakyFlashlightOff(ply) or turnedOff

        local clientSource = GetClientFlashlightSource(ply)
        if clientSource and FlashlightBattery.ForceClientFlashlightOff then
            FlashlightBattery.ForceClientFlashlightOff(ply, clientSource)
            turnedOff = true
        end

        if turnedOff and shouldEmitSound then
            ply:EmitSound("HL2Player.FlashLightOff")
        end
    end
end
