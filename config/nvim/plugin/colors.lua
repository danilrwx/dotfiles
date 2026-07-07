vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.hl.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- trailing-whitespace highlight. matchadd is window-local, and fzf reuses the
-- window for its terminal, so always clear first (else the padded fzf header
-- stays highlighted red) and re-add only for normal file buffers.
local function ws_match()
  vim.fn.clearmatches()
  if vim.bo.buftype == "" then
    vim.fn.matchadd("ErrorMsg", [[\s\+$]])
  end
end
vim.api.nvim_create_autocmd({ "BufWinEnter", "TermOpen" }, { callback = ws_match })

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = function()
    local function hl(group, opts)
      vim.api.nvim_set_hl(0, group, opts)
    end

    vim.cmd("highlight Normal guibg=NONE")
    vim.cmd("highlight SignColumn guibg=NONE")

    hl("Added", { fg = "#00cd00" })
    hl("Changed", { fg = "#00cdcd" })
    hl("Removed", { fg = "#cd0000" })

    local keep = {
      ["Pmenu"] = "Normal",
      ["NormalFloat"] = "Normal",
      ["WinSeparator"] = "Normal",
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

    local function target_for(g)
      if keep[g] then
        return keep[g]
      end
      for k, target in pairs(keep) do
        if g:find("^" .. k:gsub("%.", "%%.") .. "%.") then
          return target
        end
      end
      return "Normal"
    end

    for _, g in ipairs(vim.fn.getcompletion("@", "highlight")) do
      hl(g, { link = target_for(g) })
    end
    for g, target in pairs(keep) do
      hl(g, { link = target })
    end
  end,
})

vim.cmd.colorscheme("torte")
