local mason_lspconfig = require("mason-lspconfig")
local lsp = require("gmm.lsp")

mason_lspconfig.setup_handlers({
  function(server_name)
    lsp.setup(server_name)
  end,
})

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
