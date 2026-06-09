local M = {}

local function shell_cmd(command)
  return vim.fn.shellescape(command)
end

function M.open()
  local util = require("gmm.util")
  util.open_terminal("zsh -ic " .. shell_cmd("cx"), {
    cwd = util.project_root(),
    size = 18,
  })
end

function M.resume()
  local util = require("gmm.util")
  util.open_terminal("zsh -ic " .. shell_cmd("codex resume"), {
    cwd = util.project_root(),
    size = 18,
  })
end

function M.ask()
  vim.ui.input({ prompt = "Codex > " }, function(prompt)
    if not prompt or prompt == "" then
      return
    end

    local util = require("gmm.util")
    util.open_terminal("zsh -ic " .. shell_cmd("cx " .. vim.fn.shellescape(prompt)), {
      cwd = util.project_root(),
      size = 18,
    })
  end)
end

return M
