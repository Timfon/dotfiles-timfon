local log = require('plenary.log')
local M = {}

--- Create class
---@param fn function The class constructor
---@param parent table? The parent class
---@return table
function M.class(fn, parent)
  local out = {}
  out.__index = out

  local mt = {
    __call = function(cls, ...)
      return cls.new(...)
    end,
  }

  if parent then
    mt.__index = parent
  end

  setmetatable(out, mt)

  function out.new(...)
    local self = setmetatable({}, out)
    fn(self, ...)
    return self
  end

  return out
end

--- Get the log file path
---@return string
function M.get_log_file_path()
  return log.logfile
end

--- Check if the current version of neovim is stable
---@return boolean
function M.is_stable()
  return vim.fn.has('nvim-0.10.0') == 0
end

--- Join multiple async functions
---@param on_done function The function to call when all the async functions are done
---@param fns table The async functions
function M.join(on_done, fns)
  local count = #fns
  local results = {}
  local function done()
    count = count - 1
    if count == 0 then
      on_done(results)
    end
  end
  for i, fn in ipairs(fns) do
    fn(function(result)
      results[i] = result
      done()
    end)
  end
end

--- Writes text to a temporary file and returns path
---@param text string The text to write
---@return string?
function M.temp_file(text)
  local temp_file = os.tmpname()
  local f = io.open(temp_file, 'w+')
  if f == nil then
    error('Could not open file: ' .. temp_file)
  end
  f:write(text)
  f:close()
  return temp_file
end

--- Check if a table is equal to another table
---@param a table The first table
---@param b table The second table
---@return boolean
function M.table_equals(a, b)
  if type(a) ~= type(b) then
    return false
  end
  if type(a) ~= 'table' then
    return a == b
  end
  for k, v in pairs(a) do
    if not M.table_equals(v, b[k]) then
      return false
    end
  end
  for k, v in pairs(b) do
    if not M.table_equals(v, a[k]) then
      return false
    end
  end
  return true
end

--- Exit visual mode if we are in it
function M.exit_visual_mode()
  if vim.fn.mode():lower():find('v') then
    -- NOTE: vim.cmd('normal! v') does not work properly when executed from keymap
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<esc>', true, false, true), 'x', false)
  end
end

return M