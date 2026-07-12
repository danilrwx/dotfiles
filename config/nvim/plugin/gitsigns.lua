-- Native git signs, buffer-based & async (gitgutter-style): diff the live buffer
-- against the git index via `git diff --no-index` in a job, so signs stay correct
-- even before saving. ]c/[c jump hunks; ghp preview; ghs/ghS stage hunk/buffer;
-- ghu/ghU undo hunk / reset buffer to index; ghd/ghD diff vs index/HEAD; ih is a
-- hunk text object. Depends on git + bash.

-- re-set on ColorScheme too: a :colorscheme clears these back to cleared/linked
-- and the signs would lose their colour.
local function set_hl()
  vim.api.nvim_set_hl(0, "GitSignAdd", { fg = "#00af5f", ctermfg = "green", default = true })
  vim.api.nvim_set_hl(0, "GitSignChange", { fg = "#d7af00", ctermfg = "yellow", default = true })
  vim.api.nvim_set_hl(0, "GitSignDelete", { fg = "#d70000", ctermfg = "red", default = true })
end
set_hl()
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("gitsigns_hl", { clear = true }),
  callback = set_hl,
})

vim.fn.sign_define("GitAdd", { text = "+", texthl = "GitSignAdd", numhl = "GitSignAdd" })
vim.fn.sign_define("GitChange", { text = "~", texthl = "GitSignChange", numhl = "GitSignChange" })
vim.fn.sign_define("GitDelete", { text = "-", texthl = "GitSignDelete", numhl = "GitSignDelete" })

local GROUP = "gitsigns"
-- only diff tracked files: outside a repo (or for an untracked file) git show is
-- empty and --no-index would mark every line added -- so bail unless tracked.
local DIFF = 'git -C "$0" ls-files --error-unmatch -- "$1" >/dev/null 2>&1 || exit 0; '
  .. 'git -C "$0" diff --no-color -U0 --no-index -- <(git -C "$0" show ":./$1" 2>/dev/null) "$2" 2>/dev/null || true'

local hunks = {}
local running = {}
local last_tick = {} -- buf -> changedtick last diffed, to skip idle CursorHold runs

local function place(buf, lines, tmp)
  os.remove(tmp)
  if vim.fn.bufexists(buf) == 0 then
    return
  end

  vim.fn.sign_unplace(GROUP, { buffer = buf })

  local hs = {}
  local cur = nil
  for _, line in ipairs(lines) do
    local m = vim.fn.matchlist(line, [[^@@ -\(\d\+\),\=\(\d*\) +\(\d\+\),\=\(\d*\) @@]])
    if #m > 0 then
      if cur then
        hs[#hs + 1] = cur
      end

      local new_start = tonumber(m[4])
      local new_cnt = (m[5] == "") and 1 or tonumber(m[5])
      cur = {
        new_start = new_start,
        new_cnt = new_cnt,
        old_start = tonumber(m[2]),
        old_cnt = (m[3] == "") and 1 or tonumber(m[3]),
        lnum = (new_cnt == 0) and math.max(1, new_start) or new_start,
        old_lines = {},
        new_lines = {},
      }
    elseif cur then
      local c = line:sub(1, 1)
      if c == "-" then
        cur.old_lines[#cur.old_lines + 1] = line:sub(2)
      elseif c == "+" then
        cur.new_lines[#cur.new_lines + 1] = line:sub(2)
      end
    end
  end
  if cur then
    hs[#hs + 1] = cur
  end

  for _, h in ipairs(hs) do
    if h.new_cnt == 0 then
      vim.fn.sign_place(0, GROUP, "GitDelete", buf, { lnum = h.lnum, priority = 10 })
    else
      local name = (h.old_cnt == 0) and "GitAdd" or "GitChange"
      for l = h.new_start, h.new_start + h.new_cnt - 1 do
        vim.fn.sign_place(0, GROUP, name, buf, { lnum = l, priority = 10 })
      end
    end
  end

  hunks[buf] = hs
end

local function refresh(force)
  local path = vim.fn.expand("%:p")
  if vim.bo.buftype ~= "" or vim.fn.filereadable(path) == 0 then
    return
  end
  -- git stores a symlink as its target path, but nvim edits the followed file's
  -- content — diffing the two marks every line changed. Skip symlinks entirely.
  if require("git").is_symlink(path) then
    vim.fn.sign_unplace(GROUP, { buffer = vim.fn.bufnr("%") })
    return
  end
  local buf = vim.fn.bufnr("%")
  if running[buf] then
    return
  end
  -- CursorHold fires repeatedly with no edit; skip the tempfile+git diff unless
  -- the buffer actually changed. force=true for explicit sync points (read/write,
  -- stage/undo) where the index may have moved without a buffer edit.
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if not force and last_tick[buf] == tick then
    return
  end
  last_tick[buf] = tick

  local dir = vim.fn.expand("%:p:h")
  local name = vim.fn.expand("%:t")
  local tmp = vim.fn.tempname()
  vim.fn.writefile(vim.fn.getline(1, "$"), tmp)

  running[buf] = true
  vim.system({ "bash", "-c", DIFF, dir, name, tmp }, { text = true }, function(res)
    running[buf] = false
    local out = vim.split(res.stdout or "", "\n")
    vim.schedule(function()
      place(buf, out, tmp)
    end)
  end)
end

local function hunk_at(cur)
  for _, h in ipairs(hunks[vim.fn.bufnr("%")] or {}) do
    if h.new_cnt == 0 and cur == h.lnum then
      return h
    elseif h.new_cnt ~= 0 and cur >= h.new_start and cur < h.new_start + h.new_cnt then
      return h
    end
  end
  return nil
end

local function next_hunk()
  if vim.wo.diff then
    vim.cmd("normal! ]c")
    return
  end
  local hs = hunks[vim.fn.bufnr("%")] or {}
  if #hs == 0 then
    return
  end
  local cur = vim.fn.line(".")
  for _, h in ipairs(hs) do
    if h.lnum > cur then
      vim.api.nvim_win_set_cursor(0, { h.lnum, 0 })
      return
    end
  end
  vim.api.nvim_win_set_cursor(0, { hs[1].lnum, 0 })
end

local function prev_hunk()
  if vim.wo.diff then
    vim.cmd("normal! [c")
    return
  end
  local hs = hunks[vim.fn.bufnr("%")] or {}
  if #hs == 0 then
    return
  end
  local cur = vim.fn.line(".")
  for i = #hs, 1, -1 do
    if hs[i].lnum < cur then
      vim.api.nvim_win_set_cursor(0, { hs[i].lnum, 0 })
      return
    end
  end
  vim.api.nvim_win_set_cursor(0, { hs[#hs].lnum, 0 })
end

local function preview_hunk()
  local h = hunk_at(vim.fn.line("."))
  if not h then
    return
  end
  local lines = {}
  for _, l in ipairs(h.old_lines) do
    lines[#lines + 1] = "-" .. l
  end
  for _, l in ipairs(h.new_lines) do
    lines[#lines + 1] = "+" .. l
  end
  if #lines == 0 then
    return
  end
  vim.lsp.util.open_floating_preview(lines, "diff", { border = "single", focusable = false })
end

local function undo_hunk()
  local h = hunk_at(vim.fn.line("."))
  if not h then
    return
  end
  if h.new_cnt > 0 then
    vim.fn.deletebufline("%", h.new_start, h.new_start + h.new_cnt - 1)
  end
  if #h.old_lines > 0 then
    vim.fn.appendbufline("%", h.new_cnt > 0 and h.new_start - 1 or h.new_start, h.old_lines)
  end

  vim.api.nvim_win_set_cursor(0, { h.lnum, 0 })
  refresh(true)
end

-- repo-root-relative path of the current file, "" if not tracked
local function rel_path(dir, name)
  return vim.trim(vim.system({ "git", "-C", dir, "ls-files", "--full-name", "--", name },
    { text = true }):wait().stdout or "")
end

-- minimal unidiff-zero patch staging the given hunks (index → buffer)
local function patch_of(rel, hs)
  local p = {
    "diff --git a/" .. rel .. " b/" .. rel,
    "--- a/" .. rel,
    "+++ b/" .. rel,
  }
  for _, h in ipairs(hs) do
    p[#p + 1] = string.format("@@ -%d,%d +%d,%d @@", h.old_start, #h.old_lines, h.new_start, #h.new_lines)
    for _, l in ipairs(h.old_lines) do
      p[#p + 1] = "-" .. l
    end
    for _, l in ipairs(h.new_lines) do
      p[#p + 1] = "+" .. l
    end
  end
  p[#p + 1] = ""
  return table.concat(p, "\n")
end

-- `git apply --cached` the patch for hs, then refresh signs
local function stage(hs, what)
  local dir, name = vim.fn.expand("%:p:h"), vim.fn.expand("%:t")
  local rel = rel_path(dir, name)
  if rel == "" then
    vim.notify("gitsigns: file not tracked")
    return
  end
  vim.system({ "git", "-C", dir, "apply", "--cached", "--unidiff-zero", "-" },
    { stdin = patch_of(rel, hs) }, function(r)
      vim.schedule(function()
        if r.code ~= 0 then
          vim.notify("gitsigns: stage failed\n" .. (r.stderr or ""))
        else
          vim.notify("gitsigns: " .. what .. " staged")
        end
        refresh(true)
      end)
    end)
end

local function stage_hunk()
  local h = hunk_at(vim.fn.line("."))
  if not h then
    return
  end
  stage({ h }, "hunk")
end

local function stage_buffer()
  local hs = hunks[vim.fn.bufnr("%")] or {}
  if #hs == 0 then
    vim.notify("gitsigns: no changes")
    return
  end
  stage(hs, #hs .. (#hs == 1 and " hunk" or " hunks"))
end

-- reset the whole buffer to its index (staged) content, dropping working changes
local function reset_buffer()
  local dir, name = vim.fn.expand("%:p:h"), vim.fn.expand("%:t")
  if rel_path(dir, name) == "" then
    vim.notify("gitsigns: file not tracked")
    return
  end
  local r = vim.system({ "git", "-C", dir, "show", ":./" .. name }, { text = true }):wait()
  if r.code ~= 0 then
    vim.notify("gitsigns: no index version")
    return
  end
  local content = vim.split(r.stdout or "", "\n")
  if content[#content] == "" then
    table.remove(content) -- git show ends with a trailing newline
  end

  vim.api.nvim_buf_set_lines(0, 0, -1, false, content)
  refresh(true)
end

-- select the hunk under the cursor linewise (text object: dih, yih, Vih, …)
local function select_hunk()
  local h = hunk_at(vim.fn.line("."))
  if not h then
    return
  end
  local s = (h.new_cnt == 0) and h.lnum or h.new_start
  local e = (h.new_cnt == 0) and h.lnum or (h.new_start + h.new_cnt - 1)
  vim.cmd(("normal! %dGV%dG"):format(s, e))
end

-- open the index (ref="") or HEAD version in a diff split beside the file
local function diff_against(ref, label)
  local dir, name = vim.fn.expand("%:p:h"), vim.fn.expand("%:t")
  if rel_path(dir, name) == "" then
    vim.notify("gitsigns: file not tracked")
    return
  end
  local r = vim.system({ "git", "-C", dir, "show", ref .. ":./" .. name }, { text = true }):wait()
  if r.code ~= 0 then
    vim.notify("gitsigns: no " .. label .. " version")
    return
  end
  local content = vim.split(r.stdout or "", "\n")
  if content[#content] == "" then
    table.remove(content)
  end

  local ft = vim.bo.filetype
  vim.cmd("diffthis")
  vim.cmd("leftabove vnew")

  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, content)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = ft
  pcall(vim.api.nvim_buf_set_name, buf, name .. " (" .. label .. ")")
  vim.cmd("diffthis")

  vim.keymap.set("n", "q", "<cmd>diffoff!<bar>close<cr>", { buffer = buf, silent = true })
end

vim.keymap.set("n", "]c", next_hunk, { silent = true })
vim.keymap.set("n", "[c", prev_hunk, { silent = true })

vim.keymap.set("n", "ghp", preview_hunk, { silent = true })
vim.keymap.set("n", "ghs", stage_hunk, { silent = true })
vim.keymap.set("n", "ghS", stage_buffer, { silent = true })
vim.keymap.set("n", "ghu", undo_hunk, { silent = true })
vim.keymap.set("n", "ghU", reset_buffer, { silent = true })
vim.keymap.set("n", "ghd", function() diff_against("", "index") end, { silent = true })
vim.keymap.set("n", "ghD", function() diff_against("HEAD", "HEAD") end, { silent = true })

vim.keymap.set({ "o", "x" }, "ih", select_hunk, { silent = true })

local grp = vim.api.nvim_create_augroup("gitsigns", { clear = true })

-- explicit sync points force a diff (index may have changed without a buffer edit)
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  group = grp,
  callback = function()
    refresh(true)
  end,
})

-- idle/edit events are guarded by changedtick inside refresh
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "TextChanged", "InsertLeave" }, {
  group = grp,
  callback = function()
    refresh()
  end,
})

-- drop per-buffer state on wipe so the tables don't grow across a long session
vim.api.nvim_create_autocmd("BufWipeout", {
  group = grp,
  callback = function(a)
    hunks[a.buf], running[a.buf], last_tick[a.buf] = nil, nil, nil
  end,
})
