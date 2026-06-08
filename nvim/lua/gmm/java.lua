local M = {}

local function glob(pattern)
  return vim.split(vim.fn.glob(pattern), "\n", { trimempty = true })
end

local function first_readable(paths)
  for _, path in ipairs(paths) do
    if path and path ~= "" and vim.fn.filereadable(path) == 1 then
      return path
    end
  end
end

local function lombok_path()
  local data = vim.fn.stdpath("data")
  local candidates = {
    data .. "/mason/packages/jdtls/lombok.jar",
    data .. "/mason/packages/lombok-nightly/lombok.jar",
    vim.fn.expand("$HOME/.local/share/lombok/lombok.jar"),
  }
  return first_readable(candidates)
end

local function bundles()
  local data = vim.fn.stdpath("data")
  local result = {}

  for _, path in ipairs(glob(data .. "/mason/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar")) do
    table.insert(result, path)
  end
  for _, path in ipairs(glob(data .. "/mason/packages/java-test/extension/server/*.jar")) do
    table.insert(result, path)
  end

  return result
end

local function java_keymaps(bufnr)
  local opts = { buffer = bufnr }
  local function nmap(keys, func, desc)
    vim.keymap.set("n", keys, func, vim.tbl_extend("force", opts, { desc = desc }))
  end

  nmap("<leader>jo", function()
    require("jdtls").organize_imports()
  end, "Java organize imports")

  nmap("<leader>jt", function()
    require("jdtls").test_nearest_method()
  end, "Java test nearest")

  nmap("<leader>jT", function()
    require("jdtls").test_class()
  end, "Java test class")

  nmap("<leader>jd", function()
    require("jdtls").test_nearest_method()
  end, "Java debug nearest")

  nmap("<leader>jr", function()
    require("jdtls.dap").setup_dap_main_class_configs()
    require("dap").continue()
  end, "Java run main")

  nmap("<leader>ju", "<cmd>JdtUpdateConfig<cr>", "Java update config")
end

function M.start_or_attach()
  local jdtls = require("jdtls")
  local lsp = require("gmm.lsp")
  local root_markers = { "mvnw", "gradlew", "pom.xml", "build.gradle", "settings.gradle", ".git" }
  local root_dir = require("jdtls.setup").find_root(root_markers)

  if not root_dir then
    return
  end

  local project_name = vim.fn.fnamemodify(root_dir, ":p:h:t")
  local workspace_dir = vim.fn.stdpath("data") .. "/jdtls-workspaces/" .. project_name
  local cmd = { "jdtls", "-data", workspace_dir }
  local lombok = lombok_path()
  if lombok then
    table.insert(cmd, "--jvm-arg=-javaagent:" .. lombok)
  end

  jdtls.start_or_attach({
    cmd = cmd,
    root_dir = root_dir,
    capabilities = lsp.capabilities,
    on_attach = function(client, bufnr)
      lsp.on_attach(client, bufnr)
      java_keymaps(bufnr)
      pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
      pcall(jdtls.dap.setup_dap_main_class_configs)
    end,
    settings = {
      java = {
        maven = {
          downloadSources = true,
        },
        implementationsCodeLens = {
          enabled = true,
        },
        referencesCodeLens = {
          enabled = true,
        },
        references = {
          includeDecompiledSources = true,
        },
        signatureHelp = {
          enabled = true,
        },
        contentProvider = {
          preferred = "fernflower",
        },
        configuration = {
          updateBuildConfiguration = "interactive",
        },
        saveActions = {
          organizeImports = true,
        },
      },
    },
    init_options = {
      bundles = bundles(),
    },
  })
end

return M
