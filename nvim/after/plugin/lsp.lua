-- Ensure mason is initialized before using mason-lspconfig
require("mason").setup()

local mason_lspconfig = require("mason-lspconfig")
local lsp = require("gmm.lsp")

-- Install servers automatically when they're configured via lspconfig
mason_lspconfig.setup({
    automatic_installation = true,
})

-- mason-lspconfig versions prior to v2 do not implement `setup_handlers`.
-- To remain compatible we fall back to manually setting up installed servers
-- when the helper is unavailable.
if mason_lspconfig.setup_handlers then
    mason_lspconfig.setup_handlers({
        function(server_name)
            lsp.setup(server_name)
        end,
    })
else
    mason_lspconfig.setup()
    for _, server_name in ipairs(mason_lspconfig.get_installed_servers()) do
        lsp.setup(server_name)
    end
end

-- start jdtls automatically for Java files
vim.api.nvim_create_autocmd("FileType", {
    pattern = "java",
    callback = function()
        local jdtls = require("jdtls")
        jdtls.start_or_attach({
            on_attach = lsp.on_attach,
            capabilities = lsp.capabilities,
        })
    end,
})
