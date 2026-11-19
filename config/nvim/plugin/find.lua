-- Native :find completion, using fd's ignore rules when available.
local function files()
  local cmd = vim.fn.executable("fd") == 1 and { "fd", "--type", "f", "--print0" }
    or vim.fn.executable("fdfind") == 1 and { "fdfind", "--type", "f", "--print0" }
    or { "find", ".", "-name", ".git", "-prune", "-o", "-type", "f", "-print0" }
  local result = vim.system(cmd):wait()
  if result.code ~= 0 then
    vim.notify(result.stderr or "File search failed", vim.log.levels.ERROR)
    return {}
  end
  return vim.tbl_map(function(path) return (path:gsub("^%./", "")) end,
    vim.split(result.stdout or "", "\0", { plain = true, trimempty = true }))
end

function _G.native_find(text, completing)
  -- Opening an exact completion must not select a different fuzzy match.
  if not completing and vim.fn.filereadable(text) == 1 then
    return { text }
  end
  local candidates = files()
  return text == "" and candidates or vim.fn.matchfuzzy(candidates, text)
end

vim.o.findfunc = "v:lua.native_find"

vim.keymap.set("n", "<leader>f", ":find ")
vim.keymap.set("n", "<leader>F", ":find ")
vim.keymap.set("n", "<leader>b", ":ls<cr>:buffer ")
