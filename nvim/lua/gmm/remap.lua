vim.g.mapleader = " "

vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- Harpoon navigation
local harpoon_mark = require('harpoon.mark')
local harpoon_ui   = require('harpoon.ui')
vim.keymap.set('n', '<leader>a', harpoon_mark.add_file)
vim.keymap.set('n', '<leader>e', harpoon_ui.toggle_quick_menu)
for i = 1, 4 do
  vim.keymap.set('n', '<leader>' .. i, function() harpoon_ui.nav_file(i) end)
end
