local CVAR_FLAGS = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)

FlashlightBattery.ConVars = FlashlightBattery.ConVars or {}

local function CreateSettingConVar(setting)
    if setting.type == "choice" or setting.type == "string" then
        return CreateConVar(setting.name, tostring(setting.default), CVAR_FLAGS, setting.description)
    end

    return CreateConVar(
        setting.name,
        tostring(setting.default),
        CVAR_FLAGS,
        setting.description,
        setting.min,
        setting.max
    )
end

for _, setting in ipairs(FlashlightBattery.ServerSettings) do
    FlashlightBattery.ConVars[setting.name] = CreateSettingConVar(setting)
end
