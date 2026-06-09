local M = {}

function M.project_root()
  local markers = {
    ".git",
    "pom.xml",
    "mvnw",
    "package.json",
    "tsconfig.json",
    "jsconfig.json",
  }
  local found = vim.fs.find(markers, { upward = true, path = vim.api.nvim_buf_get_name(0) })
  if found[1] then
    return vim.fs.dirname(found[1])
  end
  return vim.loop.cwd()
end

function M.maven_cmd()
  local root = M.project_root()
  if vim.fn.executable(root .. "/mvnw") == 1 then
    return "./mvnw", root
  end
  return "mvn", root
end

function M.open_terminal(cmd, opts)
  opts = opts or {}
  local direction = opts.direction or "botright"
  local size = opts.size or 15
  local cwd = opts.cwd or M.project_root()

  vim.cmd(direction .. " " .. size .. "split")
  vim.cmd("lcd " .. vim.fn.fnameescape(cwd))
  vim.cmd("terminal " .. cmd)
  vim.cmd("startinsert")
end

return M
