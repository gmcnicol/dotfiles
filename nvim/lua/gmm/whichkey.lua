local M = {}

function M.setup()
  local wk = require("which-key")
  wk.setup({})
  wk.register({
    ["<leader>c"] = { name = "code" },
    ["<leader>d"] = { name = "debug" },
    ["<leader>j"] = { name = "java" },
    ["<leader>m"] = { name = "maven" },
    ["<leader>o"] = { name = "overseer" },
    ["<leader>p"] = { name = "project" },
    ["<leader>x"] = { name = "codex" },
  })
end

return M
