local wezterm = require("wezterm")
local mux = wezterm.mux

wezterm.on("gui-startup", function(cmd)
  local tab, pane, window = mux.spawn_window(cmd or {})
  window:gui_window():maximize()
end)

local config = wezterm.config_builder()

config.term = "xterm-256color"
config.send_composed_key_when_left_alt_is_pressed = true
config.send_composed_key_when_right_alt_is_pressed = true

local direction_keys = {
  h = "Left",
  j = "Down",
  k = "Up",
  l = "Right",
}

local function split_nav(key)
  return {
    key = key,
    mods = "CTRL",
    action = wezterm.action_callback(function(win, pane)
      if pane:get_user_vars().IS_NVIM == "true" then
        win:perform_action({ SendKey = { key = key, mods = "CTRL" } }, pane)
      else
        win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
      end
    end),
  }
end

config.font_size = 16
config.colors = {
  foreground = '#c0caf5',
  background = '#1a1b26',
  ansi = {
    '#15161e',
    '#f7768e',
    '#9ece6a',
    '#e0af68',
    '#7aa2f7',
    '#bb9af7',
    '#7dcfff',
    '#a9b1d6',
  },
  brights = {
    '#414868',
    '#ff899d',
    '#9fe044',
    '#faba4a',
    '#8db0ff',
    '#c7a9ff',
    '#a4daff',
    '#c0caf5',
  },
  indexed = {
    [16] = '#ff9e64',
    [17] = '#db4b4b',
  },
}
config.window_decorations = "RESIZE"
config.window_padding = {
  top = '2cell',
  bottom = '2cell',
  left = '2cell',
  right = '2cell',
}

-- Prevent Wayland buffer scale errors when toggling font size on HiDPI displays
config.adjust_window_size_when_changing_font_size = true

config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 2000 }

local action = wezterm.action

config.keys = {
  {
    key = "\\",
    mods = "LEADER",
    action = action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
  },
  split_nav("h"),
  split_nav("j"),
  split_nav("k"),
  split_nav("l"),
  {
    key = "h",
    mods = "CTRL|SHIFT",
    action = action.AdjustPaneSize({ "Left", 5 }),
  },
  {
    key = "l",
    mods = "CTRL|SHIFT",
    action = action.AdjustPaneSize({ "Right", 5 }),
  },
  {
    key = "j",
    mods = "CTRL|SHIFT",
    action = action.AdjustPaneSize({ "Down", 5 }),
  },
  {
    key = "k",
    mods = "CTRL|SHIFT",
    action = action.AdjustPaneSize({ "Up", 5 }),
  },
  {
    key = "-",
    mods = "LEADER",
    action = action.SplitVertical({ domain = "CurrentPaneDomain" }),
  },
  {
    key = "m",
    mods = "LEADER",
    action = action.TogglePaneZoomState,
  },
  { key = "[", mods = "LEADER", action = action.ActivateCopyMode },
  {
    key = "c",
    mods = "LEADER",
    action = action.SpawnTab("CurrentPaneDomain"),
  },
  {
    key = "p",
    mods = "LEADER",
    action = action.ActivateTabRelative(-1),
  },
  {
    key = "n",
    mods = "LEADER",
    action = action.ActivateTabRelative(1),
  },
}

for i = 1, 9 do
  table.insert(config.keys, {
    key = tostring(i),
    mods = "LEADER",
    action = action.ActivateTab(i - 1),
  })
end

return config
