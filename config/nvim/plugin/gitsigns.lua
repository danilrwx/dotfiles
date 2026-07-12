-- Native git signs, buffer-based & async (gitgutter-style): diff the live buffer
-- against the git index via `git diff --no-index` in a job, so signs stay correct
-- even before saving. ]c/[c jump between hunks, ghp previews, ghu reverts.
-- Depends on git + bash.

vim.api.nvim_set_hl(0, "GitSignAdd", { fg = "#00af5f", ctermfg = "green", default = true })
vim.api.nvim_set_hl(0, "GitSignChange", { fg = "#d7af00", ctermfg = "yellow", default = true })
vim.api.nvim_set_hl(0, "GitSignDelete", { fg = "#d70000", ctermfg = "red", default = true })

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
  vim.fn.delete(tmp)
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
  local st = vim.uv.fs_lstat(path)
  if st and st.type == "link" then
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

-- stage the hunk under the cursor: build a minimal unified-diff patch (index →
-- buffer for just this hunk) and `git apply --cached --unidiff-zero`.
local function stage_hunk()
  local h = hunk_at(vim.fn.line("."))
  if not h then
    return
  end
  local dir = vim.fn.expand("%:p:h")
  local name = vim.fn.expand("%:t")
  local rel = vim.trim(vim.system({ "git", "-C", dir, "ls-files", "--full-name", "--", name }, { text = true }):wait().stdout or "")
  if rel == "" then
    vim.notify("gitsigns: file not tracked")
    return
  end
  local patch = {
    "diff --git a/" .. rel .. " b/" .. rel,
    "--- a/" .. rel,
    "+++ b/" .. rel,
    string.format("@@ -%d,%d +%d,%d @@", h.old_start, #h.old_lines, h.new_start, #h.new_lines),
  }
  for _, l in ipairs(h.old_lines) do
    patch[#patch + 1] = "-" .. l
  end
  for _, l in ipairs(h.new_lines) do
    patch[#patch + 1] = "+" .. l
  end
  patch[#patch + 1] = ""
  vim.system({ "git", "-C", dir, "apply", "--cached", "--unidiff-zero", "-" },
    { stdin = table.concat(patch, "\n") }, function(r)
      vim.schedule(function()
        if r.code ~= 0 then
          vim.notify("gitsigns: stage failed\n" .. (r.stderr or ""))
        else
          vim.notify("gitsigns: hunk staged")
        end
        refresh(true)
      end)
    end)
end

vim.keymap.set("n", "]c", next_hunk, { silent = true })
vim.keymap.set("n", "[c", prev_hunk, { silent = true })
vim.keymap.set("n", "ghp", preview_hunk, { silent = true })
vim.keymap.set("n", "ghs", stage_hunk, { silent = true })
vim.keymap.set("n", "ghu", undo_hunk, { silent = true })

-- explicit sync points force a diff (index may have changed without a buffer edit)
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
  callback = function()
    refresh(true)
  end,
})
-- idle/edit events are guarded by changedtick inside refresh
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI", "TextChanged", "InsertLeave" }, {
  callback = function()
    refresh()
  end,
})
