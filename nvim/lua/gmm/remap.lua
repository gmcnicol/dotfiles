-- Key mappings for gmm
-- <leader> is space, <leader>pv opens Ex
vim.g.mapleader = " "

-- show line numbers and make them relative
vim.opt.number = true
vim.opt.relativenumber = true

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
