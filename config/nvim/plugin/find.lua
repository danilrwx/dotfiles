-- Native fuzzy file find: list files once, fuzzy-filter with matchfuzzy() via
-- the built-in 'findfunc'. Use `:find <fuzzy><Tab>` / <leader>e. Plus `:Grepq`
-- -> quickfix via 'grepprg', and a vim.ui.select buffer picker. No fzf.

local files_cache = {}
vim.api.nvim_create_autocmd("CmdlineEnter", {
  pattern = ":",
  callback = function()
    files_cache = {}
  end,
})

local function find_cmd()
  if vim.fn.executable("fd") == 1 then
    return "fd . --path-separator / --type f --hidden --follow --exclude .git"
  elseif vim.fn.executable("find") == 1 then
    return 'find . -type f -not -path "*/.git/*"'
  end
  return ""
end

function _G.__find(cmdarg, _)
  if #files_cache == 0 then
    local cmd = find_cmd()
    files_cache = {}
    if cmd == "" then
      for _, v in ipairs(vim.fn.globpath(".", "**", true, true)) do
        if vim.fn.isdirectory(v) == 0 then
          files_cache[#files_cache + 1] = v
        end
      end
    else
      for _, v in ipairs(vim.fn.systemlist(cmd)) do
        files_cache[#files_cache + 1] = (v:gsub("^%./", ""))
      end
    end
  end
  return cmdarg == "" and files_cache or vim.fn.matchfuzzy(files_cache, cmdarg)
end

vim.o.findfunc = "v:lua.__find"

-- fuzzy matches share no common prefix, so `longest` inserts nothing and the
-- typed query survives -- no full path auto-filled into the cmdline on <Tab>.
vim.o.wildmode = "longest:full"
vim.o.wildoptions = "pum"

vim.api.nvim_create_user_command("Grepq", function(o)
  local cmd = vim.o.grepprg .. " " .. o.args
  vim.fn.setqflist({}, " ", { title = cmd, lines = vim.fn.systemlist(cmd), efm = vim.o.grepformat })
  vim.cmd("belowright cwindow")
end, { nargs = "+", bar = true })

-- toggle the quickfix window (<leader>q): open sized to content, skip when empty
local function toggle_qf()
  local open = vim.tbl_filter(function(w)
    return w.quickfix == 1 and w.loclist == 0
  end, vim.fn.getwininfo())
  if #open > 0 then
    vim.cmd("cclose")
  elseif #vim.fn.getqflist() == 0 then
    vim.notify("quickfix is empty")
  else
    vim.cmd("botright copen " .. math.min(10, #vim.fn.getqflist()))
  end
end

-- files/buffers/grep pickers live in fzf.lua; :find keeps the native fuzzy find
vim.keymap.set("n", "<leader>e", ":find ", {})
vim.keymap.set("n", "<leader>q", toggle_qf, { silent = true })
