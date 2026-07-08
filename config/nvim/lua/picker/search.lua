-- SEARCH: fuzzy matching and result parsing. Pure functions — no UI, no state.
local M = {}

-- Fuzzy filter via the builtin (C) matchfuzzypos: fast even on big lists, ranked
-- best-first. Returns the matched candidates and, per match, the 0-based byte
-- columns that matched (for the UI to highlight). Empty query = all, no columns.
function M.fuzzy(cands, q)
  if q == "" then
    return cands, nil
  end
  local m = vim.fn.matchfuzzypos(cands, q)
  return m[1], m[2]
end

-- Grep hit -> {file, lnum} (ugrep: f:l:c:txt, grep: f:l:txt).
function M.grep_parse(line)
  local f, l = line:match("^(.-):(%d+):%d+:")
  if not f then
    f, l = line:match("^(.-):(%d+):")
  end
  return { file = f, lnum = l and tonumber(l) }
end

return M
