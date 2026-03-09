local M = {}

local function is_git_file()
  local file = vim.fn.expand("%")
  if file == "" then
    return false
  end
  local path = vim.fn.expand("%:p")
  if vim.fn.filereadable(path) == 0 then
    return false
  end
  vim.fn.system("git rev-parse --is-inside-work-tree 2> /dev/null")
  if vim.v.shell_error ~= 0 then
    return false
  end
  vim.fn.system("git ls-files --error-unmatch " .. vim.fn.shellescape(path) .. " 2> /dev/null")
  return vim.v.shell_error == 0
end

function M.setup()
  vim.fn.sign_define("GitAdded", { text = "+", texthl = "Added" })
  vim.fn.sign_define("GitRemoved", { text = "-", texthl = "Removed" })
  vim.fn.sign_define("GitChanged", { text = "~", texthl = "Changed" })

  vim.api.nvim_create_augroup("GitDiffSigns", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
    group = "GitDiffSigns",
    callback = function()
      if vim.bo.buftype == "" then
        M.update()
      end
    end,
  })
end

function M.update()
  if not is_git_file() then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.fn.sign_unplace("*", { buffer = bufnr })

  local path = vim.fn.expand("%:p")
  local diff = vim.fn.systemlist("git diff --no-color -- " .. vim.fn.shellescape(path))
  if vim.v.shell_error ~= 0 then
    return
  end

  local lnum = 0
  local id = 1000
  local removals = {}

  for _, line in ipairs(diff) do
    if line:match("^@@") then
      local start_str, count_str = line:match("^@@ %-%d+,?%d* %+(%d+),?(%d*) @@")
      if start_str then
        lnum = tonumber(start_str) - 1
      end
      removals = {}
    elseif line:match("^-") then
      table.insert(removals, true)
    elseif line:match("^%+") then
      lnum = lnum + 1
      if #removals > 0 then
        vim.fn.sign_place(id, "", "GitChanged", bufnr, { lnum = lnum })
        id = id + 1
        table.remove(removals, 1)
      else
        vim.fn.sign_place(id, "", "GitAdded", bufnr, { lnum = lnum })
        id = id + 1
      end
    elseif line:match("^ ") then
      for _ = 1, #removals do
        lnum = lnum + 1
        vim.fn.sign_place(id, "", "GitRemoved", bufnr, { lnum = lnum })
        id = id + 1
      end
      if #removals == 0 then
        lnum = lnum + 1
      end
      removals = {}
    end
  end

  if #removals > 0 then
    vim.fn.sign_place(id, "", "GitRemoved", bufnr, { lnum = lnum })
  end
end

local function get_hunks()
  if not is_git_file() then
    return {}
  end

  local bufnr = vim.api.nvim_get_current_buf()
  local result = vim.fn.sign_getplaced(bufnr, { group = "*" })
  if not result[1] or not result[1].signs or #result[1].signs == 0 then
    return {}
  end

  local lines = {}
  for _, sign in ipairs(result[1].signs) do
    table.insert(lines, tonumber(sign.lnum) or sign.lnum)
  end
  table.sort(lines, function(a, b)
    return a < b
  end)
  -- Deduplicate: one line can have multiple signs
  local unique = {}
  for i, l in ipairs(lines) do
    if i == 1 or l ~= lines[i - 1] then
      table.insert(unique, l)
    end
  end
  lines = unique

  local hunks = {}
  local hunk = {}

  for i, line in ipairs(lines) do
    if i == 1 or line == lines[i - 1] + 1 then
      table.insert(hunk, line)
    else
      table.insert(hunks, hunk)
      hunk = { line }
    end
  end
  if #hunk > 0 then
    table.insert(hunks, hunk)
  end

  return hunks
end

function M.next_hunk()
  local hunks = get_hunks()
  local current = tonumber(vim.fn.line(".")) or 1
  for _, group in ipairs(hunks) do
    if group[1] > current then
      vim.api.nvim_win_set_cursor(0, { group[1], 0 })
      return
    end
  end
  vim.notify("No next hunk", vim.log.levels.INFO)
end

function M.prev_hunk()
  local hunks = get_hunks()
  local current = tonumber(vim.fn.line(".")) or 1
  for i = #hunks, 1, -1 do
    local group = hunks[i]
    if group[1] < current then
      vim.api.nvim_win_set_cursor(0, { group[1], 0 })
      return
    end
  end
  vim.notify("No previous hunk", vim.log.levels.INFO)
end

return M
