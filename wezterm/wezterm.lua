local wezterm = require 'wezterm'

return {
  font_size = 16.0,
  colors = {
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
  },
  keys = {
    {
      key = 'Space',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.ActivateCopyMode,
    },
  },
}
