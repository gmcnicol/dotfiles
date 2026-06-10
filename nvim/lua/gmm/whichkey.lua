local M = {}

function M.setup()
  local wk = require("which-key")
  wk.setup({})
  wk.add({
    { "<leader>c", group = "code" },
    { "<leader>d", group = "debug" },
    { "<leader>j", group = "java" },
    { "<leader>m", group = "maven" },
    { "<leader>o", group = "overseer" },
    { "<leader>p", group = "project" },
    { "<leader>x", group = "codex" },
  })
end

return M
