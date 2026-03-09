local M = {}

function M.git_status()
  vim.cmd("tab term git status")
end

function M.git_log_file_patch()
  local file = vim.fn.expand("%:p")
  if file == "" then return end
  vim.cmd("tab term git log --follow -p -- " .. vim.fn.shellescape(file))
end

function M.git_log_file()
  local file = vim.fn.expand("%:p")
  if file == "" then return end
  vim.cmd("tab term git log --follow -- " .. vim.fn.shellescape(file))
end

function M.git_blame()
  local file = vim.fn.expand("%:p")
  if file == "" then return end
  vim.cmd("vertical term git blame --date short -- " .. vim.fn.shellescape(file))
end

function M.highlight_yank()
  vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
end

function M.on_lsp_attach(event)
  local opts = { buffer = event.buf }
  local client = vim.lsp.get_client_by_id(event.data.client_id)
  if client == nil then return end

  if client.server_capabilities.codeLensProvider then
    vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold" }, {
      callback = function() vim.lsp.codelens.refresh() end,
    })
    vim.keymap.set("n", "grc", "<cmd>lua vim.lsp.codelens.run()<cr>", opts)
  end

  if client:supports_method("textDocument/formatting") then
    vim.keymap.set({ "n", "x" }, "grf", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
  end

  if client:supports_method("textDocument/completion") then
    vim.lsp.completion.enable(true, client.id, event.buf, { autotrigger = true })
  end
end

function M.on_filetype(details)
  if vim.treesitter.get_parser(nil, nil, { error = false }) then
    vim.treesitter.start()
  end

  local bufnr = details.buf
  vim.bo[bufnr].syntax = "on"
  vim.bo[bufnr].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

  vim.wo.foldlevel = 99
  vim.wo.foldmethod = "expr"
  vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
end

function M.toggle_quickfix()
  local quickfix_wins = vim.tbl_filter(function(win_id)
    return vim.fn.getwininfo(win_id)[1].quickfix == 1
  end, vim.api.nvim_tabpage_list_wins(0))

  local command = #quickfix_wins == 0 and "copen" or "cclose"
  vim.cmd(command)
end

function M.setup_highlights()
  local link = vim.api.nvim_set_hl
  local function hl(group, opts) link(0, group, opts) end

  hl("Normal", { bg = nil })
  hl("SignColumn", { bg = nil })

  hl("LineNr", { fg = "#7f7f7f" })
  hl("LineNrAbove", { fg = "#7f7f7f" })
  hl("LineNrBelow", { fg = "#7f7f7f" })

  hl("Added", { fg = "#00cd00" })
  hl("Changed", { fg = "#00cdcd" })
  hl("Removed", { fg = "#cd0000" })

  local highlight_keep = {
    ["@function"] = "Function",
    ["@function.call"] = "Function",
    ["@function.method.call"] = "Function",
    ["@function.builtin"] = "Normal",

    ["@method"] = "Function",
    ["@method.call"] = "Normal",

    ["@comment"] = "Comment",
    ["@string"] = "String",

    ["@keyword"] = "Keyword",

    ["@type"] = "Type",
    ["@type.builtin"] = "Type",
    ["@property.yaml"] = "Type",

    ["@markup.heading"] = "Keyword",
    ["@markup.raw"] = "String",
    ["@markup.link"] = "Type",
    ["@punctuation.special.markdown"] = "Type",
  }

  local function target_for(group)
    if highlight_keep[group] then
      return highlight_keep[group]
    end
    for keep, target in pairs(highlight_keep) do
      if group:find("^" .. keep:gsub("%.", "%%.") .. "%.") then
        return target
      end
    end
    return "Normal"
  end

  for _, g in ipairs(vim.fn.getcompletion("@", "highlight")) do
    hl(g, { link = target_for(g) })
  end

  for group, target in pairs(highlight_keep) do
    hl(group, { link = target })
  end
end

return M
