-- Hyprland Lua config (converted from hyprland.conf)
-- Docs: https://wiki.hypr.land/Configuring/Start/
-- You can split this config into multiple files and load them with require("myFile")

------------------
---- MONITORS ----
------------------
-- See https://wiki.hypr.land/Configuring/Basics/Monitors/

for i = 1, 8 do
    hl.monitor({ output = "DP-" .. i, mode = "highres", position = "auto", scale = 1 })
end

local aorus = "desc:GIGA-BYTE TECHNOLOGY CO. LTD. AORUS FO32U2 24080B003919"
local hpZ40 = "desc:HP Inc. HP Z40c G3 CN434615R"

hl.monitor({ output = aorus, mode = "3840x2160@240", position = "2560x-1800", scale = 1 })
hl.monitor({ output = hpZ40, mode = "5120x2160@60",  position = "2560x-1800", scale = 1 })
-- eDP-1 (laptop) placed to the LEFT of the external monitor, bottom edges aligned.
-- logical size = 2560x1600 / 1.333333 = 1920x1200
-- x: external left edge = 2560, so x = 2560-1920 = 640
-- y: external bottom = -1800+2160 = 360, so y = 360-1200 = -840
hl.monitor({ output = "eDP-1", mode = "2560x1600@180", position = "640x-840", scale = 1.333333 })

--------------------
---- WORKSPACES ----
--------------------
-- See https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/

-----------------
---- PLUGINS ----
-----------------
-- hyprbars: per-window title bar with tappable buttons (touch-friendly window
-- controls). Installed from the AUR package hyprland-plugin-hyprbars, which is
-- version-locked to the running Hyprland - it must be reinstalled after every
-- Hyprland update or the plugin will refuse to load.

hl.plugin.load("/usr/lib/libhyprbars.so")

-- Colours mirror waybar (see ~/.config/waybar/style.css): opaque black bar,
-- @overlay0 (#aaaaaa) text, @overlay1 (#888888) accents.
hl.config({
    plugin = {
        hyprbars = {
            bar_height                 = 26,
            bar_padding                = 10,
            bar_button_padding         = 8,
            bar_color                  = "rgba(000000ff)",
            ["col.text"]               = "rgb(aaaaaa)",
            bar_text_font              = "JetBrainsMono Nerd Font",
            bar_text_size              = 11,
            bar_text_align             = "center",
            bar_buttons_alignment      = "right",
            bar_part_of_window         = true,
            bar_precedence_over_border = true,
        },
    },
})

-- Buttons render right-to-left in the order they are added.
-- NOTE: `action` must be a shell command string (not an hl.dsp dispatcher),
-- so window actions have to go back out through hyprctl.
--
-- Deliberately no fullscreen button: hyprbars does not draw on fullscreen
-- windows and waybar sits on the `top` layer (below fullscreen), so there
-- would be no way to leave fullscreen without a keyboard.
hl.plugin.hyprbars.add_button({
    bg_color = "rgb(cc241d)",
    fg_color = "rgb(000000)",
    size     = 12,
    icon     = "",
    action   = "hyprctl dispatch 'hl.dsp.window.close()'",
})

---------------------
---- MY PROGRAMS ----
---------------------

local terminal    = "ghostty"
local fileManager = "ghostty --class=dev.tui.yazi -e yazi"
local menu        = "wofi -S drun -i"
-- App drawer: a resident nwg-drawer instance is started by ~/.local/bin/
-- drawer-daemon (see AUTOSTART), which owns the flags. The waybar button runs
-- ~/.local/bin/drawer-toggle, which only shows/hides that instance.

-------------------
---- AUTOSTART ----
-------------------
-- See https://wiki.hypr.land/Configuring/Basics/Autostart/
-- hyprland.start fires once at startup (like the old exec-once)

local btop_cmd = "~/.config/hypr/btop-launch.sh"

hl.on("hyprland.start", function()
    hl.exec_cmd("hypridle & hyprpaper & hyprlock")
    hl.exec_cmd("wl-clip-persist --clipboard regular")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("udiskie -aTN")

    hl.exec_cmd("chromium", { workspace = "1" })
    hl.exec_cmd("gtk-launch chrome-faolnafnngnfdaknnbpnkhgohbobgegn-Default.desktop", { workspace = "10 silent" })
    hl.exec_cmd("gtk-launch chrome-ompifgpmddkgmclendfeacglnodjjndh-Default.desktop", { workspace = "11 silent" })

    hl.exec_cmd("~/.config/hypr/waybar-launch.sh")
    hl.exec_cmd("~/.config/hypr/autoreload-waybar.sh")

    -- Resident app drawer, so the waybar button opens it in ~50 ms.
    hl.exec_cmd("~/.local/bin/drawer-daemon")

    -- Keeps wvkbd running hidden, with --auto only while the folio is detached.
    hl.exec_cmd("~/.local/bin/osk-folio-watch")

    hl.exec_cmd("$HOME/.local/lib/import_env tmux")
    hl.exec_cmd("$HOME/.local/lib/import_env system")
    hl.exec_cmd("~/.config/hypr/lid-init.sh")
end)

hl.exec_cmd("~/.config/hypr/lid-init.sh")
hl.exec_cmd("pacman -Qe > ~/dotfiles/installed-packages.txt")
-- Runs on every config reload too, but btop-launch.sh is single-instance
-- guarded, so a reload only respawns btop when no window is present.
hl.exec_cmd(btop_cmd, { workspace = "13 silent" })

-- React to monitor hotplug natively.
-- lid-init.sh reassigns workspaces per monitor and re-evaluates waybar output.
hl.on("monitor.added",   function() hl.exec_cmd("~/.config/hypr/lid-init.sh") end)
hl.on("monitor.removed", function() hl.exec_cmd("~/.config/hypr/lid-init.sh") end)

-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("OZONE_PLATFORM", "wayland")

-----------------------
---- LOOK AND FEEL ----
-----------------------
-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 5,

        border_size = 2,

        col = {
            active_border   = "rgba(333333ff)",
            inactive_border = "rgba(000000dd)",
        },

        resize_on_border = false,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 1,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            color        = "rgba(1a1a1aee)",
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },

    animations = {
        enabled = true,
    },
})

------------------
---- ANIMATIONS --
------------------
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/

hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1.0}  } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })

-----------------
---- LAYOUTS ----
-----------------

hl.config({
    dwindle = {
        preserve_split         = true,
        split_width_multiplier = 0,
    },

    master = {
        new_status        = "slave",
        allow_small_split = true,
        mfact             = 0.70,
    },
})

----------------
----  MISC  ----
----------------

hl.config({
    misc = {
        force_default_wallpaper  = 1,
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        background_color         = "rgba(000000ff)",
    },
})

---------------
---- INPUT ----
---------------

hl.config({
    input = {
        kb_layout  = "us(altgr-intl)",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 0,
        sensitivity  = 0,

        touchpad = {
            natural_scroll = false,
            disable_while_typing = true
        },
    },

    xwayland = {
        force_zero_scaling   = true,
        use_nearest_neighbor = true,
    },

    -- tablet: don't leave a stale pointer arrow sitting on screen after
    -- touch/pen input. cursor reappears as soon as the mouse/touchpad moves.
    cursor = {
        hide_on_touch                  = true,
        hide_on_key_press              = false,
        warp_back_after_non_mouse_input = true,
    },
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})

------------------
---- GESTURES ----
------------------

-- No gestures configured. The app drawer is opened from the waybar button.
-- NOTE: Hyprland's gesture engine consumes libinput *gesture* events, which
-- touchscreens never emit (they send raw touch points), so any gesture added
-- here would apply to the touchpad only.

---------------------
---- KEYBINDINGS ----
---------------------
-- See https://wiki.hypr.land/Configuring/Basics/Binds/

local mainMod = "SUPER"
local secMod  = "ALT"
local ctrl    = "CTRL"

hl.bind(mainMod .. " + C", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + M", hl.dsp.exit())
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileManager))
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exec_cmd("thunar"))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + end", hl.dsp.exec_cmd(menu))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("chromium"))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("rider"))

-- wifi / bluetooth TUIs (float rules match on the --class app-id)
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(terminal .. " --class=dev.tui.wlctl -e wlctl"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd(terminal .. " --class=dev.tui.bluetui -e bluetui"))
hl.bind(mainMod .. " + S", hl.dsp.exec_cmd(terminal .. " --class=dev.tui.wiremix -e wiremix"))

-- ROG side button: 1 tap arms brightness mode (volume keys change brightness),
-- 3 taps enter Steam Gaming Mode. The button cannot be held - the firmware
-- sends press and release within ~1ms - so everything is tap counting.
hl.bind("XF86Launch3", hl.dsp.exec_cmd("~/.local/bin/side-button"), { locked = true })

hl.bind(ctrl .. " + " .. secMod .. " + Q", hl.dsp.exec_cmd("hyprlock"))

hl.bind("PRINT", hl.dsp.exec_cmd("hyprshot -m output --raw | swappy -f -"))
hl.bind(mainMod .. " + PRINT", hl.dsp.exec_cmd("hyprshot -m active --raw | swappy -f -"))
hl.bind(mainMod .. " + SHIFT + PRINT", hl.dsp.exec_cmd("hyprshot -m region --raw | swappy -f -"))
hl.bind(mainMod .. " + SHIFT + slash", hl.dsp.layout("togglesplit"))

-- toggle on-screen keyboard (wvkbd)
-- locked = true -> keybind still fires while hyprlock is active
hl.bind(mainMod .. " + O", hl.dsp.exec_cmd("zsh ~/.config/hypr/osk-toggle.sh"), { locked = true })

-- toggle the Azure VPN tunnel (WireGuard -> Windows gateway VM)
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("~/.local/bin/azvpn toggle"))

-- Move focus
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

-- Move window
hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

-- Resize active window
hl.bind(mainMod .. " + right", hl.dsp.window.resize({ x = 50,  y = 0,   relative = true }))
hl.bind(mainMod .. " + left",  hl.dsp.window.resize({ x = -50, y = 0,   relative = true }))
hl.bind(mainMod .. " + up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }))
hl.bind(mainMod .. " + down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }))

hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.resize({ x = 200,  y = 0,    relative = true }))
hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.resize({ x = -200, y = 0,    relative = true }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.resize({ x = 0,    y = -200, relative = true }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.resize({ x = 0,    y = 200,  relative = true }))

-- Switch workspaces + move active window to workspace
local wsKeys = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "minus", "equal", "backslash" }
for i, key in ipairs(wsKeys) do
    hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = tostring(i) }))
end

-- Move workspace to other monitor
hl.bind(mainMod .. " + SHIFT + TAB", hl.dsp.workspace.move({ monitor = "+1" }))

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize with mainMod + LMB/RMB
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Laptop multimedia keys
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("~/.local/bin/vol-or-bright up"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("~/.local/bin/vol-or-bright down"), { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl s +10%"),                           { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl s 10%-"),                           { locked = true, repeating = true })

-- Requires playerctl
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

-- Clamshell mode: trigger when lid switch changes
hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("zsh ~/.config/hypr/lid-init.sh"), { locked = true })

-- toggle power profiles
hl.bind("XF86Launch4", hl.dsp.exec_cmd("zsh ~/.config/hypr/power-profile.sh"), { locked = true })

-- toggle kbd backlight
hl.bind("XF86KbdLightOnOff", hl.dsp.exec_cmd("asusctl leds next"), { locked = true })

-- toggle meme
hl.bind(mainMod .. " + period", hl.dsp.exec_cmd("flemozi"))

--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------
-- See https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- xwayland-video-bridge fixes
hl.window_rule({
    name  = "xwayland-video-bridge-fixes",
    match = { class = "xwaylandvideobridge" },

    no_initial_focus = true,
    no_focus         = true,
    no_anim          = true,
    no_blur          = true,
    max_size         = "1 1",
    opacity          = "0.0",
})

-- annoying teams sharing popup
hl.window_rule({
    name  = "teams-sharing-popup",
    match = { title = "^(teams\\.cloud\\.microsoft is sharing .*)$" },

    opacity     = "0",
    border_size = 0,
    no_blur     = true,
    no_dim      = true,
    no_focus    = true,
    no_shadow   = true,
    opaque      = false,
})

-- outlook on workspace 10
hl.window_rule({
    name  = "outlook-ws10",
    match = { class = "^(chrome-faolnafnngnfdaknnbpnkhgohbobgegn-Default)$" },
    workspace = "10 silent",
    ["hyprbars:no_bar"] = true,
})

-- teams on workspace 11
hl.window_rule({
    name  = "teams-ws11",
    match = { class = "^(chrome-ompifgpmddkgmclendfeacglnodjjndh-Default)$" },
    workspace = "11 silent",
    ["hyprbars:no_bar"] = true,
})

-- tidal on workspace 12
hl.window_rule({
    name  = "tidal-ws12",
    match = { class = "^(tidal-hifi)$" },
    workspace = "12 silent",
})

-- btop
hl.window_rule({
    name  = "btop",
    match = { class = "^(dev\\.tui\\.btop)$" },
    ["hyprbars:no_bar"] = true,
    border_size = 0,
    monitor     = "eDP-1",
    workspace   = "13",
})

-- calculator
hl.window_rule({
    name  = "calculator-float",
    match = { class = "^(org.gnome.Calculator)$" },
    ["hyprbars:no_bar"] = true,
    float = true,
    size  = "375 666",
})

-- scangearmp2 (Canon scanner GUI): float + center
hl.window_rule({
    name   = "scangearmp2-float",
    match  = { class = "^(Scangearmp2)$" },
    float  = true,
    center = true,
})

-- yazi (file manager TUI, SUPER+E)
hl.window_rule({
    name   = "yazi-float",
    match  = { class = "^(dev.tui.yazi)$" },
    float  = true,
    center = true,
    size   = "1400 900",
})

-- wiremix (audio TUI, launched from waybar pulseaudio module)
hl.window_rule({
    name   = "wiremix-float",
    match  = { class = "^(dev.tui.wiremix)$" },
    float  = true,
    center = true,
    size   = "900 900",
})

-- wlctl (wifi TUI, launched from waybar network module)
hl.window_rule({
    name   = "wlctl-float",
    match  = { class = "^(dev.tui.wlctl)$" },
    float  = true,
    center = true,
    size   = "900 900",
})

-- bluetui (bluetooth TUI, launched from waybar bluetooth module)
hl.window_rule({
    name   = "bluetui-float",
    match  = { class = "^(dev.tui.bluetui)$" },
    float  = true,
    center = true,
    size   = "900 900",
})

-- pinentry (gpg / password prompts): float + center,
-- otherwise it gets tiled full-size. GTK2 build runs under xwayland, and the
-- WM_CLASS it reports varies by build (pinentry / pinentry-gtk-2), so match loose.
hl.window_rule({
    name  = "pinentry-float",
    match = { class = "^([Pp]inentry.*)$" },
    float  = true,
    center = true,
    size   = "400 200",
})

-- gsimplecal: float, no anim (calendar-toggle.sh moves it to the top-right)
hl.window_rule({
    name  = "gsimplecal",
    match = { class = "^(gsimplecal)$" },
    float   = true,
    no_anim = true,
})

-- xwayland: no min size
hl.window_rule({
    name  = "xwayland-no-minsize",
    match = { xwayland = true },
    min_size    = "1 1",
    no_max_size = true,
})

-- JetBrains Rider (native Wayland) popups keep-alive. 
hl.window_rule({
    name  = "jetbrains-rider-popups",
    match = { class = "^(jetbrains-rider)$", title = "^$" },
    stay_focused = true,
})

-- firefox (windows avd)
 hl.window_rule({
    name = "Firefox kiosk as normal window",
    match = { class = "firefox" },
    fullscreen_state = "0 0"
})

-- No hyprbars title bar on apps that draw their own window controls.
--
-- NOTE: the plugin rule key is "hyprbars:no_bar", NOT the hyprlang spelling
-- "plugin:hyprbars:no_bar" -- the lua parser strips the "plugin:" prefix and
-- rejects the full name with "unknown field".
hl.window_rule({
    name   = "nobar-jetbrains-rider",
    match  = { class = "^(jetbrains-rider)$" },
    ["hyprbars:no_bar"] = true,
})

hl.window_rule({
    name   = "nobar-chromium",
    match  = { class = "^(chromium)$" },
    ["hyprbars:no_bar"] = true,
})

hl.window_rule({
    name   = "nobar-steam",
    match  = { class = "^(steam)$" },
    ["hyprbars:no_bar"] = true,
})

hl.window_rule({
    name   = "nobar-bambustudio",
    match  = { class = "^(BambuStudio)$" },
    ["hyprbars:no_bar"] = true,
})

hl.window_rule({
    name   = "nobar-vscode",
    match  = { class = "^([Cc]ode)$" },
    ["hyprbars:no_bar"] = true,
})

-----------------
---- LAYERS ----
-----------------

-- on-screen keyboard (wvkbd) usable on the lock screen.
-- above_lock = 2 -> rendered above hyprlock AND receives input (1/true = render only).
hl.layer_rule({
    name       = "wvkbd-above-lock",
    match      = { namespace = "^wvkbd$" },
    above_lock = 2,
})

