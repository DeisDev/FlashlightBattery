FlashlightBattery.ClientConVars = FlashlightBattery.ClientConVars or {}

for _, setting in ipairs(FlashlightBattery.ClientSettings) do
    FlashlightBattery.ClientConVars[setting.name] = CreateClientConVar(
        setting.name,
        tostring(setting.default),
        true,
        false,
        setting.description
    )
end
