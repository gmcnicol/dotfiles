-- Key mappings for gmm
-- <leader> is space, <leader>pv opens Ex
vim.g.mapleader = " "

-- show line numbers and make them relative
vim.opt.number = true
vim.opt.relativenumber = true

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- yank current line to system clipboard
vim.keymap.set("n", "<leader>Y", '"+yy', { desc = "Yank line" })

-- telescope shortcuts
local telescope = require("telescope.builtin")
vim.keymap.set("n", "<leader>pf", telescope.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>pg", telescope.git_files, { desc = "Git files" })
vim.keymap.set("n", "<leader>ps", function()
  telescope.grep_string({ search = vim.fn.input("Grep > ") })
end, { desc = "Search for string" })
vim.keymap.set("n", "<leader>pws", telescope.grep_string, { desc = "Search word" })
