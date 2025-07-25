local smart_splits = require("smart-splits")

smart_splits.setup({
  default_amount = 5,
})

vim.keymap.set("n", "<C-h>", smart_splits.move_cursor_left)
vim.keymap.set("n", "<C-j>", smart_splits.move_cursor_down)
vim.keymap.set("n", "<C-k>", smart_splits.move_cursor_up)
vim.keymap.set("n", "<C-l>", smart_splits.move_cursor_right)

vim.keymap.set("n", "<C-S-h>", smart_splits.resize_left)
vim.keymap.set("n", "<C-S-j>", smart_splits.resize_down)
vim.keymap.set("n", "<C-S-k>", smart_splits.resize_up)
vim.keymap.set("n", "<C-S-l>", smart_splits.resize_right)
