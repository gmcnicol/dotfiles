local M = {}

function M.setup()
  local smart_splits = require("smart-splits")

  smart_splits.setup({
    default_amount = 5,
  })

  vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left, { desc = "Move left" })
  vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down, { desc = "Move down" })
  vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up, { desc = "Move up" })
  vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Move right" })

  vim.keymap.set("n", "<C-S-h>", smart_splits.resize_left, { desc = "Resize left" })
  vim.keymap.set("n", "<C-S-j>", smart_splits.resize_down, { desc = "Resize down" })
  vim.keymap.set("n", "<C-S-k>", smart_splits.resize_up, { desc = "Resize up" })
  vim.keymap.set("n", "<C-S-l>", smart_splits.resize_right, { desc = "Resize right" })
end

return M
