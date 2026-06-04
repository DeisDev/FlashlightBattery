FlashlightBattery = FlashlightBattery or {}

FlashlightBattery.ServerSettings = {
    {
        name = "fb_enabled",
        label = "Enabled",
        description = "Enable or disable Flashlight Battery without uninstalling the addon.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0
    },
    {
        name = "fb_drain_time",
        label = "Drain time",
        suffix = "seconds",
        description = "Time in seconds to fully drain flashlight from 100% to 0% while on.",
        default = 60,
        min = 10,
        max = 600,
        decimals = 0
    },
    {
        name = "fb_recharge_step",
        label = "Recharge amount",
        suffix = "% per interval",
        description = "Recharge step in percentage per recharge interval when off and not cooling.",
        default = 1,
        min = 0,
        max = 10,
        decimals = 1
    },
    {
        name = "fb_recharge_interval",
        label = "Recharge interval",
        suffix = "seconds",
        description = "Recharge interval in seconds when off and not cooling.",
        default = 0.5,
        min = 0.05,
        max = 5,
        decimals = 2
    },
    {
        name = "fb_cooldown",
        label = "Cooldown",
        suffix = "seconds",
        description = "Cooldown in seconds after full drain before recharging starts.",
        default = 5,
        min = 0,
        max = 60,
        decimals = 0
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
        decimals = 0
    },
    {
        name = "fb_center_notifications",
        label = "Chat notifications",
        description = "Show chat messages when the battery depletes, cooldown ends, or activation is blocked.",
        default = 1,
        type = "bool",
        min = 0,
        max = 1,
        decimals = 0
    }
}

FlashlightBattery.ServerSettingByName = {}

for _, setting in ipairs(FlashlightBattery.ServerSettings) do
    FlashlightBattery.ServerSettingByName[setting.name] = setting
end

FlashlightBattery.HudVisibleBatteryThreshold = 99.5
FlashlightBattery.NetSetConVar = "FB_SetConVar"

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

FlashlightBattery.ClientSettings = {
    {
        name = "fb_hud_anchor",
        label = "HUD corner",
        description = "Choose which screen corner anchors the battery HUD.",
        default = "bottom_right",
        type = "choice",
        choices = FlashlightBattery.HudAnchors,
        order = FlashlightBattery.HudAnchorOrder
    },
    {
        name = "fb_hud_visibility",
        label = "HUD visibility",
        description = "Choose when the battery HUD is shown.",
        default = "auto",
        type = "choice",
        choices = FlashlightBattery.HudVisibilityModes,
        order = FlashlightBattery.HudVisibilityOrder
    },
    {
        name = "fb_hud_opacity",
        label = "HUD opacity",
        suffix = "%",
        description = "Battery HUD opacity.",
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
        description = "Battery HUD size.",
        default = 100,
        type = "number",
        min = 75,
        max = 150,
        decimals = 0
    }
}
