-- Orchestrator: owns picker state (filtered/sel/marked), wires the UI to the
-- SEARCH matcher, binds in-picker keymaps, debounces, and tracks MRU history.
local ui = require("picker.ui")
local search = require("picker.search")

local M = {}
M.launchers = {} -- name -> function(opts); filled by the sources layer
local last_query = {}
local ring, ridx = {}, 0

local HINT = "<cr> open   ^s/^v/^t split   ^x mark   <tab> qf   ^f/^b page   A-f/b scroll   ^/ preview   ^o prev"

-- opts: name, prompt, parse(line)->{file,lnum}, live(q)->lines, on_pick(line,cmd),
-- hint_extra, actions, query, resuming
function M.open(cands, opts)
  local parse = opts.parse or function(l)
    return { file = l }
  end
  local filtered, sel, marked = cands, 1, {}
  local positions -- per-row matched byte columns from the matcher (or nil)
  local ftimer, ptimer
  local live_seq = 0 -- bumped per query; async live results tagged stale if behind

  local v = ui.new(opts.prompt or "", HINT .. (opts.hint_extra or ""))

  local function item()
    return filtered[sel] and parse(filtered[sel]) or {}
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
    ptimer = vim.defer_fn(function()
      if opts.preview then
        opts.preview(v, filtered[sel])
      else
        v:preview(item())
      end
    end, 60)
  end

  local function paint()
    v:point(sel, filtered, #cands, vim.tbl_count(marked))
    schedule_preview()
  end

  local function render()
    local pos
    if opts.line_positions then
      -- a live source (e.g. grep) supplies its own {col,hl} highlights per row
      pos = {}
      for i = 1, math.min(#filtered, 500) do
        pos[i] = opts.line_positions(filtered[i])
      end
    elseif positions then
      -- matcher gave plain byte columns; tag them with the match colour
      pos = {}
      for i, cols in ipairs(positions) do
        local hl = {}
        for _, c in ipairs(cols) do
          hl[#hl + 1] = { col = c, hl = "PickerMatch" }
        end
        pos[i] = hl
      end
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
    last_query[opts.name] = q
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
    if ftimer then
      ftimer:stop()
    end
    if ptimer then
      ptimer:stop()
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
    if #ring <= 1 then
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
      if ftimer then
        ftimer:stop()
      end
      ftimer = vim.defer_fn(refilter, 30)
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
    if line then
      marked[line] = not marked[line] or nil
      sel = (sel % #filtered) + 1
      render() -- full: the mark sign changed
    end
  end)
  map("<C-/>", function()
    v:toggle_preview()
    if v.prev_visible then
      if opts.preview then
        opts.preview(v, filtered[sel])
      else
        v:preview(item())
      end
    end
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
          refilter = refilter,
          close = close,
          set_query = function(t)
            v:set_query(t)
            v:focus(#t)
          end,
          set_title = function(t) v:set_title(t) end,
        })
      end)
    end
  end

  -- MRU history (Alt-Tab): unique pickers by recency, most recent last. A fresh
  -- open moves its type to the end; C-o steps back through it (wrapping).
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

  -- fresh open starts empty; only an explicit query or a history revisit reseeds
  local seed = opts.query or (opts.resuming and last_query[opts.name]) or ""
  v:set_query(seed)
  refilter()
  v:focus(#seed)
end

-- History navigation, shared by C-o (advance, relative) and <leader>'/" (resume).
function M.advance(step)
  if #ring <= 1 then
    return
  end
  ridx = (ridx - 1 + step) % #ring + 1 -- wrap
  M.launchers[ring[ridx]]({ resuming = true })
end

function M.resume(offset)
  local i = #ring - offset
  if i >= 1 and ring[i] then
    ridx = i
    M.launchers[ring[i]]({ resuming = true })
  end
end

return M
