local POLL_NAME = "FB_ClientFlashlightCompat"
local POLL_INTERVAL = 0.2
local WBK_SOURCE = "wbk_vmanip"
local nw = FlashlightBattery.NW

local lastStates = {}

local function SendClientState(source, active)
    if lastStates[source] == active then return end

    lastStates[source] = active

    net.Start(FlashlightBattery.NetClientFlashlightState)
    net.WriteString(source)
    net.WriteBool(active)
    net.SendToServer()
end

local function WBKFlashlightExists()
    return _G.WBK_FlashlightIsActive ~= nil or _G.WBK_FlashlightObject ~= nil
end

local function IsWBKFlashlightOn()
    return _G.WBK_FlashlightIsActive == true
end

local function ForceWBKFlashlightOff()
    local flashlightObject = _G.WBK_FlashlightObject

    if flashlightObject and flashlightObject.Remove then
        pcall(function()
            flashlightObject:Remove()
        end)
    end

    _G.WBK_FlashlightIsActive = false
    _G.WBK_FlashlightObject = nil

    SendClientState(WBK_SOURCE, false)
end

local function IsFlashlightBatteryEnabled()
    local convar = GetConVar("fb_enabled")
    return not convar or convar:GetBool()
end

local function CanUseFlashlightBattery()
    local ply = LocalPlayer()
    if not IsValid(ply) then return true end
    if not IsFlashlightBatteryEnabled() then return true end
    if ply:GetNW2Bool(nw.Cooldown, false) then return false end

    local battery = ply:GetNW2Float(nw.Battery, 100)
    local minimumConVar = GetConVar("fb_min_battery_to_turn_on")
    local minimumBattery = minimumConVar and minimumConVar:GetFloat() or 0

    return battery > 0 and battery >= minimumBattery
end

timer.Create(POLL_NAME, POLL_INTERVAL, 0, function()
    if WBKFlashlightExists() then
        SendClientState(WBK_SOURCE, IsWBKFlashlightOn())
    elseif lastStates[WBK_SOURCE] ~= nil then
        SendClientState(WBK_SOURCE, false)
    end
end)

net.Receive(FlashlightBattery.NetForceClientFlashlightOff, function()
    local source = net.ReadString()

    if source == WBK_SOURCE then
        ForceWBKFlashlightOff()
    end
end)

hook.Add("PlayerBindPress", "FB_BlockWBKFlashlightWhenEmpty", function(ply, bind, pressed)
    if ply ~= LocalPlayer() or not pressed then return nil end
    if bind ~= "impulse 100" and bind ~= "+reload" then return nil end
    if not WBKFlashlightExists() then return nil end
    if CanUseFlashlightBattery() then return nil end

    if IsWBKFlashlightOn() then
        ForceWBKFlashlightOff()
    end

    return true
end)
