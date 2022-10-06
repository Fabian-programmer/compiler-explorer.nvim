local alert = require("compiler-explorer.alert")
local config = require("compiler-explorer.config")

local api, fn = vim.api, vim.fn
local json = vim.json

local M = {}

local cache = {
  in_memory = {},
  filename = fn.stdpath("cache") .. "/compiler-explorer-cache.json",
  loaded_from_file = false,
}

setmetatable(cache, {
  __index = function(t, key)
    local value = rawget(t.in_memory, key)
    if value ~= nil then
      return value
    else
      if t.loaded_from_file then
        return nil
      end

      api.nvim_create_autocmd({ "VimLeavePre" }, {
        group = api.nvim_create_augroup("ce-cache", { clear = true }),
        callback = function()
          local file = io.open(cache.filename, "w+")
          file:write(json.encode(t.in_memory))
          file:close()
        end,
      })

      local ok, file = pcall(io.open, cache.filename, "r")
      if not ok or not file then
        return nil
      end
      local data = file:read("*a")
      file:close()
      t.in_memory = json.decode(data)
      t.loaded_from_file = true
      return rawget(t.in_memory, key)
    end
  end,
  __newindex = function(t, key, value)
    rawset(t.in_memory, key, value)
  end,
})

M.get_compilers = function(extension)
  local conf = config.get_config()
  local compilers_endpoint = table.concat({ conf.url, "api", "compilers" }, "/")
  local languages_endpoint = table.concat({ conf.url, "api", "languages" }, "/")

  local compilers = cache[compilers_endpoint] or {}
  if extension == nil then
    return compilers
  end

  local langs = cache[languages_endpoint] or {}
  local filtered_langs = vim.tbl_filter(function(l)
    return vim.tbl_contains(l.extensions, extension)
  end, langs)
  local filtered_ids = vim.tbl_map(function(l)
    return l.id
  end, filtered_langs)
  return vim.tbl_filter(function(c)
    return vim.tbl_contains(filtered_ids, c.lang)
  end, compilers)
end

M.delete_cache = function()
  cache.in_memory = {}
  os.remove(fn.stdpath("cache") .. "/compiler-explorer-cache.json")
  alert.info("Cache file has been deleted.")
end

M.get = function()
  return cache
end
return M
