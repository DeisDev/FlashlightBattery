util.AddNetworkString(FlashlightBattery.NetSetConVar)

local function CanConfigure(ply)
    return game.SinglePlayer() or (IsValid(ply) and (ply:IsAdmin() or (ply.IsListenServerHost and ply:IsListenServerHost())))
end

local function RoundValue(value, decimals)
    local multiplier = 10 ^ decimals
    return math.floor(value * multiplier + 0.5) / multiplier
end

local function ValidateSettingValue(setting, rawValue)
    if setting.type == "choice" then
        if not setting.choices[rawValue] then return nil end

        return rawValue
    end

    if setting.type == "string" then
        return string.Trim(string.sub(rawValue, 1, setting.maxLength or 128))
    end

    local value = tonumber(rawValue)
    if not value then return nil end

    value = math.Clamp(value, setting.min, setting.max)
    return RoundValue(value, setting.decimals)
end

net.Receive(FlashlightBattery.NetSetConVar, function(_, ply)
    if not CanConfigure(ply) then return end

    local name = net.ReadString()
    local rawValue = net.ReadString()
    local setting = FlashlightBattery.ServerSettingByName[name]
    if not setting then return end

    local value = ValidateSettingValue(setting, rawValue)
    if value == nil then return end

    RunConsoleCommand(name, tostring(value))
end)
