local M = {}

local function run_task(name, cmd, args, cwd)
  local overseer = require("overseer")
  local task = overseer.new_task({
    name = name,
    cmd = cmd,
    args = args,
    cwd = cwd,
    components = {
      "default",
      { "on_output_quickfix", open = false },
    },
  })
  task:start()
  overseer.open({ enter = false })
end

local function run_maven(goal)
  local util = require("gmm.util")
  local cmd, root = util.maven_cmd()
  run_task("mvn " .. goal, cmd, vim.split(goal, " ", { trimempty = true }), root)
end

function M.setup()
  local overseer = require("overseer")

  overseer.setup({
    dap = true,
    task_list = {
      direction = "bottom",
      min_height = 8,
      max_height = 18,
    },
    templates = { "builtin" },
  })

  vim.api.nvim_create_user_command("Maven", function(opts)
    run_maven(opts.args)
  end, {
    nargs = "+",
    complete = function()
      return {
        "compile",
        "test",
        "package",
        "verify",
        "clean",
        "clean test",
        "spring-boot:run",
      }
    end,
  })

  vim.keymap.set("n", "<leader>mc", function()
    run_maven("compile")
  end, { desc = "Maven compile" })

  vim.keymap.set("n", "<leader>mt", function()
    run_maven("test")
  end, { desc = "Maven test" })

  vim.keymap.set("n", "<leader>mp", function()
    run_maven("package")
  end, { desc = "Maven package" })

  vim.keymap.set("n", "<leader>mb", function()
    run_maven("spring-boot:run")
  end, { desc = "Maven Spring Boot run" })

  vim.keymap.set("n", "<leader>mR", function()
    vim.ui.input({ prompt = "Maven goal: " }, function(goal)
      if goal and goal ~= "" then
        run_maven(goal)
      end
    end)
  end, { desc = "Maven goal" })

  vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<cr>", { desc = "Run task" })
  vim.keymap.set("n", "<leader>ot", "<cmd>OverseerToggle<cr>", { desc = "Toggle tasks" })
end

return M
