FlashlightBattery = FlashlightBattery or {}

FlashlightBattery.Version = "1.1.1"
FlashlightBattery.NetSetConVar = "FB_SetConVar"
FlashlightBattery.NetClientFlashlightState = "FB_ClientFlashlightState"
FlashlightBattery.NetForceClientFlashlightOff = "FB_ForceClientFlashlightOff"
FlashlightBattery.HudVisibleBatteryThreshold = 99.5

FlashlightBattery.NW = {
    Battery = "FB_Battery",
    Cooldown = "FB_Cooldown",
    CooldownEnd = "FB_CooldownEnd"
}

FlashlightBattery.HudAnchors = {
    top_left = {
        label = "Top left"
    },
    top_right = {
        label = "Top right"
    },
    bottom_left = {
        label = "Bottom left"
    },
    bottom_right = {
        label = "Bottom right"
    }
}

FlashlightBattery.HudAnchorOrder = {
    "bottom_right",
    "bottom_left",
    "top_right",
    "top_left"
}

FlashlightBattery.HudVisibilityModes = {
    auto = {
        label = "Auto"
    },
    always = {
        label = "Always"
    },
    active = {
        label = "Flashlight on"
    },
    hidden = {
        label = "Hidden"
    }
}

FlashlightBattery.HudVisibilityOrder = {
    "auto",
    "always",
    "active",
    "hidden"
}

FlashlightBattery.PickupRefillModes = {
    flat = {
        label = "Flat amount"
    },
    missing_percent = {
        label = "Percent of missing battery"
    },
    multiplier = {
        label = "Current battery multiplier"
    }
}

FlashlightBattery.PickupRefillModeOrder = {
    "flat",
    "missing_percent",
    "multiplier"
}

FlashlightBattery.ServerSettings = {
    {
        name = "fb_enabled",
        label = "Enabled",
        description = "Enable or disable Flashlight Battery without uninstalling the addon.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Gameplay"
    },
    {
        name = "fb_drain_time",
        label = "Drain time",
        suffix = "seconds",
        description = "Time in seconds to fully drain flashlight from 100% to 0% while on.",
        default = 60,
        min = 10,
        max = 600,
        decimals = 0,
        section = "Gameplay"
    },
    {
        name = "fb_recharge_step",
        label = "Recharge amount",
        suffix = "% per interval",
        description = "Recharge step in percentage per recharge interval when off and not cooling.",
        default = 1,
        min = 0,
        max = 10,
        decimals = 1,
        section = "Gameplay"
    },
    {
        name = "fb_recharge_interval",
        label = "Recharge interval",
        suffix = "seconds",
        description = "Recharge interval in seconds when off and not cooling.",
        default = 0.5,
        min = 0.05,
        max = 5,
        decimals = 2,
        section = "Gameplay"
    },
    {
        name = "fb_recharge_requires_pickups",
        label = "Pickup-only recharge",
        description = "Require battery pickups to recharge the flashlight instead of passively recharging while off.",
        default = 0,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Gameplay"
    },
    {
        name = "fb_cooldown",
        label = "Cooldown",
        suffix = "seconds",
        description = "Cooldown in seconds after full drain before recharging starts.",
        default = 5,
        min = 0,
        max = 60,
        decimals = 0,
        section = "Gameplay"
    },
    {
        name = "fb_min_battery_to_turn_on",
        label = "Minimum to turn on",
        suffix = "%",
        description = "Minimum battery percentage required to turn the flashlight on.",
        default = 0,
        type = "number",
        min = 0,
        max = 100,
        decimals = 0,
        section = "Gameplay"
    },
    {
        name = "fb_low_battery_warning_threshold",
        label = "Low battery warning",
        suffix = "%",
        description = "Battery percentage that triggers a one-time low battery warning while the flashlight is on. Set to 0 to disable.",
        default = 20,
        type = "number",
        min = 0,
        max = 100,
        decimals = 0,
        section = "Gameplay"
    },
    {
        name = "fb_center_notifications",
        label = "Enable notifications",
        description = "Master toggle for all Flashlight Battery chat notifications.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Notifications"
    },
    {
        name = "fb_notify_depleted",
        label = "Battery depleted",
        description = "Notify players when their flashlight battery reaches 0%.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Notifications"
    },
    {
        name = "fb_notify_ready",
        label = "Cooldown ready",
        description = "Notify players when cooldown ends and the battery can recharge again.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Notifications"
    },
    {
        name = "fb_notify_blocked",
        label = "Activation blocked",
        description = "Notify players when the flashlight cannot turn on because the battery is cooling down or too low.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Notifications"
    },
    {
        name = "fb_notify_low_battery",
        label = "Low battery warning",
        description = "Notify players when the battery drops to the low battery warning threshold.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Notifications"
    },
    {
        name = "fb_notify_pickup_refill",
        label = "Pickup refill",
        description = "Notify players when a pickup restores flashlight battery.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Notifications"
    },
    {
        name = "fb_pickup_enabled",
        label = "Enable pickups",
        description = "Allow flashlight battery pickup entities to refill player batteries.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_suit_battery_refill_enabled",
        label = "Suit batteries recharge",
        description = "Allow HL2 suit batteries to also restore flashlight battery using the pickup refill settings.",
        default = 0,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_refill_mode",
        label = "Refill mode",
        description = "Choose how battery pickups calculate the amount restored.",
        default = "flat",
        type = "choice",
        choices = FlashlightBattery.PickupRefillModes,
        order = FlashlightBattery.PickupRefillModeOrder,
        section = "Pickups"
    },
    {
        name = "fb_pickup_refill_amount",
        label = "Flat refill amount",
        suffix = "%",
        description = "Battery percentage points restored by pickups when using Flat amount mode.",
        default = 35,
        type = "number",
        min = 1,
        max = 100,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_refill_missing_percent",
        label = "Missing battery refill",
        suffix = "%",
        description = "Percent of missing battery restored by pickups when using Percent of missing battery mode.",
        default = 50,
        type = "number",
        min = 1,
        max = 100,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_refill_multiplier",
        label = "Battery multiplier",
        suffix = "x",
        description = "Current battery multiplier used by pickups when using Current battery multiplier mode.",
        default = 2,
        type = "number",
        min = 1,
        max = 5,
        decimals = 2,
        section = "Pickups"
    },
    {
        name = "fb_pickup_respawn_time",
        label = "Respawn time",
        suffix = "seconds",
        description = "Delay before an automatically spawned pickup is replaced after being collected.",
        default = 60,
        type = "number",
        min = 0,
        max = 600,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_alpha",
        label = "Pickup opacity",
        suffix = "alpha",
        description = "Transparency of the battery pickup model. Lower values are more transparent.",
        default = 180,
        type = "number",
        min = 64,
        max = 255,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_spin_speed",
        label = "Spin speed",
        suffix = "degrees per second",
        description = "How quickly pickup models rotate.",
        default = 35,
        type = "number",
        min = 0,
        max = 180,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_model_scale",
        label = "Model scale",
        suffix = "x",
        description = "Visual scale for pickup models.",
        default = 1,
        type = "number",
        min = 0.5,
        max = 2,
        decimals = 2,
        section = "Pickups"
    },
    {
        name = "fb_pickup_trigger_radius",
        label = "Pickup radius",
        suffix = "units",
        description = "Touch radius used by battery pickups.",
        default = 24,
        type = "number",
        min = 12,
        max = 64,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_sound_enabled",
        label = "Pickup sound",
        description = "Play a sound when a player collects a battery pickup.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_sound_path",
        label = "Pickup sound path",
        description = "Sound file played when a battery pickup is collected.",
        default = "items/battery_pickup.wav",
        type = "string",
        maxLength = 128,
        section = "Pickups"
    },
    {
        name = "fb_pickup_sound_volume",
        label = "Pickup sound volume",
        suffix = "volume",
        description = "Volume for the pickup sound.",
        default = 1,
        type = "number",
        min = 0,
        max = 1,
        decimals = 2,
        section = "Pickups"
    },
    {
        name = "fb_pickup_sound_level",
        label = "Pickup sound level",
        suffix = "dB",
        description = "Sound level for how far the pickup sound can be heard.",
        default = 70,
        type = "number",
        min = 40,
        max = 100,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_sound_pitch",
        label = "Pickup sound pitch",
        suffix = "pitch",
        description = "Pitch for the pickup sound.",
        default = 100,
        type = "number",
        min = 50,
        max = 150,
        decimals = 0,
        section = "Pickups"
    },
    {
        name = "fb_pickup_label_enabled",
        label = "Floating label",
        description = "Show a floating label above battery pickups.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Pickup Label"
    },
    {
        name = "fb_pickup_label_text",
        label = "Label text",
        description = "Text shown above battery pickups.",
        default = "Flashlight Battery",
        type = "string",
        maxLength = 48,
        section = "Pickup Label"
    },
    {
        name = "fb_pickup_label_height",
        label = "Label height",
        suffix = "units",
        description = "Vertical offset above the pickup model for the floating label.",
        default = 18,
        type = "number",
        min = 8,
        max = 128,
        decimals = 0,
        section = "Pickup Label"
    },
    {
        name = "fb_pickup_label_scale",
        label = "Label scale",
        suffix = "x",
        description = "Size of the floating label.",
        default = 0.12,
        type = "number",
        min = 0.05,
        max = 0.3,
        decimals = 2,
        section = "Pickup Label"
    },
    {
        name = "fb_pickup_label_distance",
        label = "Label draw distance",
        suffix = "units",
        description = "Maximum distance where pickup labels are drawn. Set to 0 to always draw.",
        default = 768,
        type = "number",
        min = 0,
        max = 4096,
        decimals = 0,
        section = "Pickup Label"
    },
    {
        name = "fb_pickup_map_spawns_enabled",
        label = "Map random spawns",
        description = "Randomly spawn battery pickups on maps with a navmesh.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "Pickup Spawns"
    },
    {
        name = "fb_pickup_map_spawn_count",
        label = "Map pickup count",
        suffix = "pickups",
        description = "Target number of random battery pickups to keep on the map.",
        default = 8,
        type = "number",
        min = 0,
        max = 64,
        decimals = 0,
        section = "Pickup Spawns"
    },
    {
        name = "fb_pickup_spawn_attempts",
        label = "Spawn attempts",
        suffix = "tries",
        description = "Maximum random navmesh positions checked when placing each pickup.",
        default = 128,
        type = "number",
        min = 8,
        max = 1024,
        decimals = 0,
        section = "Pickup Spawns"
    },
    {
        name = "fb_pickup_float_height",
        label = "Float height",
        suffix = "units",
        description = "How far random pickups float above the ground.",
        default = 18,
        type = "number",
        min = 0,
        max = 64,
        decimals = 0,
        section = "Pickup Spawns"
    },
    {
        name = "fb_pickup_spawn_clearance_radius",
        label = "Wall clearance radius",
        suffix = "units",
        description = "Horizontal hull radius used to avoid spawning pickups inside walls.",
        default = 18,
        type = "number",
        min = 8,
        max = 64,
        decimals = 0,
        section = "Pickup Spawns"
    },
    {
        name = "fb_pickup_spawn_clearance_height",
        label = "Wall clearance height",
        suffix = "units",
        description = "Vertical hull height used to avoid spawning pickups inside walls.",
        default = 36,
        type = "number",
        min = 16,
        max = 128,
        decimals = 0,
        section = "Pickup Spawns"
    },
    {
        name = "fb_pickup_spawn_min_player_distance",
        label = "Minimum player distance",
        suffix = "units",
        description = "Avoid random pickup spawns near players. Set to 0 to disable.",
        default = 512,
        type = "number",
        min = 0,
        max = 4096,
        decimals = 0,
        section = "Pickup Spawns"
    },
    {
        name = "fb_admin_hud_enabled",
        label = "Force HUD settings",
        description = "Force all players to use the server HUD layout below instead of their local HUD preferences.",
        default = 0,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0,
        section = "HUD"
    },
    {
        name = "fb_admin_hud_anchor",
        label = "HUD corner",
        description = "Server-forced HUD corner when Force HUD settings is enabled.",
        default = "bottom_right",
        type = "choice",
        choices = FlashlightBattery.HudAnchors,
        order = FlashlightBattery.HudAnchorOrder,
        section = "HUD"
    },
    {
        name = "fb_admin_hud_visibility",
        label = "HUD visibility",
        description = "Server-forced HUD visibility mode when Force HUD settings is enabled.",
        default = "auto",
        type = "choice",
        choices = FlashlightBattery.HudVisibilityModes,
        order = FlashlightBattery.HudVisibilityOrder,
        section = "HUD"
    },
    {
        name = "fb_admin_hud_opacity",
        label = "HUD opacity",
        suffix = "%",
        description = "Server-forced HUD opacity when Force HUD settings is enabled.",
        default = 100,
        type = "number",
        min = 20,
        max = 100,
        decimals = 0,
        section = "HUD"
    },
    {
        name = "fb_admin_hud_scale",
        label = "HUD scale",
        suffix = "%",
        description = "Server-forced HUD size when Force HUD settings is enabled.",
        default = 100,
        type = "number",
        min = 75,
        max = 150,
        decimals = 0,
        section = "HUD"
    }
}

FlashlightBattery.ServerSettingByName = {}

for _, setting in ipairs(FlashlightBattery.ServerSettings) do
    FlashlightBattery.ServerSettingByName[setting.name] = setting
end

FlashlightBattery.ClientSettings = {
    {
        name = "fb_hud_anchor",
        label = "HUD corner",
        description = "Choose which screen corner anchors the battery HUD when the server is not forcing HUD settings.",
        default = "bottom_right",
        type = "choice",
        choices = FlashlightBattery.HudAnchors,
        order = FlashlightBattery.HudAnchorOrder
    },
    {
        name = "fb_hud_visibility",
        label = "HUD visibility",
        description = "Choose when the battery HUD is shown when the server is not forcing HUD settings.",
        default = "auto",
        type = "choice",
        choices = FlashlightBattery.HudVisibilityModes,
        order = FlashlightBattery.HudVisibilityOrder
    },
    {
        name = "fb_hud_opacity",
        label = "HUD opacity",
        suffix = "%",
        description = "Battery HUD opacity when the server is not forcing HUD settings.",
        default = 100,
        type = "number",
        min = 20,
        max = 100,
        decimals = 0
    },
    {
        name = "fb_hud_scale",
        label = "HUD scale",
        suffix = "%",
        description = "Battery HUD size when the server is not forcing HUD settings.",
        default = 100,
        type = "number",
        min = 75,
        max = 150,
        decimals = 0
    }
}
