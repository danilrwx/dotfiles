-- Self-contained fuzzy picker: own matcher, own UI (prompt + list + treesitter
-- preview), no fzf and no plugin. Pickers: Files, GFiles, Buffers, LiveGrep.
-- Floating windows stacked preview (top) / results (middle) / prompt (bottom),
-- styled after the shell fzf config: sharp borders, "> " prompt, ">" pointer,
-- matched chars highlighted, counter inline-right. Ideas from mini.pick:
-- width-then-start ranking, marking + send-to-quickfix, choose in split/tab.

-- fzf-like palette (colours mirror FZF_DEFAULT_OPTS: match=blue, accents=green,
-- border=grey). default=true so a colorscheme can override.
local function setup_hl()
  local set = vim.api.nvim_set_hl
  set(0, "PickerBorder", { fg = "#6b7089", default = true })
  set(0, "PickerMatch", { fg = "#5fafff", bold = true, default = true })
  set(0, "PickerCurrent", { fg = "#00cd00", default = true })
  set(0, "PickerPointer", { fg = "#00cd00", bold = true, default = true })
  set(0, "PickerMarker", { fg = "#00cd00", default = true })
  set(0, "PickerCounter", { fg = "#5fafff", default = true })
  set(0, "PickerPrompt", { fg = "#dcdccc", bold = true, default = true })
end
setup_hl()
vim.api.nvim_create_autocmd("ColorScheme", { callback = setup_hl })

-- Fuzzy subsequence match. Score is two-tier like mini.pick: minimise the match
-- width (span from first to last matched char), then the start column.
-- ponytail: plain-lua, synchronous; fine for a repo's file list. For a huge
-- source (10k+) cap candidates or shell out to fzf — no async/caching here.
local function match_pos(sl, ql)
  local pos, si = {}, 1
  for qi = 1, #ql do
    local f = sl:find(ql:sub(qi, qi), si, true)
    if not f then
      return nil
    end
    pos[#pos + 1] = f
    si = f + 1
  end
  return pos
end

local function fuzzy(cands, q)
  if q == "" then
    return cands
  end
  local ql = q:lower()
  local scored = {}
  for _, s in ipairs(cands) do
    local pos = match_pos(s:lower(), ql)
    if pos then
      scored[#scored + 1] = { s = s, score = (pos[#pos] - pos[1]) * 100000 + pos[1] }
    end
  end
  table.sort(scored, function(a, b)
    if a.score ~= b.score then
      return a.score < b.score
    end
    return #a.s < #b.s
  end)
  local out = {}
  for _, e in ipairs(scored) do
    out[#out + 1] = e.s
  end
  return out
end

local ns = vim.api.nvim_create_namespace("picker")
local ns_cur = vim.api.nvim_create_namespace("picker_cur")
local hlns = vim.api.nvim_create_namespace("picker_hl")
local last_query = {}
local launchers = {}
local ring, ridx = {}, 0

local OPEN = { edit = "edit", split = "split", vsplit = "vsplit", tab = "tabedit" }

-- opts: name, prompt, parse(line)->{file,lnum}, live(q)->lines, on_pick(line,cmd)
local function open(cands, opts)
  local parse = opts.parse or function(l)
    return { file = l }
  end
  local filtered, sel, marked = cands, 1, {}
  local prev_visible = true
  local ftimer, ptimer

  local W, H = vim.o.columns, vim.o.lines
  local width = W - 2
  local col = 0
  local pv_h = math.floor(H * 0.5)
  local pr_h = 1
  local ls_h = math.max(3, H - pv_h - pr_h - 8)

  local function float(row, h, cfg)
    local buf = vim.api.nvim_create_buf(false, true)
    vim.bo[buf].bufhidden = "wipe" -- delete the scratch buffer when its window closes
    local c = vim.tbl_extend("force", {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = h,
      border = "single",
      style = "minimal",
      zindex = 50,
    }, cfg or {})
    local win = vim.api.nvim_open_win(buf, false, c)
    vim.wo[win].winhighlight = "FloatBorder:PickerBorder,FloatTitle:PickerPrompt,Normal:Normal"
    return win, buf
  end

  local prev_win, prev_buf = float(0, pv_h, { title = " preview " })
  local list_win, list_buf = float(pv_h + 2, ls_h, {})
  local prompt_win, prompt_buf = float(pv_h + 2 + ls_h + 2, pr_h,
    { title = " " .. (opts.prompt or "") .. " ", title_pos = "left" })

  vim.wo[prev_win].number = false
  vim.wo[list_win].signcolumn = "yes:1"
  vim.wo[prompt_win].statuscolumn = "%#PickerPrompt#> "
  vim.bo[prompt_buf].buftype = "nofile"
  vim.api.nvim_set_current_win(prompt_win)

  -- keymap hints in the list's bottom border (like the old fzf --header)
  local hint = "<cr> open   ^s/^v/^t split   ^x mark   <tab> qf   ^f/^b page   ^/ preview   ^o prev"
    .. (opts.hint_extra or "")
  pcall(vim.api.nvim_win_set_config, list_win,
    { footer = { { " " .. hint .. " ", "PickerBorder" } }, footer_pos = "center" })

  local function render_preview()
    local it = filtered[sel] and parse(filtered[sel]) or {}
    vim.bo[prev_buf].modifiable = true
    if not it.file or vim.fn.filereadable(it.file) == 0 then
      vim.api.nvim_buf_set_lines(prev_buf, 0, -1, false, {})
      vim.bo[prev_buf].modifiable = false
      return
    end
    vim.api.nvim_win_set_config(prev_win, { title = " " .. vim.fn.fnamemodify(it.file, ":t") .. " " })
    local lines = vim.fn.readfile(it.file, "", 500)
    -- readfile turns NUL bytes into \n; a line containing \n means binary content,
    -- which nvim_buf_set_lines rejects — show a placeholder instead.
    local binary = false
    for _, l in ipairs(lines) do
      if l:find("\n") then
        binary = true
        break
      end
    end
    if binary then
      lines = { "[binary file]" }
    end
    vim.api.nvim_buf_set_lines(prev_buf, 0, -1, false, lines)
    vim.bo[prev_buf].modifiable = false
    local ft = not binary and (vim.filetype.match({ filename = it.file, contents = lines }) or "") or ""
    vim.bo[prev_buf].filetype = ft
    if ft ~= "" then
      pcall(vim.treesitter.start, prev_buf)
    end
    vim.api.nvim_buf_clear_namespace(prev_buf, hlns, 0, -1)
    if it.lnum and it.lnum >= 1 and it.lnum <= #lines then
      vim.api.nvim_buf_set_extmark(prev_buf, hlns, it.lnum - 1, 0, { line_hl_group = "Visual" })
      pcall(vim.api.nvim_win_set_cursor, prev_win, { it.lnum, 0 })
      vim.api.nvim_win_call(prev_win, function()
        vim.cmd("normal! zz")
      end)
    end
  end

  -- preview reads the file and starts treesitter — too costly per keystroke, so
  -- debounce it: fast navigation repaints instantly, the preview catches up on a
  -- brief pause.
  local function schedule_preview()
    if not prev_visible then
      return
    end
    if ptimer then
      ptimer:stop()
    end
    ptimer = vim.defer_fn(render_preview, 60)
  end

  -- light: only the current-line highlight (own namespace), cursor and counter.
  -- Runs on every navigation keystroke, so it must not rebuild the list or read
  -- files — the preview is debounced separately.
  local function paint_current()
    vim.api.nvim_buf_clear_namespace(list_buf, ns_cur, 0, -1)
    local n = #filtered
    if n > 0 and sel <= n then
      vim.api.nvim_buf_set_extmark(list_buf, ns_cur, sel - 1, 0,
        { line_hl_group = "PickerCurrent", sign_text = ">", sign_hl_group = "PickerPointer" })
      pcall(vim.api.nvim_win_set_cursor, list_win, { sel, 0 })
      vim.api.nvim_win_call(list_win, function()
        vim.cmd("normal! zz") -- keep the selection centered while scrolling
      end)
    end
    local nmark = vim.tbl_count(marked)
    local counter = string.format(" %d/%d%s ", #filtered, #cands, nmark > 0 and (" " .. nmark .. "*") or "")
    pcall(vim.api.nvim_win_set_config, prompt_win, { footer = { { counter, "PickerCounter" } }, footer_pos = "right" })
    schedule_preview()
  end

  -- full: rebuild the list buffer + match/mark highlights. Only on query change
  -- or mark toggle, never on plain navigation.
  local function render_list()
    local q = (vim.api.nvim_buf_get_lines(prompt_buf, 0, 1, false)[1] or ""):lower()
    vim.bo[list_buf].modifiable = true
    vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, filtered)
    vim.bo[list_buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)
    -- mark/match highlights only for the first 500 rows (rarely scrolled past;
    -- keeps the highlight pass bounded while the buffer still holds every row so
    -- navigation and the pointer stay in sync with the preview).
    local lim = math.min(#filtered, 500)
    for i = 1, lim do
      local line = filtered[i]
      local row = i - 1
      if marked[line] then
        vim.api.nvim_buf_set_extmark(list_buf, ns, row, 0,
          { sign_text = "+", sign_hl_group = "PickerMarker" })
      end
      if q ~= "" then
        local pos = match_pos(line:lower(), q)
        for _, p in ipairs(pos or {}) do
          vim.api.nvim_buf_set_extmark(list_buf, ns, row, p - 1,
            { end_col = p, hl_group = "PickerMatch" })
        end
      end
    end
    paint_current()
  end

  local function refilter()
    local q = vim.api.nvim_buf_get_lines(prompt_buf, 0, 1, false)[1] or ""
    last_query[opts.name] = q
    if opts.live then
      filtered = q ~= "" and opts.live(q) or {}
      cands = filtered
    else
      filtered = fuzzy(cands, q)
    end
    sel = 1
    render_list()
  end

  local wins = { prev_win, list_win, prompt_win }
  local closing = false
  local function close()
    if closing then
      return
    end
    closing = true
    if ftimer then
      ftimer:stop()
    end
    if ptimer then
      ptimer:stop()
    end
    pcall(vim.cmd, "stopinsert")
    for _, w in ipairs(wins) do
      pcall(vim.api.nvim_win_close, w, true)
    end
  end

  -- tear the whole picker down if the prompt is left or closed by any means
  -- (:q, <C-w>, focus change) — not just via the mapped keys
  vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
    buffer = prompt_buf,
    once = true,
    callback = function()
      vim.schedule(close)
    end,
  })

  local function move(step)
    if #filtered == 0 then
      return
    end
    sel = (sel - 1 + step) % #filtered + 1 -- wrap around
    paint_current()
  end

  local function choose(cmd)
    local pick = filtered[sel]
    close()
    if pick then
      opts.on_pick(pick, cmd)
    end
  end

  -- Tab: send marked items (or all matches if none marked) to the quickfix list
  local function to_quickfix()
    local src = next(marked) and vim.tbl_keys(marked) or filtered
    if #src == 0 then
      return
    end
    local items = {}
    for _, line in ipairs(src) do
      local it = parse(line)
      if it.file then
        items[#items + 1] = { filename = it.file, lnum = it.lnum or 1, text = line }
      end
    end
    close()
    vim.fn.setqflist({}, " ", { items = items, title = opts.prompt })
    vim.cmd("copen")
    vim.cmd("cfirst")
  end

  local function toggle_preview()
    prev_visible = not prev_visible
    pcall(vim.api.nvim_win_set_config, prev_win, { hide = not prev_visible })
    if prev_visible then
      render_preview()
    end
  end

  -- debounce: coalesce fast typing into one refilter, so a big source (thousands
  -- of files) doesn't queue a render per keystroke and appear to freeze.
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    buffer = prompt_buf,
    callback = function()
      if ftimer then
        ftimer:stop()
      end
      ftimer = vim.defer_fn(refilter, 30)
    end,
  })

  local k = { buffer = prompt_buf, silent = true }
  local map = function(lhs, fn)
    vim.keymap.set("i", lhs, fn, k)
  end
  map("<C-n>", function() move(1) end)
  map("<Down>", function() move(1) end)
  map("<C-p>", function() move(-1) end)
  map("<Up>", function() move(-1) end)
  map("<C-g>", function()
    sel = 1
    paint_current()
  end)
  map("<CR>", function() choose("edit") end)
  map("<C-s>", function() choose("split") end)
  map("<C-v>", function() choose("vsplit") end)
  map("<C-t>", function() choose("tab") end)
  map("<Tab>", to_quickfix)
  map("<C-x>", function()
    local line = filtered[sel]
    if line then
      marked[line] = not marked[line] or nil
      sel = (sel % #filtered) + 1
      render_list() -- full: the mark sign changed
    end
  end)
  map("<C-/>", toggle_preview)
  local page = math.max(1, ls_h - 1)
  local function page_move(step)
    if #filtered == 0 then
      return
    end
    sel = math.max(1, math.min(#filtered, sel + step)) -- clamp, no wrap
    paint_current()
  end
  map("<C-f>", function() page_move(page) end) -- page down, stops at end
  map("<C-b>", function() page_move(-page) end) -- page up, stops at start
  local function cycle(step)
    if #ring <= 1 then
      return -- only this picker in history; nothing to switch to (don't close)
    end
    close()
    vim.schedule(function()
      _G.PickerCycle(step)
    end)
  end
  -- C-o: previous picker (MRU). Also shadows i_CTRL-O so it can't drop out of
  -- insert. Alt was unusable — terminals send it as Esc+key, tripping <Esc>=close.
  map("<C-o>", function() cycle(-1) end)
  map("<Esc>", close)
  map("<C-c>", close)
  if opts.actions then
    for lhs, fn in pairs(opts.actions) do
      map(lhs, function()
        fn({ sel = filtered[sel], refilter = refilter, close = close })
      end)
    end
  end

  -- MRU history (Alt-Tab): unique pickers ordered by recency, most recent last.
  -- A fresh open moves its type to the end; C-o steps back through it, so it
  -- lands on the previously used picker, not itself.
  if not opts.resuming then
    for i, n in ipairs(ring) do
      if n == opts.name then
        table.remove(ring, i)
        break
      end
    end
    ring[#ring + 1] = opts.name
    ridx = #ring
  end

  -- fresh open starts empty; only an explicit query (e.g. grep <cword>) or a
  -- history revisit (resuming) reseeds the previous query.
  local seed = opts.query or (opts.resuming and last_query[opts.name]) or ""
  if seed ~= "" then
    vim.api.nvim_buf_set_lines(prompt_buf, 0, 1, false, { seed })
  end
  refilter()
  vim.cmd("startinsert")
  vim.api.nvim_win_set_cursor(prompt_win, { 1, #seed })
end

function _G.PickerCycle(step)
  if #ring <= 1 then
    return
  end
  ridx = (ridx - 1 + step) % #ring + 1 -- wrap around the history
  launchers[ring[ridx]]({ resuming = true })
end

local function lines_of(cmd)
  local ok, r = pcall(function()
    return vim.system(cmd, { text = true }):wait()
  end)
  if not ok or not r then
    return {}
  end
  return vim.split(r.stdout or "", "\n", { trimempty = true })
end

-- grep hit -> file/lnum (ugrep: f:l:c:txt, grep: f:l:txt)
local function grep_parse(line)
  local f, l = line:match("^(.-):(%d+):%d+:")
  if not f then
    f, l = line:match("^(.-):(%d+):")
  end
  return { file = f, lnum = l and tonumber(l) }
end

local function edit_file(f, cmd)
  local verb = OPEN[cmd] or "edit"
  if verb == "edit" and vim.bo.modified then
    verb = "hide edit" -- current buffer has unsaved changes; keep it hidden (no E37)
  end
  vim.cmd(verb .. " " .. vim.fn.fnameescape(f))
end

local function files_source()
  if vim.fn.executable("rg") == 1 then
    return { "rg", "--files" }
  elseif vim.fn.executable("fd") == 1 then
    return { "fd", "--type", "f" }
  end
  return { "git", "ls-files", "--cached", "--others", "--exclude-standard" }
end

launchers = {
  files = function(o)
    open(lines_of(files_source()),
      { name = "files", prompt = "Files", on_pick = edit_file, resuming = o and o.resuming })
  end,
  gfiles = function(o)
    open(lines_of({ "git", "ls-files", "--cached", "--others", "--exclude-standard" }),
      { name = "gfiles", prompt = "GFiles", on_pick = edit_file, resuming = o and o.resuming })
  end,
  buffers = function(o)
    local names = {}
    for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
      if b.name ~= "" then
        names[#names + 1] = vim.fn.fnamemodify(b.name, ":~:.")
      end
    end
    open(names, {
      name = "buffers",
      prompt = "Buffers",
      on_pick = edit_file,
      resuming = o and o.resuming,
      hint_extra = "   ^d del",
      actions = {
        ["<C-d>"] = function(ctx)
          if ctx.sel then
            pcall(vim.cmd, "bdelete " .. vim.fn.fnameescape(ctx.sel))
          end
          ctx.close()
          vim.schedule(function()
            launchers.buffers({ resuming = true })
          end)
        end,
      },
    })
  end,
  livegrep = function(o)
    local tool = vim.fn.executable("ugrep") == 1
        and { "ugrep", "-RInk", "--ignore-files", "--color=never" }
      or { "rg", "--column", "--line-number", "--no-heading", "--color=never" }
    open({}, {
      name = "livegrep",
      prompt = "LiveGrep",
      query = o and o.query,
      parse = grep_parse,
      resuming = o and o.resuming,
      live = function(q)
        return lines_of(vim.list_extend(vim.deepcopy(tool), { "--", q }))
      end,
      on_pick = function(line, cmd)
        local it = grep_parse(line)
        if it.file then
          edit_file(it.file, cmd)
          if it.lnum then
            pcall(vim.fn.cursor, it.lnum, 1)
          end
        end
      end,
    })
  end,
}

vim.api.nvim_create_user_command("Files", function() launchers.files() end, {})
vim.api.nvim_create_user_command("GFiles", function() launchers.gfiles() end, {})
vim.api.nvim_create_user_command("Buffers", function() launchers.buffers() end, {})
vim.api.nvim_create_user_command("LiveGrep", function(o) launchers.livegrep({ query = o.args }) end, { nargs = "*" })

vim.keymap.set("n", "<leader>F", function() launchers.files() end, { silent = true })
vim.keymap.set("n", "<leader>f", function() launchers.gfiles() end, { silent = true })
vim.keymap.set("n", "<leader>b", function() launchers.buffers() end, { silent = true })
vim.keymap.set("n", "<leader>/", function() launchers.livegrep() end, { silent = true })
vim.keymap.set("n", "<leader>?", function() launchers.livegrep({ query = vim.fn.expand("<cword>") }) end, { silent = true })
vim.keymap.set("x", "<leader>/", function()
  vim.cmd('normal! "zy')
  launchers.livegrep({ query = (vim.fn.getreg("z"):gsub("\n.*", "")) })
end, { silent = true })
-- <leader>' reopens the most recently used picker; <leader>" the one before it.
-- From there A-n/A-p walk the history inside the picker.
local function resume(offset)
  local i = #ring - offset
  if i >= 1 and ring[i] then
    ridx = i
    launchers[ring[i]]({ resuming = true })
  end
end
vim.keymap.set("n", "<leader>'", function() resume(0) end, { silent = true })
vim.keymap.set("n", '<leader>"', function() resume(1) end, { silent = true })
