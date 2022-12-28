local M = {}

M.defaults = {
  url = "https://localhost:10240",
  auto_scroll = "both", -- (none, both, source, asm)
  open_qflist = true,
  infer_lang = true, -- Try to infer possible language based on file extension.
  binary_hl = "Comment",
  autocmd = {
    enable = true,
    hl = "Cursor",
  },
  diagnostics = { -- vim.diagnostic.config() options for the ce-diagnostics namespace.
    underline = false,
    virtual_text = false,
    signs = false,
  },
  split = "vsplit", -- How to split the window after compile (split/vsplit).
  spinner_frames = { "⣼", "⣹", "⢻", "⠿", "⡟", "⣏", "⣧", "⣶" },
  spinner_interval = 100,
  compiler_flags = "",
  use_compile_commands = true,
  compile_commands_folder = "build",
  job_timeout = 25000, -- Timeout for libuv job in milliseconds.
}

M._config = M.defaults

function M.setup(user_config)
  M._config = vim.tbl_deep_extend("force", M._config, user_config)
end

function M.get_config()
  return M._config
end

return M
