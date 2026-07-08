-- SEARCH: fuzzy matching and result parsing. Pure functions — no UI, no state.
local M = {}

-- Subsequence match: byte positions of each query char, in order, or nil.
function M.match_pos(sl, ql)
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

-- Rank matches like mini.pick: minimise span width (last-first), then start.
function M.fuzzy(cands, q)
  if q == "" then
    return cands
  end
  local ql = q:lower()
  local scored = {}
  for _, s in ipairs(cands) do
    local pos = M.match_pos(s:lower(), ql)
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

-- Grep hit -> {file, lnum} (ugrep: f:l:c:txt, grep: f:l:txt).
function M.grep_parse(line)
  local f, l = line:match("^(.-):(%d+):%d+:")
  if not f then
    f, l = line:match("^(.-):(%d+):")
  end
  return { file = f, lnum = l and tonumber(l) }
end

return M
