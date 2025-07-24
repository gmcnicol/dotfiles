local M = {}

local lspconfig = require("lspconfig")
local cmp_nvim_lsp = require("cmp_nvim_lsp")

function M.on_attach(_, bufnr)
    local opts = { buffer = bufnr }
    local nmap = function(keys, func, desc)
        if desc then
            desc = "LSP: " .. desc
        end
        vim.keymap.set("n", keys, func, vim.tbl_extend("force", opts, { desc = desc }))
    end

    nmap("gd", vim.lsp.buf.definition, "Goto Definition")
    nmap("gD", vim.lsp.buf.declaration, "Goto Declaration")
    nmap("gi", vim.lsp.buf.implementation, "Goto Implementation")
    nmap("gr", vim.lsp.buf.references, "Goto References")
    nmap("K", vim.lsp.buf.hover, "Hover Documentation")
    nmap("<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
    nmap("<leader>ca", vim.lsp.buf.code_action, "Code Action")
    nmap("[d", vim.diagnostic.goto_prev, "Previous Diagnostic")
    nmap("]d", vim.diagnostic.goto_next, "Next Diagnostic")
    nmap("<C-S-f>", function()
        vim.lsp.buf.format({ async = true })
    end, "Format File")
end

M.capabilities = cmp_nvim_lsp.default_capabilities()

function M.setup(server_name)
    lspconfig[server_name].setup({
        capabilities = M.capabilities,
        on_attach = M.on_attach,
    })
end

return M
