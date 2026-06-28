local convars = FlashlightBattery.ConVars
local PICKUP_CLASS = "fb_battery_pickup"
local FULL_PICKUP_CLASS = "fb_battery_pickup_full"
local SUIT_BATTERY_CLASS = "item_battery"
local RESPAWN_TIMER = "FB_PickupRespawn"
local suitBatteryPickupCandidates = {}

local function CanConfigure(ply)
    return game.SinglePlayer() or (IsValid(ply) and (ply:IsAdmin() or (ply.IsListenServerHost and ply:IsListenServerHost())))
end

local function PickupsEnabled()
    return convars.fb_pickup_enabled:GetBool() and convars.fb_pickup_map_spawns_enabled:GetBool()
end

local function GetAutoPickups()
    local pickups = {}

    for _, entity in ipairs(ents.FindByClass(PICKUP_CLASS)) do
        if entity.FB_AutoSpawned then
            pickups[#pickups + 1] = entity
        end
    end

    return pickups
end

local function RemoveAutoPickups()
    for _, entity in ipairs(GetAutoPickups()) do
        if IsValid(entity) then
            entity:Remove()
        end
    end
end

local function RefillFromSuitBattery(ply)
    if not convars.fb_suit_battery_refill_enabled:GetBool() then return end
    if not IsValid(ply) or not ply:IsPlayer() then return end

    local restored = FlashlightBattery.RefillBatteryFromPickup(ply, nil, true)
    FlashlightBattery.NotifyPickupRefill(ply, restored)
end

local function IsFarEnoughFromPlayers(position)
    local minDistance = convars.fb_pickup_spawn_min_player_distance:GetFloat()
    if minDistance <= 0 then return true end

    local minDistanceSqr = minDistance * minDistance

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply:GetPos():DistToSqr(position) < minDistanceSqr then
            return false
        end
    end

    return true
end

local function HasPickupClearance(position)
    local radius = convars.fb_pickup_spawn_clearance_radius:GetFloat()
    local height = convars.fb_pickup_spawn_clearance_height:GetFloat()
    local mins = Vector(-radius, -radius, -height * 0.5)
    local maxs = Vector(radius, radius, height * 0.5)

    local trace = util.TraceHull({
        start = position,
        endpos = position,
        mins = mins,
        maxs = maxs,
        mask = MASK_SOLID
    })

    if trace.StartSolid or trace.Hit then return false end

    for _, entity in ipairs(ents.FindInBox(position + mins, position + maxs)) do
        if IsValid(entity) and entity:GetClass() == PICKUP_CLASS then
            return false
        end
    end

    return true
end

local function FindGroundPosition(position)
    local trace = util.TraceLine({
        start = position + Vector(0, 0, 96),
        endpos = position - Vector(0, 0, 256),
        mask = MASK_SOLID_BRUSHONLY
    })

    if trace.Hit then
        return trace.HitPos
    end

    return position
end

local function GetRandomNavPosition(areas)
    local area = areas[math.random(#areas)]
    local position = area:GetRandomPoint()
    local groundPosition = FindGroundPosition(position)

    return groundPosition + Vector(0, 0, convars.fb_pickup_float_height:GetFloat())
end

local function TrySpawnPickup(areas)
    local attempts = math.floor(convars.fb_pickup_spawn_attempts:GetFloat())

    for _ = 1, attempts do
        local position = GetRandomNavPosition(areas)

        if IsFarEnoughFromPlayers(position) and HasPickupClearance(position) then
            local pickup = ents.Create(PICKUP_CLASS)
            if not IsValid(pickup) then return false end

            pickup:SetPos(position)
            pickup.FB_AutoSpawned = true
            pickup:Spawn()
            pickup:Activate()

            return true
        end
    end

    return false
end

local function SpawnMissingPickups()
    timer.Remove(RESPAWN_TIMER)

    if not PickupsEnabled() then
        RemoveAutoPickups()
        return
    end

    if not navmesh.IsLoaded() then return end

    local targetCount = math.floor(convars.fb_pickup_map_spawn_count:GetFloat())
    if targetCount <= 0 then
        RemoveAutoPickups()
        return
    end

    local areas = navmesh.GetAllNavAreas()
    if #areas == 0 then return end

    local pickups = GetAutoPickups()

    for index = targetCount + 1, #pickups do
        if IsValid(pickups[index]) then
            pickups[index]:Remove()
        end
    end

    local missingCount = targetCount - math.min(#pickups, targetCount)
    for _ = 1, missingCount do
        TrySpawnPickup(areas)
    end
end

function FlashlightBattery.SchedulePickupRespawn(delay)
    if timer.Exists(RESPAWN_TIMER) then return end

    timer.Create(RESPAWN_TIMER, delay or convars.fb_pickup_respawn_time:GetFloat(), 1, SpawnMissingPickups)
end

hook.Add("InitPostEntity", "FB_SpawnBatteryPickups", function()
    FlashlightBattery.SchedulePickupRespawn(1)
end)

hook.Add("PostCleanupMap", "FB_RespawnBatteryPickupsAfterCleanup", function()
    FlashlightBattery.SchedulePickupRespawn(1)
end)

local function RefreshPickups()
    timer.Remove(RESPAWN_TIMER)
    FlashlightBattery.SchedulePickupRespawn(0)
end

local function RefreshPickupSettings()
    for _, className in ipairs({PICKUP_CLASS, FULL_PICKUP_CLASS}) do
        for _, entity in ipairs(ents.FindByClass(className)) do
            if IsValid(entity) and entity.ApplyPickupSettings then
                entity:ApplyPickupSettings()
            end
        end
    end
end

local function RespawnPickupsNow(ply)
    if IsValid(ply) and not CanConfigure(ply) then return end

    RemoveAutoPickups()
    timer.Remove(RESPAWN_TIMER)
    SpawnMissingPickups()

    if IsValid(ply) then
        ply:PrintMessage(HUD_PRINTTALK, "Flashlight Battery pickups respawned")
    end
end

concommand.Add("fb_respawn_pickups", RespawnPickupsNow)

cvars.AddChangeCallback("fb_pickup_enabled", RefreshPickups, "FB_RefreshPickupsEnabled")
cvars.AddChangeCallback("fb_pickup_map_spawns_enabled", RefreshPickups, "FB_RefreshPickupMapSpawns")
cvars.AddChangeCallback("fb_pickup_map_spawn_count", RefreshPickups, "FB_RefreshPickupMapSpawnCount")
cvars.AddChangeCallback("fb_pickup_alpha", RefreshPickupSettings, "FB_RefreshPickupAlpha")
cvars.AddChangeCallback("fb_pickup_model_scale", RefreshPickupSettings, "FB_RefreshPickupModelScale")
cvars.AddChangeCallback("fb_pickup_trigger_radius", RefreshPickupSettings, "FB_RefreshPickupTriggerRadius")

hook.Add("PlayerCanPickupItem", "FB_MarkSuitBatteryPickup", function(ply, item)
    if not convars.fb_suit_battery_refill_enabled:GetBool() then return nil end
    if not IsValid(item) or item:GetClass() ~= SUIT_BATTERY_CLASS then return nil end

    suitBatteryPickupCandidates[item] = ply

    return nil
end)

hook.Add("EntityRemoved", "FB_RefillFromSuitBatteryPickup", function(entity)
    if not entity or not entity.GetClass or entity:GetClass() ~= SUIT_BATTERY_CLASS then return end

    local ply = suitBatteryPickupCandidates[entity]
    suitBatteryPickupCandidates[entity] = nil
    RefillFromSuitBattery(ply)
end)
