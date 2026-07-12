-- oil-mini: edit a directory as a buffer. :w applies renames/creates/copies/
-- deletes, subpaths included (mkdir -p). <CR> opens the entry, - goes up.
-- Each line is `name<TAB><id>` with the <TAB><id> concealed at the end, so the
-- name sits at column 1 and edits normally. A session-global registry maps id to
-- absolute path. Rules: an entry of THIS dir with a changed name is a rename
-- (a name like ../x or sub/x moves it); a duplicated line is a copy; a line whose
-- id belongs to ANOTHER dir (pasted in) is a copy in; a line with no id is a new
-- file; an id gone from its dir is a deletion. All confirmed. `cp` for copies.

local registry = {} -- id -> absolute path
local revreg = {} -- absolute path -> id (reused across renders)
local seq = 0
local ns = vim.api.nvim_create_namespace("oil_mini")
local bufdir = {} -- bufnr -> dir
local bufreg = {} -- bufnr -> { id -> disp }

vim.api.nvim_set_hl(0, "OilDir", { link = "Directory", default = true })
vim.api.nvim_set_hl(0, "OilLinkTarget", { link = "Comment", default = true })
vim.api.nvim_set_hl(0, "OilLink", { fg = "#00afaf", ctermfg = 6, default = true })
vim.api.nvim_set_hl(0, "OilExec", { fg = "#5faf5f", ctermfg = 2, default = true })

local M = {}

local function id_for(full)
  if not revreg[full] then
    seq = seq + 1
    revreg[full] = tostring(seq)
    registry[revreg[full]] = full
  end
  return revreg[full]
end

-- -> { name, id } for an entry line, nil for a create line
local function parse(l)
  local m = vim.fn.matchlist(l, [[^\(.*\)\t\(\d\+\)$]])
  if #m > 0 and registry[m[3]] then
    return { m[2], m[3] }
  end
  return nil
end

local function rel(dir, p)
  return (p:sub(1, #dir) == dir) and p:sub(#dir + 1) or p
end

local function mkparent(p)
  local d = vim.fn.fnamemodify(p, ":h")
  if vim.fn.isdirectory(d) == 0 then
    vim.fn.mkdir(d, "p")
  end
end

local function copy_path(src, dst)
  vim.fn.system("cp -Rp -- " .. vim.fn.shellescape(src) .. " " .. vim.fn.shellescape(dst))
  return vim.v.shell_error
end

local function render(buf)
  local dir = bufdir[buf]
  bufreg[buf] = {}
  local names = vim.fn.readdir(dir)
  local isdir = {}
  for _, name in ipairs(names) do
    isdir[name] = vim.fn.isdirectory(dir .. name) == 1
  end
  -- directories first, then by name -- like oil.nvim's default
  table.sort(names, function(a, b)
    if isdir[a] == isdir[b] then
      return a < b
    end
    return isdir[a]
  end)

  local lines = {}
  local metas = {} -- { display byte-length, hl group ('' none), link target ('' none) }
  for _, name in ipairs(names) do
    local full = vim.fn.simplify(dir .. name)
    local id = id_for(full)
    local disp = name .. (isdir[name] and "/" or "")
    bufreg[buf][id] = disp
    lines[#lines + 1] = disp .. "\t" .. id
    local islink = vim.fn.getftype(full) == "link"
    local hl = islink and "OilLink" or (isdir[name] and "OilDir" or (vim.fn.executable(full) == 1 and "OilExec" or ""))
    local target = islink and rel(dir, vim.fn.resolve(full)) or ""
    metas[#metas + 1] = { vim.fn.strlen(disp), hl, target }
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for i, meta in ipairs(metas) do
    if meta[2] ~= "" then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = meta[1], hl_group = meta[2] })
    end
    if meta[3] ~= "" then
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, meta[1], {
        virt_text = { { " →  " .. meta[3], "OilLinkTarget" } },
        virt_text_pos = "inline",
      })
    end
  end
  vim.bo[buf].modified = false
end

local function confirm(summary)
  return vim.fn.confirm("Apply changes?\n\n" .. table.concat(summary, "\n"), "&Yes\n&No", 2) == 1
end

local function apply(buf)
  local dir = bufdir[buf]
  local reg = bufreg[buf]
  local byid = {} -- id -> list of names
  local creates = {}
  for _, l in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if l:match("%S") then
      local p = parse(l)
      if not p then
        creates[#creates + 1] = (l:gsub("\t%d+$", ""))
      else
        byid[p[2]] = byid[p[2]] or {}
        table.insert(byid[p[2]], p[1])
      end
    end
  end

  local renames = {}
  local copies = {}
  for id, names in pairs(byid) do
    local src = registry[id]
    local targets = {}
    for _, nm in ipairs(names) do
      targets[#targets + 1] = vim.fn.simplify(dir .. vim.fn.trim(nm, "/", 2))
    end
    if not reg[id] then
      -- pasted from another dir -> copy in, never touch the foreign source
      for _, t in ipairs(targets) do
        copies[#copies + 1] = { src, t }
      end
    elseif vim.tbl_contains(targets, src) then
      for _, t in ipairs(targets) do
        if t ~= src then
          copies[#copies + 1] = { src, t }
        end
      end
    else
      renames[#renames + 1] = { src, targets[1] }
      for i = 2, #targets do
        copies[#copies + 1] = { src, targets[i] }
      end
    end
  end

  local deletes = {}
  for id in pairs(reg) do
    if not byid[id] then
      deletes[#deletes + 1] = registry[id]
    end
  end

  if #renames == 0 and #copies == 0 and #creates == 0 and #deletes == 0 then
    return true
  end

  local summary = {}
  for _, rc in ipairs(renames) do
    summary[#summary + 1] = ("rename  %s → %s"):format(rel(dir, rc[1]), rel(dir, rc[2]))
  end
  for _, rc in ipairs(copies) do
    summary[#summary + 1] = ("copy    %s → %s"):format(rel(dir, rc[1]), rel(dir, rc[2]))
  end
  for _, name in ipairs(creates) do
    summary[#summary + 1] = "create  " .. name
  end
  for _, full in ipairs(deletes) do
    summary[#summary + 1] = "delete  " .. rel(dir, full)
  end
  if not confirm(summary) then
    return false
  end

  local errors = {}

  -- deletes run FIRST: a delete target never overlaps a rename source (its id is
  -- gone), so doing them before copies/renames stops a rename/copy from
  -- overwriting a file that is then deleted (swap, "delete A + rename B→A", …).
  for _, full in ipairs(deletes) do
    if vim.fn.delete(full, vim.fn.isdirectory(full) == 1 and "rf" or "") ~= 0 then
      errors[#errors + 1] = "delete failed: " .. rel(dir, full)
    end
  end

  local tcount = {}
  for _, rc in ipairs(renames) do
    tcount[rc[2]] = (tcount[rc[2]] or 0) + 1
  end
  for _, rc in ipairs(copies) do
    tcount[rc[2]] = (tcount[rc[2]] or 0) + 1
  end

  for _, rc in ipairs(copies) do
    local src, dst = rc[1], rc[2]
    if tcount[dst] > 1 then
      errors[#errors + 1] = "copy skipped, name used twice: " .. rel(dir, dst)
    elseif vim.fn.filereadable(dst) == 1 or vim.fn.isdirectory(dst) == 1 then
      errors[#errors + 1] = "copy skipped, exists: " .. rel(dir, dst)
    else
      mkparent(dst)
      if copy_path(src, dst) ~= 0 then
        errors[#errors + 1] = ("copy failed: %s → %s"):format(rel(dir, src), rel(dir, dst))
      end
    end
  end

  -- renames in two phases via temp names so swaps/cycles and cross-dir moves work
  local vacated = {}
  for _, rc in ipairs(renames) do
    vacated[rc[1]] = true
  end
  for _, full in ipairs(deletes) do
    vacated[full] = true
  end
  local pending = {}
  local ti = 0
  for _, rc in ipairs(renames) do
    local src, dst = rc[1], rc[2]
    if tcount[dst] > 1 then
      errors[#errors + 1] = "rename skipped, name used twice: " .. rel(dir, dst)
    elseif (vim.fn.filereadable(dst) == 1 or vim.fn.isdirectory(dst) == 1) and not vacated[dst] then
      errors[#errors + 1] = "rename skipped, exists: " .. rel(dir, dst)
    else
      ti = ti + 1
      -- ponytail: temp is .oil-tmp-N in dir; a real file of that name would clash.
      local tmp = vim.fn.simplify(dir .. (".oil-tmp-%d"):format(ti))
      if vim.fn.rename(src, tmp) ~= 0 then
        errors[#errors + 1] = ("rename failed: %s → %s"):format(rel(dir, src), rel(dir, dst))
      else
        pending[#pending + 1] = { tmp, dst }
      end
    end
  end
  for _, td in ipairs(pending) do
    mkparent(td[2])
    if vim.fn.rename(td[1], td[2]) ~= 0 then
      errors[#errors + 1] = "rename failed → " .. rel(dir, td[2])
    end
  end

  for _, name in ipairs(creates) do
    local dst = vim.fn.simplify(dir .. name)
    if vim.fn.filereadable(dst) == 0 and vim.fn.isdirectory(dst) == 0 then
      local ok = pcall(function()
        mkparent(dst)
        if name:match("/$") then
          vim.fn.mkdir(dst, "p")
        else
          vim.fn.writefile({}, dst)
        end
      end)
      if not ok then
        errors[#errors + 1] = "create failed: " .. name
      end
    end
  end

  if #errors > 0 then
    for _, e in ipairs(errors) do
      vim.api.nvim_echo({ { "oil: " .. e, "WarningMsg" } }, true, {})
    end
  end
  return true
end

local function enter()
  local p = parse(vim.api.nvim_get_current_line())
  if not p then
    return
  end
  vim.bo.modified = false
  local full = registry[p[2]]
  if vim.fn.isdirectory(full) == 1 then
    M.open(full .. "/")
  else
    vim.cmd("edit " .. vim.fn.fnameescape(full))
  end
end

local function up()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo.modified = false
  M.open(vim.fn.fnamemodify(vim.fn.trim(bufdir[buf], "/", 2), ":h") .. "/")
end

local function focus(name)
  if name == "" then
    return
  end
  for lnum = 1, vim.fn.line("$") do
    local p = parse(vim.fn.getline(lnum))
    if p and (p[1] == name or p[1] == name .. "/") then
      vim.api.nvim_win_set_cursor(0, { lnum, 0 })
      return
    end
  end
end

-- cc/S would wipe the hidden id suffix (turning a rename into delete+create);
-- keep the suffix and clear only the name so the edit stays a rename.
local function rename_line()
  local m = vim.fn.matchlist(vim.api.nvim_get_current_line(), [[\t\(\d\+\)$]])
  vim.api.nvim_set_current_line(#m > 0 and ("\t" .. m[2]) or "")
  vim.api.nvim_win_set_cursor(0, { vim.fn.line("."), 0 })
  vim.cmd("startinsert")
end

function M.open(path)
  path = path or ""
  local d = vim.fn.fnamemodify(path == "" and vim.fn.expand("%:p:h") or path, ":p")
  if vim.fn.isdirectory(d) == 0 then
    return
  end
  local prev = vim.api.nvim_get_current_buf()
  local leaving = bufdir[prev] and vim.fn.fnamemodify(vim.fn.trim(bufdir[prev], "/", 2), ":t") or vim.fn.expand("%:t")
  -- 'oil:' not 'oil://' -- a :// name is hijacked by netrw's URL handler
  vim.cmd("silent edit " .. vim.fn.fnameescape("oil:" .. d))
  local buf = vim.api.nvim_get_current_buf()
  bufdir[buf] = d
  vim.bo[buf].buftype = "acwrite"
  vim.bo[buf].swapfile = false
  vim.bo[buf].bufhidden = "wipe"
  vim.wo.conceallevel = 3
  vim.wo.concealcursor = "nvic"
  vim.cmd("syntax clear")
  vim.cmd([[syntax match oilId '\t\d\+$' conceal]])
  local function bmap(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, silent = true })
  end
  bmap("<CR>", enter)
  bmap("-", up)
  bmap("cc", rename_line)
  bmap("S", rename_line)
  vim.api.nvim_create_autocmd("BufWriteCmd", {
    buffer = buf,
    callback = function()
      if apply(buf) then
        render(buf)
      end
    end,
  })
  render(buf)
  focus(leaving)
end

vim.api.nvim_create_user_command("Oil", function(o)
  M.open(o.args)
end, { nargs = "?", complete = "dir" })
