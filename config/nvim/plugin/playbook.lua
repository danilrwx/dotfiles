-- Minimal playbook runner: in a playbook.sh buffer, <CR> sends the current line
-- (or the visual selection) to the neighbouring tmux pane and runs it. Depends
-- on tmux only.

local target = vim.g.playbook_target or "{last}"

local function send(lines)
  if not vim.env.TMUX or vim.env.TMUX == "" then
    vim.api.nvim_echo({ { "playbook: not inside tmux", "WarningMsg" } }, true, {})
    return
  end
  for _, line in ipairs(lines) do
    if line:match("%S") then
      vim.fn.system("tmux send-keys -t " .. target .. " -l -- " .. vim.fn.shellescape(line))
      vim.fn.system("tmux send-keys -t " .. target .. " Enter")
    end
  end
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "playbook.sh",
  callback = function(ev)
    vim.keymap.set("n", "<CR>", function()
      send({ vim.api.nvim_get_current_line() })
      if vim.fn.line(".") < vim.fn.line("$") then
        vim.cmd("normal! j")
      end
    end, { buffer = ev.buf, silent = true })

    vim.keymap.set("x", "<CR>", function()
      local s, e = vim.fn.line("v"), vim.fn.line(".")
      if s > e then
        s, e = e, s
      end
      send(vim.fn.getline(s, e))
      vim.api.nvim_input("<Esc>")
    end, { buffer = ev.buf, silent = true })
  end,
})
