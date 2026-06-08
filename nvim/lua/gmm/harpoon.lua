local M = {}

function M.setup()
  local harpoon = require("harpoon")
  harpoon:setup()

  vim.keymap.set("n", "<leader>a", function()
    harpoon:list():add()
  end, { desc = "Harpoon add" })

  vim.keymap.set("n", "<C-e>", function()
    harpoon.ui:toggle_quick_menu(harpoon:list())
  end, { desc = "Harpoon menu" })

  for i = 1, 9 do
    vim.keymap.set("n", string.format("<leader>h%s", i), function()
      harpoon:list():select(i)
    end, { desc = string.format("Harpoon %d", i) })
  end

  vim.keymap.set("n", "<C-S-P>", function()
    harpoon:list():prev()
  end, { desc = "Harpoon previous" })

  vim.keymap.set("n", "<C-S-N>", function()
    harpoon:list():next()
  end, { desc = "Harpoon next" })
end

return M
