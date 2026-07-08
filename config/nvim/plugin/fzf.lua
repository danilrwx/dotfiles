-- fzf pickers, ported from the vim config. Uses fzf's bundled base plugin
-- (fzf#run) from brew/apt -- the fzf binary's own runtime, no managed plugin.

-- Make fzf's base plugin available: brew keeps it under <prefix>/plugin (add to
-- rtp + source), apt ships a standalone example file (source directly).
local loaded = false
for _, d in ipairs({
  "/opt/homebrew/opt/fzf",
  "/usr/local/opt/fzf",
  "/home/linuxbrew/.linuxbrew/opt/fzf",
  vim.fn.expand("~/.fzf"),
}) do
  if vim.fn.isdirectory(d) == 1 then
    vim.opt.runtimepath:append(d)
    if vim.fn.filereadable(d .. "/plugin/fzf.vim") == 1 then
      vim.cmd("source " .. d .. "/plugin/fzf.vim")
    end
    loaded = true
    break
  end
end
if not loaded then
  for _, f in ipairs({ "/usr/share/vim/vimfiles/plugin/fzf.vim", "/usr/share/doc/fzf/examples/fzf.vim" }) do
    if vim.fn.filereadable(f) == 1 then
      vim.cmd("source " .. f)
      break
    end
  end
end

if vim.fn.exists("*fzf#run") == 0 then
  return
end
local run = vim.fn["fzf#run"]

-- preview: bat (batcat on apt) gives syntax highlighting; plain cat otherwise.
local bat = vim.fn.executable("bat") == 1 and "bat"
  or (vim.fn.executable("batcat") == 1 and "batcat" or nil)

-- preview opts for a file target ({} for files, {2} for the buffers picker)
local function preview_file(target)
  local cmd = bat and (bat .. " --style=numbers --color=always --line-range :500 " .. target)
    or ("cat -- " .. target)
  return { "--preview", cmd, "--preview-window", "right:60%:border-left" }
end

-- preview opts for grep hits (file:line:col:text); highlight and scroll to the
-- matched line ({1}=file, {2}=line via the picker's ':' delimiter)
local function preview_grep()
  local cmd = bat and (bat .. " --style=numbers --color=always --highlight-line {2} -- {1}")
    or "cat -- {1}"
  return { "--preview", cmd, "--preview-window", "right:55%:border-left:+{2}-/2" }
end

-- Unified picker framework with resumable state. Each picker has a name and a
-- launcher(query). Every fzf runs with --print-query so the typed query comes
-- back on the first output line; we stash it in `saved` and re-seed --query when
-- the picker is reopened, so state (and, for live grep, the result) survives.
-- History of picker names lets you cycle between them: <leader>'/<leader>" when
-- fzf is closed, alt-o (an --expect key) from inside fzf.
-- per-picker query history file. --history makes fzf steal ctrl-n/ctrl-p for
-- history, so bind them back to list nav and move history to alt-n/alt-p.
local HISTDIR = vim.fn.stdpath("state") .. "/fzf-history"
vim.fn.mkdir(HISTDIR, "p")

local saved = {}
local launchers = {}
local history = {}
local ridx = 0
local resuming = false

local function index_of(list, v)
  for i, x in ipairs(list) do
    if x == v then
      return i
    end
  end
  return nil
end

local function open(name, query)
  if not resuming then
    local i = index_of(history, name)
    if i then
      table.remove(history, i)
    end
    history[#history + 1] = name
    if #history > 10 then
      table.remove(history, 1)
    end
    ridx = #history
  end
  launchers[name](query)
end

local function cycle(step)
  if #history == 0 then
    return
  end
  local n = #history
  local base = (ridx < 1) and n or ridx
  ridx = ((base - 1 + step) % n + n) % n + 1
  local name = history[ridx]
  resuming = true
  open(name, saved[name] or "")
  resuming = false
end
vim.keymap.set("n", "<leader>'", function()
  cycle(-1)
end, { silent = true })
vim.keymap.set("n", '<leader>"', function()
  cycle(1)
end, { silent = true })

-- common sink: line 1 is the query (--print-query), line 2 the --expect key
-- ('' for Enter), the rest the selection. Saves the query, routes alt-o to the
-- picker ring, otherwise hands (key, items) to the picker's accept handler.
local function finish(name, lines, on_accept)
  if #lines == 0 then
    return
  end
  -- keep the last non-empty query so an accidental blank input doesn't wipe it
  if lines[1] ~= "" then
    saved[name] = lines[1]
  end
  local key = lines[2] or ""
  if key == "alt-o" then
    cycle(-1)
    return
  end
  local items = {}
  for i = 3, #lines do
    items[#items + 1] = lines[i]
  end
  on_accept(key, items)
end

local function base_opts(name, prompt, query, expect_keys)
  -- --height 100% overrides the 40% in FZF_DEFAULT_OPTS so vim pickers fill the
  -- window instead of hugging the top (shell fzf keeps its 40%).
  return {
    "--height",
    "100%",
    "--print-query",
    "--multi",
    "--expect",
    expect_keys,
    "--history",
    HISTDIR .. "/" .. name,
    "--bind",
    "ctrl-n:down,ctrl-p:up,alt-n:next-history,alt-p:previous-history,ctrl-/:toggle-preview",
    "--query",
    query,
    "--prompt",
    prompt,
  }
end

local function extend(a, b)
  for _, v in ipairs(b) do
    a[#a + 1] = v
  end
  return a
end

local function open_files(_, items)
  for _, f in ipairs(items) do
    vim.cmd("edit " .. vim.fn.fnameescape(f))
  end
end

local function launch_files(query)
  run({
    ["sink*"] = function(lines)
      finish("files", lines, open_files)
    end,
    options = extend(extend(base_opts("files", "Files> ", query, "alt-o"), preview_file("{}")),
      { "--header", "Alt-O: prev  Ctrl-/: preview" }),
  })
end

local function launch_gfiles(query)
  run({
    source = "git ls-files --cached --others --exclude-standard",
    ["sink*"] = function(lines)
      finish("gfiles", lines, open_files)
    end,
    options = extend(extend(base_opts("gfiles", "GFiles> ", query, "alt-o"), preview_file("{}")),
      { "--header", "Alt-O: prev  Ctrl-/: preview" }),
  })
end

local function buf_accept(key, items)
  local nums = {}
  for _, l in ipairs(items) do
    nums[#nums + 1] = tonumber(l:match("^%d+"))
  end
  if #nums == 0 then
    return
  end
  if key == "ctrl-d" then
    vim.cmd("bdelete " .. table.concat(nums, " "))
  else
    vim.cmd("buffer " .. nums[1])
  end
end

local function launch_buffers(query)
  local bufs = {}
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if b.name ~= "" then
      bufs[#bufs + 1] = string.format("%d\t%s", b.bufnr, vim.fn.fnamemodify(b.name, ":~:."))
    end
  end
  run({
    source = bufs,
    ["sink*"] = function(lines)
      finish("buffers", lines, buf_accept)
    end,
    options = extend(extend(base_opts("buffers", "Buffers> ", query, "ctrl-d,alt-o"), preview_file("{2}")), {
      "--with-nth",
      "2..",
      "-d",
      "\t",
      "--header",
      "Enter: open  Ctrl-D: delete  Tab: select  Alt-O: prev  Ctrl-/: preview",
    }),
  })
end

local function grep_item(line)
  -- ugrep gives file:line:col:text, grep gives file:line:text
  local m = vim.fn.matchlist(line, [[^\(.\{-}\):\(\d\+\):\(\d\+\):\(.*\)$]])
  if #m > 0 then
    return { filename = m[2], lnum = tonumber(m[3]), col = tonumber(m[4]), text = m[5] }
  end
  m = vim.fn.matchlist(line, [[^\(.\{-}\):\(\d\+\):\(.*\)$]])
  if #m > 0 then
    return { filename = m[2], lnum = tonumber(m[3]), col = 1, text = m[4] }
  end
  return nil
end

local function grep_accept(_, items)
  local found = {}
  for _, l in ipairs(items) do
    local it = grep_item(l)
    if it then
      found[#found + 1] = it
    end
  end
  if #found == 0 then
    return
  end
  if #found == 1 then
    vim.cmd("edit " .. vim.fn.fnameescape(found[1].filename))
    vim.fn.cursor(found[1].lnum, found[1].col)
  else
    vim.fn.setqflist({}, " ", { items = found, title = "Grep" })
    vim.cmd("copen")
    vim.cmd("cfirst")
  end
end

-- live grep: --disabled hands the query to grep instead of filtering, and
-- change:reload re-runs grep on every keystroke. {q} is the grep pattern; an
-- empty query is guarded so the list starts blank.
local function launch_grep(query)
  local tool = vim.fn.executable("ugrep") == 1 and "ugrep -RInk --ignore-files --color=never" or "grep -rIn"
  local reload = "[ -n {q} ] && " .. tool .. " -- {q} . 2>/dev/null || true"
  run({
    ["sink*"] = function(lines)
      finish("livegrep", lines, grep_accept)
    end,
    options = extend(extend(base_opts("livegrep", "LiveGrep> ", query, "alt-o"), preview_grep()), {
      "--disabled",
      "--delimiter",
      ":",
      "--nth",
      "1",
      "--header",
      "Alt-F: filter file  Alt-G: grep  Tab: → quickfix  Alt-O: prev  Ctrl-/: preview",
      "--bind",
      "start:reload:" .. reload,
      "--bind",
      "change:reload:" .. reload,
      -- alt-f: stop grepping, fuzzy-filter the current results by file path
      -- (field 1 via --nth); alt-g: back to grep mode.
      "--bind",
      "alt-f:unbind(change)+enable-search+change-prompt(File> )+clear-query",
      "--bind",
      "alt-g:rebind(change)+disable-search+change-prompt(LiveGrep> )+clear-query",
    }),
  })
end

launchers = {
  files = launch_files,
  gfiles = launch_gfiles,
  buffers = launch_buffers,
  livegrep = launch_grep,
}

vim.api.nvim_create_user_command("Files", function()
  open("files", "")
end, {})
vim.api.nvim_create_user_command("GFiles", function()
  open("gfiles", "")
end, {})
vim.api.nvim_create_user_command("Buffers", function()
  open("buffers", "")
end, {})
vim.api.nvim_create_user_command("LiveGrep", function(o)
  open("livegrep", o.args)
end, { nargs = "*" })

vim.keymap.set("n", "<leader>F", function()
  open("files", "")
end, { silent = true })
vim.keymap.set("n", "<leader>f", function()
  open("gfiles", "")
end, { silent = true })
vim.keymap.set("n", "<leader>b", function()
  open("buffers", "")
end, { silent = true })
-- <leader>/ empty, <leader>? seeds the word under the cursor
vim.keymap.set("n", "<leader>/", function()
  open("livegrep", "")
end, { silent = true })
vim.keymap.set("n", "<leader>?", function()
  open("livegrep", vim.fn.expand("<cword>"))
end, { silent = true })
vim.keymap.set("x", "<leader>/", function()
  vim.cmd('normal! "zy')
  open("livegrep", (vim.fn.getreg("z"):gsub("\n.*", "")))
end, { silent = true })
