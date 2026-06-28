local BETTER_FLASHLIGHT_CONVAR = "sv_betterflashlight_override_default"
local BETTER_FLASHLIGHT_STATE = "FlashlightIsOn"

local function IsBetterFlashlightEnabled()
    local betterFlashlight = GetConVar(BETTER_FLASHLIGHT_CONVAR)
    return betterFlashlight and betterFlashlight:GetBool()
end

function FlashlightBattery.IsFlashlightOn(ply)
    if not IsValid(ply) then return false end
    if ply.FlashlightIsOn and ply:FlashlightIsOn() then return true end
    if IsBetterFlashlightEnabled() and ply:GetNWBool(BETTER_FLASHLIGHT_STATE, false) then return true end

    return false
end

if SERVER then
    function FlashlightBattery.ForceFlashlightOff(ply)
        if not IsValid(ply) then return end

        local engineFlashlightOn = ply.FlashlightIsOn and ply:FlashlightIsOn()
        local betterFlashlightOn = IsBetterFlashlightEnabled() and ply:GetNWBool(BETTER_FLASHLIGHT_STATE, false)

        if engineFlashlightOn then
            ply:Flashlight(false)
        end

        if betterFlashlightOn then
            ply:SetNWBool(BETTER_FLASHLIGHT_STATE, false)
            ply:EmitSound("HL2Player.FlashLightOff")
        end
    end
end
