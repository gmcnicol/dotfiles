local M = {}

local function on_attach(_, bufnr)
  local opts = { buffer = bufnr }
  local function nmap(keys, func, desc)
    vim.keymap.set("n", keys, func, vim.tbl_extend("force", opts, { desc = desc }))
  end

  nmap("gd", vim.lsp.buf.definition, "Goto definition")
  nmap("gD", vim.lsp.buf.declaration, "Goto declaration")
  nmap("gi", vim.lsp.buf.implementation, "Goto implementation")
  nmap("gr", vim.lsp.buf.references, "Goto references")
  nmap("K", vim.lsp.buf.hover, "Hover")
  nmap("<leader>rn", vim.lsp.buf.rename, "Rename")
  nmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
end

M.on_attach = on_attach
M.capabilities = require("cmp_nvim_lsp").default_capabilities()

local function setup_server(lspconfig, server, opts)
  opts = opts or {}
  if not lspconfig[server] then
    return
  end

  lspconfig[server].setup(vim.tbl_deep_extend("force", {
    capabilities = M.capabilities,
    on_attach = M.on_attach,
  }, opts))
end

function M.setup()
  require("mason").setup()

  local lspconfig = require("lspconfig")
  local ts_server = vim.fn.has("nvim-0.10") == 1 and "ts_ls" or "tsserver"
  local servers = {
    "lua_ls",
    "jsonls",
    "yamlls",
    "html",
    "cssls",
    "eslint",
    "sqlls",
    ts_server,
  }

  require("mason-lspconfig").setup({
    ensure_installed = servers,
    automatic_installation = true,
  })

  require("mason-tool-installer").setup({
    ensure_installed = {
      "jdtls",
      "java-debug-adapter",
      "java-test",
      "prettier",
      "stylua",
      "typescript-language-server",
      "eslint-lsp",
      "json-lsp",
      "yaml-language-server",
      "html-lsp",
      "css-lsp",
      "lua-language-server",
      "sqlls",
    },
    auto_update = false,
    run_on_start = true,
    start_delay = 3000,
  })

  setup_server(lspconfig, ts_server)
  setup_server(lspconfig, "eslint")
  setup_server(lspconfig, "jsonls")
  setup_server(lspconfig, "yamlls")
  setup_server(lspconfig, "html")
  setup_server(lspconfig, "cssls")
  setup_server(lspconfig, "sqlls")
  setup_server(lspconfig, "lua_ls", {
    settings = {
      Lua = {
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          checkThirdParty = false,
        },
        telemetry = {
          enable = false,
        },
      },
    },
  })
end

return M
