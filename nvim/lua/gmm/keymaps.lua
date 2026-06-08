local util = require("gmm.util")

local function nmap(keys, func, desc)
  vim.keymap.set("n", keys, func, { desc = desc })
end

local function vmap(keys, func, desc)
  vim.keymap.set("v", keys, func, { desc = desc })
end

nmap("<leader>pv", vim.cmd.Ex, "Project view")
nmap("<leader>Y", '"+yy', "Yank line to clipboard")
vmap("<leader>Y", '"+y', "Yank selection to clipboard")

nmap("<leader>pf", function()
  require("telescope.builtin").find_files({ cwd = util.project_root() })
end, "Find files")

nmap("<leader>pg", function()
  require("telescope.builtin").git_files({ cwd = util.project_root() })
end, "Git files")

nmap("<leader>ps", function()
  require("telescope.builtin").grep_string({
    cwd = util.project_root(),
    search = vim.fn.input("Grep > "),
  })
end, "Search string")

nmap("<leader>pws", function()
  require("telescope.builtin").grep_string({ cwd = util.project_root() })
end, "Search word")

nmap("<leader>e", vim.diagnostic.open_float, "Line diagnostics")
nmap("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
nmap("]d", vim.diagnostic.goto_next, "Next diagnostic")
nmap("<leader>q", vim.diagnostic.setloclist, "Diagnostics list")

nmap("<leader>f", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, "Format buffer")

nmap("<leader>xx", function()
  require("gmm.codex").open()
end, "Open Codex")

nmap("<leader>xr", function()
  require("gmm.codex").resume()
end, "Resume Codex")

nmap("<leader>xa", function()
  require("gmm.codex").ask()
end, "Ask Codex")
