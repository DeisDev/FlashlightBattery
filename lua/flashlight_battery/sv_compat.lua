util.AddNetworkString(FlashlightBattery.NetClientFlashlightState)
util.AddNetworkString(FlashlightBattery.NetForceClientFlashlightOff)

local allowedClientSources = {
    wbk_vmanip = true
}

local function SetClientFlashlightState(ply, source, active)
    ply.__fb_client_flashlight_states = ply.__fb_client_flashlight_states or {}
    ply.__fb_client_flashlight_states[source] = active or nil
end

function FlashlightBattery.ForceClientFlashlightOff(ply, source)
    if not IsValid(ply) then return end
    if not allowedClientSources[source] then return end

    SetClientFlashlightState(ply, source, false)

    net.Start(FlashlightBattery.NetForceClientFlashlightOff)
    net.WriteString(source)
    net.Send(ply)
end

net.Receive(FlashlightBattery.NetClientFlashlightState, function(_, ply)
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local source = net.ReadString()
    local active = net.ReadBool()
    if not allowedClientSources[source] then return end

    SetClientFlashlightState(ply, source, active)
end)

hook.Add("PlayerSpawn", "FB_ClearClientFlashlightStateOnSpawn", function(ply)
    if not IsValid(ply) then return end

    ply.__fb_client_flashlight_states = nil
end)

hook.Add("PlayerDisconnected", "FB_ClearClientFlashlightStateOnDisconnect", function(ply)
    if not IsValid(ply) then return end

    ply.__fb_client_flashlight_states = nil
end)
