local M = {}

function M.setup()
  local dap = require("dap")
  local dapui = require("dapui")

  dapui.setup()

  dap.listeners.before.attach.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.launch.dapui_config = function()
    dapui.open()
  end
  dap.listeners.before.event_terminated.dapui_config = function()
    dapui.close()
  end
  dap.listeners.before.event_exited.dapui_config = function()
    dapui.close()
  end

  vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP breakpoint" })
  vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue" })
  vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
  vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
  vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
  vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "DAP UI" })
end

return M
