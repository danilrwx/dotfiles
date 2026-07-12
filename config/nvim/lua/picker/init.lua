-- Orchestrator: owns picker state (filtered/sel/marked), wires the UI to the
-- SEARCH matcher, binds in-picker keymaps, debounces, and tracks MRU history.
local ui = require("picker.ui")
local search = require("picker.search")

local M = {}
M.launchers = {} -- name -> function(opts); filled by the sources layer
-- Chronological log of opened pickers, most-recent last, NOT deduped (so
-- LiveGrep→LiveGrep→Commits→LiveGrep→Files→Files is kept as-is), capped at
-- HISTORY_MAX. Each entry reopens where you left off: { name, query, sel,
-- state }, where state is optional source-owned data (e.g. live grep's mode /
-- filter / cache). C-o steps through it; <leader>'/" resume by offset.
local HISTORY_MAX = 10
local RENDER_CAP = 500 -- highlight/position work is bounded to this many rows
local DEBOUNCE_MS = 30 -- coalesce a typing burst into one refilter
local PREVIEW_MS = 60 -- delay preview so fast navigation stays instant
local history = {}
local ridx = 0
local pending_resume -- the entry being resumed, handed to M.open by launch()

local HINT = "<cr> open   ^s/^v/^t split   ^x mark   <tab> qf   ^f/^b page   A-f/b scroll   ^/ preview   ^o prev"

-- opts: name, prompt, parse(line)->{file,lnum}, live(q)->lines, on_pick(line,cmd),
-- hint_extra, actions, query, resuming, get_state()->tbl (persisted in history)
function M.open(cands, opts)
  local parse = opts.parse or function(l)
    return { file = l }
  end

  local filtered, sel, marked = cands, 1, {}
  local positions -- per-row matched byte columns from the matcher (or nil)
  local ftimer, ptimer
  local live_seq = 0 -- bumped per query; async live results tagged stale if behind
  local entry -- this picker's history record (set below), kept live as query/sel change
  local restore_sel -- pending list position to reapply once results first arrive
  local last_q -- query of the last refilter; skips no-op debounced refilters

  local v = ui.new(opts.prompt or "", HINT .. (opts.hint_extra or ""))

  local function item()
    return filtered[sel] and parse(filtered[sel]) or {}
  end

  -- render the current selection into the preview pane (custom hook or file view)
  local function do_preview()
    if opts.preview then
      opts.preview(v, filtered[sel])
    else
      v:preview(item())
    end
  end

  -- preview reads a file and starts treesitter — debounce it so fast navigation
  -- stays instant and the preview catches up on a pause.
  local function schedule_preview()
    if not v.prev_visible then
      return
    end
    if ptimer then
      ptimer:stop()
    end
    ptimer = vim.defer_fn(do_preview, PREVIEW_MS)
  end

  local function paint()
    v:point(sel, filtered, #cands, vim.tbl_count(marked))
    schedule_preview()
  end

  local function render()
    local pos = {}
    if opts.line_positions then
      -- a live source (e.g. grep) supplies its own {col,hl} highlights per row
      for i = 1, math.min(#filtered, RENDER_CAP) do
        pos[i] = opts.line_positions(filtered[i])
      end
    elseif positions then
      -- matcher gave plain byte columns; tag them with the match colour
      for i, cols in ipairs(positions) do
        local hl = {}
        for _, c in ipairs(cols) do
          hl[#hl + 1] = { col = c, hl = "PickerMatch" }
        end
        pos[i] = hl
      end
    end

    -- base layer: colour the file path (opts.path_hl -> start,end bytes) under the
    -- match/line highlights, so every picker shows paths like live grep does.
    if opts.path_hl then
      for i = 1, math.min(#filtered, RENDER_CAP) do
        local s, e = opts.path_hl(filtered[i])
        if s then
          pos[i] = pos[i] or {}
          table.insert(pos[i], 1, { col = s, end_col = e, hl = "PickerGrepFile", priority = 50 })
        end
      end
    end

    -- reapply a resumed list position once results exist (fuzzy: this refilter;
    -- live: the async feed). Spent on first use so later refilters start at top.
    if restore_sel and #filtered > 0 then
      sel = math.max(1, math.min(restore_sel, #filtered))
      restore_sel = nil
    end

    v:render_list(filtered, marked, pos)
    paint()
  end

  -- async live sources call this later with results for query #seq; a result for
  -- a superseded query is dropped so slow greps can't clobber a newer one.
  local function feed(seq, lines)
    if seq ~= live_seq then
      return
    end
    filtered, cands, positions = lines, lines, nil
    sel = 1
    render()
  end

  local function refilter()
    local q = v:query()
    last_q = q
    if entry then
      entry.query = q
    end

    if opts.live then
      live_seq = live_seq + 1
      local seq = live_seq
      -- live() returns what to show immediately (cache/empty) and may push more
      -- via feed() when an async job (e.g. ripgrep) finishes.
      filtered, positions = opts.live(q, function(lines)
        feed(seq, lines)
      end), nil
      cands = filtered
    else
      filtered, positions = search.fuzzy(cands, q)
    end

    sel = 1
    render()
  end

  local closing = false
  local function close()
    if closing then
      return
    end

    closing = true
    if entry then
      entry.sel = sel -- remember list position for a later resume
      if opts.get_state then
        entry.state = opts.get_state()
      end
      -- an empty search is noise in the history; drop the entry on close and keep
      -- ridx pointing at the same logical spot so C-o doesn't skip after a prune.
      if vim.trim(entry.query) == "" then
        for i = #history, 1, -1 do
          if history[i] == entry then
            table.remove(history, i)
            if i <= ridx then
              ridx = ridx - 1
            end
            break
          end
        end
      end
    end

    if ftimer then
      ftimer:stop()
    end
    if ptimer then
      ptimer:stop()
    end
    if opts.on_close then
      opts.on_close() -- let a source tear down async work (e.g. kill a grep job)
    end

    v:close()
  end

  -- tear down if the prompt is left/closed by any means, not just mapped keys
  vim.api.nvim_create_autocmd({ "WinLeave", "WinClosed" }, {
    buffer = v.prompt_buf,
    once = true,
    callback = function()
      vim.schedule(close)
    end,
  })

  local function move(step)
    if #filtered == 0 then
      return
    end
    sel = (sel - 1 + step) % #filtered + 1 -- wrap
    paint()
  end

  local function page_move(step)
    if #filtered == 0 then
      return
    end
    sel = math.max(1, math.min(#filtered, sel + step)) -- clamp
    paint()
  end

  local function choose(cmd)
    local pick = filtered[sel]
    close()
    if pick then
      opts.on_pick(pick, cmd)
    end
  end

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

  local function cycle(step)
    if #history <= 1 then
      return -- only this picker in history; nothing to switch to (don't close)
    end
    close()
    vim.schedule(function()
      M.advance(step)
    end)
  end

  -- debounce typing: coalesce a burst into one refilter on a big source
  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    buffer = v.prompt_buf,
    callback = function()
      -- set_query() (open/actions) fires this async after the manual refilter
      -- already ran; skip when the text is unchanged so live_seq isn't bumped
      -- (which would drop the in-flight grep job as stale) and sel isn't reset.
      if v:query() == last_q then
        return
      end
      if ftimer then
        ftimer:stop()
      end
      ftimer = vim.defer_fn(refilter, DEBOUNCE_MS)
    end,
  })

  local k = { buffer = v.prompt_buf, silent = true }
  local function map(lhs, fn)
    vim.keymap.set("i", lhs, fn, k)
  end
  map("<C-n>", function() move(1) end)
  map("<Down>", function() move(1) end)
  map("<C-p>", function() move(-1) end)
  map("<Up>", function() move(-1) end)
  map("<C-g>", function()
    sel = 1
    paint()
  end)
  map("<CR>", function() choose("edit") end)
  map("<C-s>", function() choose("split") end)
  map("<C-v>", function() choose("vsplit") end)
  map("<C-t>", function() choose("tab") end)
  map("<Tab>", to_quickfix)
  map("<C-x>", function()
    local line = filtered[sel]
    if not line then
      return
    end
    marked[line] = not marked[line] or nil
    sel = (sel % #filtered) + 1
    render() -- full: the mark sign changed
  end)
  map("<C-/>", function()
    v:toggle_preview()
    if not v.prev_visible then
      return
    end
    do_preview()
  end)
  map("<C-f>", function() page_move(v.page) end)
  map("<C-b>", function() page_move(-v.page) end)
  map("<A-f>", function() v:scroll_preview(true) end) -- scroll preview down
  map("<A-b>", function() v:scroll_preview(false) end) -- scroll preview up
  -- C-o: previous picker (MRU). Also shadows i_CTRL-O so it can't drop out of
  -- insert. Alt was unusable — terminals send it as Esc+key, tripping <Esc>=close.
  map("<C-o>", function() cycle(-1) end)
  map("<Esc>", close)
  map("<C-c>", close)
  if opts.actions then
    for lhs, fn in pairs(opts.actions) do
      map(lhs, function()
        fn({
          sel = filtered[sel],
          query = v:query(),
          refilter = refilter,
          close = close,
          keep_pos = function()
            restore_sel = sel
          end,
          set_query = function(t)
            v:set_query(t)
            v:focus(#t)
          end,
          set_title = function(t) v:set_title(t) end,
        })
      end)
    end
  end

  -- history entry: a resume rebinds the exact entry it reopened (so its saved
  -- query+sel persist); any other open appends a fresh entry, keeping repeats.
  if opts.resuming and pending_resume then
    entry = pending_resume
  else
    entry = { name = opts.name, query = opts.query or "", sel = 1 }
    history[#history + 1] = entry
    while #history > HISTORY_MAX do
      table.remove(history, 1)
    end
    ridx = #history
  end

  restore_sel = opts.resuming and entry.sel or nil
  v:set_query(entry.query)
  refilter()
  v:focus(#entry.query)
end

-- History navigation, shared by C-o (advance, relative) and <leader>'/" (resume).
local function launch(i)
  local l = history[i] and M.launchers[history[i].name]
  if not l then
    return
  end
  ridx = i
  pending_resume = history[i]
  l({ resuming = true, state = history[i].state })
  pending_resume = nil
end

function M.advance(step)
  if #history <= 1 then
    return
  end
  launch((ridx - 1 + step) % #history + 1) -- wrap
end

function M.resume(offset)
  launch(#history - offset)
end

return M
