FlashlightBattery = FlashlightBattery or {}

local sharedFiles = {
    "flashlight_battery/sh_config.lua",
    "flashlight_battery/sh_flashlight_state.lua"
}

local clientFiles = {
    "flashlight_battery/cl_convars.lua",
    "flashlight_battery/cl_compat.lua",
    "flashlight_battery/cl_hud.lua",
    "flashlight_battery/cl_menu.lua"
}

local serverFiles = {
    "flashlight_battery/sv_convars.lua",
    "flashlight_battery/sv_network.lua",
    "flashlight_battery/sv_compat.lua",
    "flashlight_battery/sv_battery.lua",
    "flashlight_battery/sv_pickups.lua"
}

if SERVER then
    AddCSLuaFile()

    for _, path in ipairs(sharedFiles) do
        AddCSLuaFile(path)
    end

    for _, path in ipairs(clientFiles) do
        AddCSLuaFile(path)
    end
end

for _, path in ipairs(sharedFiles) do
    include(path)
end

if SERVER then
    for _, path in ipairs(serverFiles) do
        include(path)
    end
else
    for _, path in ipairs(clientFiles) do
        include(path)
    end
end
