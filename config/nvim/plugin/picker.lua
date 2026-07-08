-- Self-contained fuzzy picker: own matcher, own UI (prompt + list + treesitter
-- preview), no fzf and no plugin. Pickers: Files, GFiles, Buffers, LiveGrep.
-- Layout is preview (top) / results (middle) / prompt (bottom). Ideas borrowed
-- from mini.pick: width-then-start match ranking, marking + send-to-quickfix,
-- choose in split/tab.

-- Fuzzy subsequence match. Score is two-tier like mini.pick: minimise the match
-- width (span from first to last matched char), then the start column — compact,
-- early matches rank first. Greedy leftmost positions (near-optimal for paths).
-- ponytail: plain-lua, synchronous; fine for a repo's file list. For a huge
-- source (10k+) cap candidates or shell out to fzf — no async/caching here.
local function fuzzy(cands, q)
  if q == "" then
    return cands
  end
  local ql = q:lower()
  local scored = {}
  for _, s in ipairs(cands) do
    local sl = s:lower()
    local si, first, last, ok = 1, nil, nil, true
    for qi = 1, #ql do
      local f = sl:find(ql:sub(qi, qi), si, true)
      if not f then
        ok = false
        break
      end
      first = first or f
      si, last = f + 1, f
    end
    if ok then
      scored[#scored + 1] = { s = s, score = (last - first) * 100000 + first }
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

  vim.cmd("tabnew")
  local prompt_win = vim.api.nvim_get_current_win()
  local prompt_buf = vim.api.nvim_get_current_buf()
  vim.cmd("aboveleft split")
  local list_win = vim.api.nvim_get_current_win()
  local list_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(list_win, list_buf)
  vim.cmd("aboveleft split")
  local prev_win = vim.api.nvim_get_current_win()
  local prev_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(prev_win, prev_buf)

  local prev_h = math.floor(vim.o.lines * 0.55)
  vim.api.nvim_win_set_height(prev_win, prev_h)
  vim.api.nvim_win_set_height(prompt_win, 1)
  vim.bo[prompt_buf].buftype = "nofile"
  vim.wo[prev_win].number = false
  vim.wo[prev_win].cursorline = false
  vim.wo[list_win].number = false

  local function render_preview()
    local it = filtered[sel] and parse(filtered[sel]) or {}
    vim.bo[prev_buf].modifiable = true
    if not it.file or vim.fn.filereadable(it.file) == 0 then
      vim.api.nvim_buf_set_lines(prev_buf, 0, -1, false, {})
      vim.bo[prev_buf].modifiable = false
      return
    end
    local lines = vim.fn.readfile(it.file, "", 500)
    vim.api.nvim_buf_set_lines(prev_buf, 0, -1, false, lines)
    vim.bo[prev_buf].modifiable = false
    local ft = vim.filetype.match({ filename = it.file, contents = lines }) or ""
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

  local function render_list()
    local shown = {}
    for i = 1, math.min(#filtered, 500) do
      shown[i] = filtered[i]
    end
    vim.bo[list_buf].modifiable = true
    vim.api.nvim_buf_set_lines(list_buf, 0, -1, false, shown)
    vim.bo[list_buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(list_buf, ns, 0, -1)
    for i, line in ipairs(shown) do
      if marked[line] then
        vim.api.nvim_buf_set_extmark(list_buf, ns, i - 1, 0,
          { sign_text = "▍", sign_hl_group = "Special" })
      end
    end
    if #shown > 0 then
      vim.api.nvim_buf_set_extmark(list_buf, ns, sel - 1, 0, { line_hl_group = "Visual" })
      pcall(vim.api.nvim_win_set_cursor, list_win, { sel, 0 })
    end
    local nmark = vim.tbl_count(marked)
    vim.wo[prompt_win].winbar = string.format("%s  %d/%d%s", opts.prompt or "", #filtered, #cands,
      nmark > 0 and ("  [" .. nmark .. " marked]") or "")
    if prev_visible then
      render_preview()
    end
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

  local function close()
    pcall(vim.cmd, "stopinsert")
    pcall(vim.api.nvim_win_close, prompt_win, true)
    pcall(vim.cmd, "tabclose")
  end

  local function move(step)
    if #filtered == 0 then
      return
    end
    sel = (sel - 1 + step) % #filtered + 1 -- wrap around
    render_list()
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
    vim.api.nvim_win_set_height(prev_win, prev_visible and prev_h or 0)
    if prev_visible then
      render_preview()
    end
  end

  local function scroll(keys)
    if prev_visible then
      vim.api.nvim_win_call(prev_win, function()
        vim.cmd("normal! " .. keys)
      end)
    end
  end

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, { buffer = prompt_buf, callback = refilter })

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
    render_list()
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
      move(1)
    end
  end)
  map("<C-/>", toggle_preview)
  map("<A-f>", function() scroll("\4") end) -- <C-d>
  map("<A-b>", function() scroll("\21") end) -- <C-u>
  map("<A-o>", function()
    close()
    vim.schedule(function()
      _G.PickerCycle(-1)
    end)
  end)
  map("<Esc>", close)
  map("<C-c>", close)
  if opts.actions then
    for lhs, fn in pairs(opts.actions) do
      map(lhs, function()
        fn({ sel = filtered[sel], refilter = refilter, close = close })
      end)
    end
  end

  -- track picker in the ring for <leader>'/<leader>" cycling
  if not opts.resuming then
    for i, n in ipairs(ring) do
      if n == opts.name then
        table.remove(ring, i)
      end
    end
    ring[#ring + 1] = opts.name
    ridx = #ring
  end

  local seed = opts.query or last_query[opts.name] or ""
  if seed ~= "" then
    vim.api.nvim_buf_set_lines(prompt_buf, 0, 1, false, { seed })
  end
  vim.api.nvim_set_current_win(prompt_win)
  refilter()
  vim.cmd("startinsert")
  vim.api.nvim_win_set_cursor(prompt_win, { 1, #seed })
end

function _G.PickerCycle(step)
  if #ring == 0 then
    return
  end
  ridx = (ridx - 1 + step) % #ring + 1
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
  vim.cmd((OPEN[cmd] or "edit") .. " " .. vim.fn.fnameescape(f))
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
      -- Ctrl-D: delete the buffer under the cursor, then refresh the list
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
vim.keymap.set("n", "<leader>'", function() _G.PickerCycle(-1) end, { silent = true })
vim.keymap.set("n", '<leader>"', function() _G.PickerCycle(1) end, { silent = true })
