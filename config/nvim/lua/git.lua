-- Git history/blame helpers, native (git CLI + vim.system + float/split), no
-- plugin. show() opens a commit; file_history() lists a file's commits in the
-- picker; blame_line() peeks the commit for the cursor line; blame_toggle()
-- annotates every line. Blame uses --contents of the live buffer, so line
-- numbers match even before saving.
local M = {}

-- git stores a symlink as its target path while nvim edits the followed file, so
-- blaming a symlink path against the followed content is nonsense — treat as N/A.
local function is_symlink(file)
  local st = vim.uv.fs_lstat(file)
  return st ~= nil and st.type == "link"
end

local function ctx()
  local file = vim.fn.expand("%:p")
  if file == "" or vim.bo.buftype ~= "" or is_symlink(file) then
    return nil
  end
  return { dir = vim.fn.expand("%:p:h"), file = file }
end

local function reldate(epoch)
  local d = math.max(0, os.time() - epoch)
  local units = { { 31536000, "y" }, { 2592000, "mo" }, { 86400, "d" }, { 3600, "h" }, { 60, "m" } }
  for _, u in ipairs(units) do
    if d >= u[1] then
      return math.floor(d / u[1]) .. u[2] .. " ago"
    end
  end
  return "just now"
end

-- parse `git blame --line-porcelain` into { [final_line] = {hash,author,time,summary} }
local function parse_blame(stdout)
  local out, cur = {}, nil
  for _, l in ipairs(vim.split(stdout or "", "\n")) do
    local hash, final = l:match("^(%x+)%s+%d+%s+(%d+)")
    if hash and #hash >= 7 then
      cur = { hash = hash, final = tonumber(final) }
    elseif cur then
      local a, t, s = l:match("^author (.+)"), l:match("^author%-time (%d+)"), l:match("^summary (.+)")
      if a then
        cur.author = a
      elseif t then
        cur.time = tonumber(t)
      elseif s then
        cur.summary = s
      elseif l:sub(1, 1) == "\t" then
        out[cur.final] = cur
        cur = nil
      end
    end
  end
  return out
end

local function uncommitted(hash)
  return hash:match("^0+$") ~= nil
end

-- run `git blame --line-porcelain` over the buffer's live lines (written to a
-- temp file so unsaved edits are blamed too) and hand the parsed result + the
-- raw system result to cb on the main loop. extra: argv before --line-porcelain
-- (e.g. { "-L", "5,5" } for a single line). Always removes the temp file.
local function blame_contents(dir, file, lines, extra, cb)
  local tmp = vim.fn.tempname()
  vim.fn.writefile(lines, tmp)
  local cmd = { "git", "-C", dir, "blame" }
  vim.list_extend(cmd, extra or {})
  vim.list_extend(cmd, { "--line-porcelain", "--contents", tmp, "--", file })
  vim.system(cmd, { text = true }, function(r)
    os.remove(tmp)
    vim.schedule(function()
      cb(parse_blame(r.stdout), r)
    end)
  end)
end

-- build a picker preview(v, line) that keys each row via key_of(line), runs
-- cmd_of(key) once (cached for the picker's lifetime) and renders the output as
-- filetype ft with title title_of(key). Empty/unkeyed rows clear the pane.
function M.cached_preview(key_of, cmd_of, ft, title_of)
  local cache = {}
  return function(v, line)
    local key = line and key_of(line)
    if not key then
      v:show_text({}, "", "")
      return
    end
    if cache[key] then
      v:show_text(cache[key], ft, title_of(key))
      return
    end
    vim.system(cmd_of(key), { text = true }, function(r)
      local dl = vim.split(r.stdout or "", "\n", { trimempty = true })
      cache[key] = dl
      vim.schedule(function()
        pcall(function()
          v:show_text(dl, ft, title_of(key))
        end)
      end)
    end)
  end
end

-- git-highlighted scratch buffer (commit/log/diff). where = "tab" | "split".
-- dir is the repo, so <CR> on a commit hash can open it (fugitive-style browse).
local function scratch(lines, name, where, dir)
  if lines[#lines] == "" then
    table.remove(lines)
  end
  if #lines == 0 then
    vim.notify("git: nothing to show")
    return
  end
  vim.cmd(where == "tab" and "tabnew" or "botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "git"
  vim.bo[buf].modifiable = false
  -- ws_match adds a trailing-whitespace ErrorMsg match on BufWinEnter (before we
  -- set nofile); drop it so diff/log lines aren't flagged red.
  vim.fn.clearmatches()
  vim.b[buf].git_dir = dir
  pcall(vim.api.nvim_buf_set_name, buf, name)
  local function hash_under_cursor()
    local w = vim.fn.expand("<cword>")
    return (w:match("^%x+$") and #w >= 7) and w or nil
  end
  vim.keymap.set("n", "<CR>", function()
    local h = hash_under_cursor()
    if h then
      M.show(h, { dir = dir })
    end
  end, { buffer = buf })
  vim.keymap.set("n", "o", function()
    local h = hash_under_cursor()
    if h then
      M.open_pr(h, dir)
    end
  end, { buffer = buf })
end

-- open `git show <rev>` (optionally scoped to a path) in a diff-highlighted tab
function M.show(rev, opts)
  opts = opts or {}
  local dir = opts.dir or vim.fn.expand("%:p:h")
  local args = { "git", "-C", dir, "show", "--no-color", rev }
  if opts.path then
    vim.list_extend(args, { "--", opts.path })
  end
  vim.system(args, { text = true }, function(r)
    vim.schedule(function()
      scratch(vim.split(r.stdout or "", "\n"), "git show " .. rev:sub(1, 12), "tab", dir)
    end)
  end)
end

-- fugitive-style `:0Gclog`: the current file's whole log with patches, in a tab
function M.file_log()
  local c = ctx()
  if not c then
    return
  end
  vim.system({ "git", "-C", c.dir, "log", "--follow", "--no-color", "-p", "--", c.file },
    { text = true }, function(r)
      vim.schedule(function()
        scratch(vim.split(r.stdout or "", "\n"), "git log " .. vim.fn.fnamemodify(c.file, ":t"), "tab", c.dir)
      end)
    end)
end

-- byte span of the leading commit hash (first token) in a log row
local function hash_span(line)
  local c = line:find("%s")
  return 0, c and c - 1 or #line
end

-- fuzzy-pick a commit from the current file's history; <CR> shows its diff
function M.file_history(o)
  local c = ctx()
  if not c then
    return
  end
  local r = vim.system({
    "git", "-C", c.dir, "log", "--follow",
    "--format=%h  %s  (%cr) <%an>", "--", c.file,
  }, { text = true }):wait()
  local items = vim.split(r.stdout or "", "\n", { trimempty = true })
  if #items == 0 then
    vim.notify("git: no history for this file")
    return
  end
  require("picker").open(items, {
    name = "git_file_history",
    prompt = "File history",
    resuming = o and o.resuming,
    path_hl = hash_span,
    preview = M.cached_preview(
      function(line) return line:match("^(%x+)") end,
      function(hash) return { "git", "-C", c.dir, "show", "--no-color", hash, "--", c.file } end,
      "git",
      function(hash) return hash:sub(1, 10) end),
    on_pick = function(line)
      local hash = line:match("^(%x+)")
      if hash then
        M.show(hash, { dir = c.dir, path = c.file })
      end
    end,
  })
end

-- repo root for the current file (or cwd), nil if not in a repo
local function root(dir)
  dir = dir or vim.fn.expand("%:p:h")
  if dir == "" then
    dir = vim.fn.getcwd()
  end
  local r = vim.trim((vim.system({ "git", "-C", dir, "rev-parse", "--show-toplevel" }, { text = true }):wait().stdout or ""))
  return r ~= "" and r or nil
end

-- browse the whole repo log in the picker: fuzzy over subjects, preview the diff.
function M.commits(o)
  local r = root()
  if not r then
    vim.notify("git: not a repo")
    return
  end
  local log = vim.system({ "git", "-C", r, "log", "-n", "10000", "--format=%h  %s  (%cr) <%an>" }, { text = true }):wait()
  local items = vim.split(log.stdout or "", "\n", { trimempty = true })
  if #items == 0 then
    vim.notify("git: no commits")
    return
  end
  require("picker").open(items, {
    name = "git_commits",
    prompt = "Commits",
    resuming = o and o.resuming,
    path_hl = hash_span,
    preview = M.cached_preview(
      function(line) return line:match("^(%x+)") end,
      function(h) return { "git", "-C", r, "show", "--no-color", h } end,
      "git",
      function(h) return h end),
    on_pick = function(line)
      local h = line:match("^(%x+)")
      if h then
        M.show(h, { dir = r })
      end
    end,
  })
end

-- git status in the picker: <CR> opens the file, ^s stages, ^u unstages.
local function status_path(line)
  local p = line:sub(4)
  return (p:match(" %-> (.+)$") or p) -- take the new name of a rename
end

function M.status(o)
  o = o or {}
  local r = root()
  if not r then
    vim.notify("git: not a repo")
    return
  end
  local st = vim.system({ "git", "-C", r, "status", "--porcelain=v1" }, { text = true }):wait()
  local items = vim.split(st.stdout or "", "\n", { trimempty = true })
  if #items == 0 then
    vim.notify("git: clean")
    return
  end
  require("picker").open(items, {
    name = "git_status",
    prompt = "Status",
    resuming = o.resuming,
    query = o.query,
    hint_extra = "   ^s stage  ^u unstage",
    path_hl = function(line)
      return 3, #line
    end,
    preview = M.cached_preview(
      status_path,
      function(p) return { "git", "-C", r, "diff", "--no-color", "HEAD", "--", p } end,
      "diff",
      function(p) return p end),
    actions = {
      ["<C-s>"] = function(ctx)
        if ctx.sel then
          vim.system({ "git", "-C", r, "add", "--", status_path(ctx.sel) }):wait()
        end
        ctx.close()
        vim.schedule(function()
          M.status({ query = ctx.query })
        end)
      end,
      ["<C-u>"] = function(ctx)
        if ctx.sel then
          vim.system({ "git", "-C", r, "restore", "--staged", "--", status_path(ctx.sel) }):wait()
        end
        ctx.close()
        vim.schedule(function()
          M.status({ query = ctx.query })
        end)
      end,
    },
    on_pick = function(line)
      vim.cmd("edit " .. vim.fn.fnameescape(r .. "/" .. status_path(line)))
    end,
  })
end

-- resolve origin's host and namespace/repo path (ssh or https remote)
local function remote_host_path(dir)
  local url = vim.trim((vim.system({ "git", "-C", dir, "remote", "get-url", "origin" }, { text = true }):wait().stdout or ""))
  local host, path = url:match("^%w+@([^:]+):(.+)$")
  if not host then
    host, path = url:match("^https?://[^/]-([%w.%-]+)/(.+)$")
  end
  if path then
    path = path:gsub("%.git$", "")
  end
  return host, path
end

-- open the PR/MR that introduced <hash> in the browser (gh for github, glab else)
function M.open_pr(hash, dir)
  dir = dir or vim.fn.expand("%:p:h")
  local host, path = remote_host_path(dir)
  if not host then
    vim.notify("git: no origin remote")
    return
  end
  local cmd
  if host:match("github") then
    cmd = { "gh", "api", "repos/{owner}/{repo}/commits/" .. hash .. "/pulls", "--jq", ".[0].html_url // empty" }
  elseif path then
    local enc = path:gsub("/", "%%2F")
    cmd = { "glab", "api", "projects/" .. enc .. "/repository/commits/" .. hash .. "/merge_requests",
      "--jq", ".[0].web_url // empty" }
  else
    vim.notify("git: can't parse remote " .. host)
    return
  end
  vim.system(cmd, { text = true, cwd = dir }, function(r)
    vim.schedule(function()
      local url = vim.trim(r.stdout or "")
      if r.code ~= 0 or url == "" then
        vim.notify("git: no PR/MR for " .. hash:sub(1, 10))
        return
      end
      if vim.ui.open then
        vim.ui.open(url)
      else
        vim.fn.jobstart({ "open", url })
      end
    end)
  end)
end

-- show the commit for the cursor line in a focused float: <CR> opens the commit,
-- o opens its PR/MR, q/<Esc> closes.
function M.blame_line()
  local c = ctx()
  if not c then
    return
  end
  local lnum = vim.fn.line(".")
  blame_contents(c.dir, c.file, vim.fn.getline(1, "$"), { "-L", lnum .. "," .. lnum }, function(bl)
      local _, e = next(bl)
      if not e then
        vim.notify("git blame: no info")
        return
      end
      local committed = not uncommitted(e.hash)
      local lines
      if committed then
        local when = e.time and (os.date("%Y-%m-%d", e.time) .. "  " .. reldate(e.time)) or "?"
        lines = { e.hash:sub(1, 10) .. "  " .. (e.author or "?"), when, "", e.summary or "",
          "", "⏎ commit   o PR/MR   q close" }
      else
        lines = { "● Not committed yet" }
      end
      local w = 0
      for _, l in ipairs(lines) do
        w = math.max(w, vim.fn.strdisplaywidth(l))
      end
      local buf = vim.api.nvim_create_buf(false, true)
      vim.bo[buf].bufhidden = "wipe" -- drop the scratch buffer with its window
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
      local ns = vim.api.nvim_create_namespace("git_blame_float")
      local function hl(group, ln, from, to)
        local endcol = to == -1 and #lines[ln + 1] or to
        pcall(vim.api.nvim_buf_set_extmark, buf, ns, ln, from, { end_col = endcol, hl_group = group })
      end
      if committed then
        hl("Type", 0, 0, 10) -- hash
        hl("Function", 0, 12, -1) -- author
        hl("Comment", 1, 0, -1) -- date / relative
        hl("Normal", 3, 0, -1) -- summary (white)
        hl("Comment", #lines - 1, 0, -1) -- key hint
      else
        hl("Comment", 0, 0, -1)
      end
      -- flip above the cursor when there isn't room below, so the float never
      -- spills past the bottom of the window (+2 leaves room for its border).
      local below = vim.api.nvim_win_get_height(0) - vim.fn.winline()
      local anchor, row = "NW", 1
      if #lines + 2 > below then
        anchor, row = "SW", 0
      end
      local win = vim.api.nvim_open_win(buf, true, {
        relative = "cursor", anchor = anchor, row = row, col = 0,
        width = math.min(w, vim.o.columns - 4), height = #lines,
        style = "minimal", border = "rounded",
      })
      local function close()
        pcall(vim.api.nvim_win_close, win, true)
      end
      vim.keymap.set("n", "q", close, { buffer = buf })
      vim.keymap.set("n", "<Esc>", close, { buffer = buf })
      if committed then
        vim.keymap.set("n", "<CR>", function()
          close()
          M.show(e.hash, { dir = c.dir })
        end, { buffer = buf })
        vim.keymap.set("n", "o", function()
          close()
          M.open_pr(e.hash, c.dir)
        end, { buffer = buf })
      end
    end)
end

local blame_ns = vim.api.nvim_create_namespace("git_blame")
local blame_on = {}
local blame_pending = {} -- buf -> true while a full-blame git call is in flight
local cur_ns = vim.api.nvim_create_namespace("git_cur_blame")
local refresh_cur -- forward decl (defined in the current-line section below)

-- toggle per-line blame annotations (short hash · author · relative date)
function M.blame_toggle()
  local buf = vim.api.nvim_get_current_buf()
  if blame_on[buf] then
    vim.api.nvim_buf_clear_namespace(buf, blame_ns, 0, -1)
    blame_on[buf] = nil
    if refresh_cur then
      refresh_cur(buf) -- bring back the single current-line annotation
    end
    return
  end
  if blame_pending[buf] then
    return -- a full-blame call is already running for this buffer
  end
  -- full blame annotates every line, so drop the current-line one to avoid overlap
  vim.api.nvim_buf_clear_namespace(buf, cur_ns, 0, -1)
  local c = ctx()
  if not c then
    return
  end
  blame_pending[buf] = true
  blame_contents(c.dir, c.file, vim.fn.getline(1, "$"), nil, function(bl)
    blame_pending[buf] = nil
    if not vim.api.nvim_buf_is_valid(buf) then
      return
    end
    for line, e in pairs(bl) do
      local text = uncommitted(e.hash) and "● uncommitted"
        or (e.hash:sub(1, 8) .. " · " .. (e.author or "?") .. " · " .. (e.time and reldate(e.time) or "?"))
      pcall(vim.api.nvim_buf_set_extmark, buf, blame_ns, line - 1, 0, {
        virt_text = { { text, "Comment" } },
        virt_text_pos = "right_align",
      })
    end
    blame_on[buf] = true
  end)
end

-- Always-on current-line blame: subtle right-aligned annotation that follows the
-- cursor. Full blame (parse_blame) is cached per buffer+changedtick; the cursor
-- just reads the cached line, so moving is instant and git runs only after edits.
-- (cur_ns is declared above, shared with blame_toggle.)
local lb_cache = {} -- buf -> { tick, data }
local lb_pending = {}
M.line_blame = true

local function render_cur(buf)
  vim.api.nvim_buf_clear_namespace(buf, cur_ns, 0, -1)
  if not M.line_blame or blame_on[buf] then
    return -- full-file blame already annotates every line
  end
  local c = lb_cache[buf]
  if not c or vim.api.nvim_get_current_buf() ~= buf then
    return
  end
  local line = vim.api.nvim_win_get_cursor(0)[1]
  local e = c.data[line]
  if not e then
    return
  end
  local text = uncommitted(e.hash) and "● uncommitted"
    or ((e.author or "?") .. " · " .. (e.time and reldate(e.time) or "?") .. " · " .. (e.summary or ""))
  local max = 80
  if vim.fn.strdisplaywidth(text) > max then
    text = vim.fn.strcharpart(text, 0, max - 1) .. "…"
  end
  pcall(vim.api.nvim_buf_set_extmark, buf, cur_ns, line - 1, 0, {
    virt_text = { { text, "Comment" } },
    virt_text_pos = "right_align",
  })
end

refresh_cur = function(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if not M.line_blame or vim.bo[buf].buftype ~= "" or name == "" or is_symlink(name) then
    pcall(vim.api.nvim_buf_clear_namespace, buf, cur_ns, 0, -1)
    return
  end
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  if (lb_cache[buf] and lb_cache[buf].tick == tick) or lb_pending[buf] then
    return
  end
  lb_pending[buf] = true
  local file = vim.api.nvim_buf_get_name(buf)
  local dir = vim.fn.fnamemodify(file, ":h")
  blame_contents(dir, file, vim.api.nvim_buf_get_lines(buf, 0, -1, false), nil, function(bl, r)
    lb_pending[buf] = nil
    if r.code == 0 and vim.api.nvim_buf_is_valid(buf) then
      lb_cache[buf] = { tick = tick, data = bl }
      render_cur(buf)
    end
  end)
end

function M.line_blame_toggle()
  M.line_blame = not M.line_blame
  local buf = vim.api.nvim_get_current_buf()
  if M.line_blame then
    refresh_cur(buf)
  else
    vim.api.nvim_buf_clear_namespace(buf, cur_ns, 0, -1)
  end
end

-- open the PR/MR for the commit in context: a hash under cursor in a git buffer,
-- otherwise the commit that last touched the current line.
function M.open_pr_at()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].filetype == "git" then
    local w = vim.fn.expand("<cword>")
    if w:match("^%x+$") and #w >= 7 then
      M.open_pr(w, vim.b[buf].git_dir)
    end
    return
  end
  local c = lb_cache[buf]
  local e = c and c.data[vim.fn.line(".")]
  if e and not uncommitted(e.hash) then
    M.open_pr(e.hash, vim.fn.expand("%:p:h"))
  else
    vim.notify("git: no commit for this line")
  end
end

function M.setup_current_line()
  local grp = vim.api.nvim_create_augroup("git_cur_blame", { clear = true })
  -- CursorMoved renders instantly from cache; CursorHold/BufEnter refresh it.
  vim.api.nvim_create_autocmd("CursorMoved", {
    group = grp,
    callback = function(a)
      render_cur(a.buf)
    end,
  })
  vim.api.nvim_create_autocmd({ "CursorHold", "BufEnter" }, {
    group = grp,
    callback = function(a)
      refresh_cur(a.buf)
    end,
  })
  -- drop per-buffer state when a buffer is wiped, so the tables don't grow
  -- unbounded across a long session.
  vim.api.nvim_create_autocmd("BufWipeout", {
    group = grp,
    callback = function(a)
      blame_on[a.buf], blame_pending[a.buf] = nil, nil
      lb_cache[a.buf], lb_pending[a.buf] = nil, nil
    end,
  })
end

-- exported for reuse (gitsigns, picker sources) so root/symlink logic lives once
M.root = root
M.is_symlink = is_symlink

-- register the picker-backed views as launchers so C-o / <leader>' can resume
-- them (they reresolve ctx/root for the current buffer on reopen).
local launchers = require("picker").launchers
launchers.git_file_history = function(o)
  M.file_history(o)
end
launchers.git_commits = function(o)
  M.commits(o)
end
launchers.git_status = function(o)
  M.status(o)
end

return M
