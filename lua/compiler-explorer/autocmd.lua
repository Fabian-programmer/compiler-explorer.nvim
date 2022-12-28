local config = require("compiler-explorer.config")

local api, fn = vim.api, vim.fn

local M = {}

local function highlight_line(bufnr, linenr, ns, higroup)
  vim.api.nvim_buf_add_highlight(bufnr, ns, higroup, linenr, 0, -1)
end

local function create_linehl_dict(asm, offset)
  local source_to_asm, asm_to_source = {}, {}
  for asm_idx, line_obj in ipairs(asm) do
    if line_obj.source == vim.NIL then
      -- continue
    else
      local isLineInBuffer = line_obj.source.file == vim.NIL
      if line_obj.source.line ~= vim.NIL and isLineInBuffer then

      local source_idx = line_obj.source.line + offset
      if source_to_asm[source_idx] == nil then
        source_to_asm[source_idx] = {}
      end

      table.insert(source_to_asm[source_idx], asm_idx)
      asm_to_source[asm_idx] = source_idx
      end
    end
  end

  return source_to_asm, asm_to_source
end

local function get_median(list)
  local len = #list

  -- if the length is odd, return the middle element
  if len % 2 == 1 then
    return list[(len + 1) / 2]
  end

  -- if the length is even, return the neighbour of the middle element
  return list[len / 2]
end

local function center_line(winid, line)
    local current_windid = vim.api.nvim_get_current_win()

    vim.api.nvim_set_current_win(winid)
    vim.api.nvim_win_set_cursor(winid, {line, 0})
    vim.cmd('norm! zz')
    vim.api.nvim_set_current_win(current_windid)
end

M.create_autocmd = function(source_bufnr, asm_bufnr, resp, offset)
  local source_to_asm, asm_to_source = create_linehl_dict(resp, offset)
  if vim.tbl_isempty(source_to_asm) or vim.tbl_isempty(asm_to_source) then
    return
  end

  local conf = config.get_config()
  local hl_group = conf.autocmd.hl
  local gid = api.nvim_create_augroup("CompilerExplorer" .. asm_bufnr, { clear = true })
  local ns = api.nvim_create_namespace("ce-autocmds")

  -- asm buffer
  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      if fn.bufloaded(asm_bufnr) == 0 then
        api.nvim_clear_autocmds({ group = gid })
        api.nvim_del_augroup_by_id(gid)
        return
      end
      api.nvim_buf_clear_namespace(asm_bufnr, ns, 0, -1)

      local line_nr = fn.line(".")
      local hl_list = source_to_asm[line_nr]
      if hl_list then
        for _, hl in ipairs(hl_list) do
          highlight_line(asm_bufnr, hl - 1, ns, hl_group)
        end
      end

      if conf.auto_scroll == "both" or conf.auto_scroll == "asm" then
        local winid = fn.bufwinid(asm_bufnr)
        if winid ~= -1 and hl_list ~= nil then
          center_line(winid, get_median(hl_list))
        end
      end
    end,
  })

  -- source buffer
  api.nvim_create_autocmd({ "CursorMoved" }, {
    group = gid,
    buffer = asm_bufnr,
    callback = function()
      if not fn.bufloaded(source_bufnr) == 0 then
        api.nvim_clear_autocmds({ group = gid })
        api.nvim_del_augroup_by_id(gid)
        return
      end
      api.nvim_buf_clear_namespace(source_bufnr, ns, 0, -1)

      local line_nr = fn.line(".")
      local hl = asm_to_source[line_nr]

      if hl == nil or hl-1 == nil then
        return
      end

      highlight_line(source_bufnr, hl - 1, ns, hl_group)

      if conf.auto_scroll == "both" or conf.auto_scroll == "source" then
        local winid = fn.bufwinid(source_bufnr)
        if winid ~= -1 then
          center_line(winid, hl)
        end
      end
    end,
  })

  api.nvim_create_autocmd({ "BufLeave" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      pcall(api.nvim_buf_clear_namespace, asm_bufnr, ns, 0, -1)
    end,
  })

  api.nvim_create_autocmd({ "BufLeave" }, {
    group = gid,
    buffer = asm_bufnr,
    callback = function()
      pcall(api.nvim_buf_clear_namespace, source_bufnr, ns, 0, -1)
    end,
  })

  api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "TextChangedP" }, {
    group = gid,
    buffer = source_bufnr,
    callback = function()
      api.nvim_buf_clear_namespace(source_bufnr, ns, 0, -1)
      api.nvim_buf_clear_namespace(asm_bufnr, ns, 0, -1)
      api.nvim_clear_autocmds({ group = gid })
    end,
  })
end

return M
