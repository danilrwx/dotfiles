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

-- Case-insensitive subsequence match: 0-based byte columns, or nil if no match.
function M.subseq_pos(s, pat)
  s, pat = s:lower(), pat:lower()
  local cols, si = {}, 1
  for i = 1, #pat do
    local f = s:find(pat:sub(i, i), si, true)
    if not f then
      return nil
    end
    cols[#cols + 1] = f - 1
    si = f + 1
  end

  return cols
end

function M.subseq(s, pat)
  return M.subseq_pos(s, pat) ~= nil
end

-- 0-based byte columns of every literal occurrence of sub in s (each matched
-- byte), case-insensitive. Empty sub -> no columns.
function M.find_all(s, sub)
  if sub == "" then
    return {}
  end

  s, sub = s:lower(), sub:lower()
  local cols, si = {}, 1
  while true do
    local a, b = s:find(sub, si, true)
    if not a then
      break
    end
    for c = a, b do
      cols[#cols + 1] = c - 1
    end
    si = b + 1
  end

  return cols
end

-- Grep hit -> {file, lnum, col} (ugrep: f:l:c:txt, grep: f:l:txt).
function M.grep_parse(line)
  local f, l, c = line:match("^(.-):(%d+):(%d+):")
  if not f then
    f, l = line:match("^(.-):(%d+):")
  end

  return { file = f, lnum = l and tonumber(l), col = c and tonumber(c) }
end

return M
