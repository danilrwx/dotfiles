-- Per-directory sessions on top of :mksession. A session file is named after
-- its cwd (slashes encoded as %), so each project restores where you left off.
local M = {}

M.dir = vim.fs.joinpath(vim.fn.stdpath("state"), "sessions")
vim.fn.mkdir(M.dir, "p")

local function file_for(cwd)
  cwd = cwd or vim.fn.getcwd()
  return vim.fs.joinpath(M.dir, cwd:gsub("/", "%%") .. ".vim")
end

local function cwd_of(name)
  return (name:gsub("%.vim$", ""):gsub("%%", "/"))
end

-- true if there's at least one real, named file buffer worth saving
local function has_content()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[b].buflisted and vim.bo[b].buftype == "" and vim.api.nvim_buf_get_name(b) ~= "" then
      return true
    end
  end

  return false
end

function M.save(cwd)
  if not has_content() then
    return
  end
  vim.cmd("mksession! " .. vim.fn.fnameescape(file_for(cwd)))
end

function M.restore(cwd)
  local f = file_for(cwd)
  if vim.fn.filereadable(f) == 0 then
    return false
  end
  vim.cmd("silent! source " .. vim.fn.fnameescape(f))
  return true
end

function M.delete(cwd)
  vim.fn.delete(file_for(cwd))
end

-- cwds that have a saved session, most recently modified first
function M.list()
  local files = {}
  for name, t in vim.fs.dir(M.dir) do
    if t == "file" and name:match("%.vim$") then
      local p = vim.fs.joinpath(M.dir, name)
      files[#files + 1] = { cwd = cwd_of(name), mtime = vim.fn.getftime(p) }
    end
  end

  table.sort(files, function(a, b)
    return a.mtime > b.mtime
  end)

  local out = {}
  for _, f in ipairs(files) do
    out[#out + 1] = f.cwd
  end
  return out
end

return M
