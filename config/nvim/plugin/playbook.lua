-- Minimal playbook runner: in a playbook.sh buffer, <CR> sends the current line
-- (or the visual selection) to the neighbouring tmux pane and runs it. Depends
-- on tmux only.

local function send(lines)
  if not vim.env.TMUX or vim.env.TMUX == "" then
    vim.api.nvim_echo({ { "playbook: not inside tmux", "WarningMsg" } }, true, {})
    return
  end
  -- read the target each call (per-project g:playbook_target takes effect) and
  -- pass argv to vim.system — no shell, so the target can't inject.
  local target = vim.g.playbook_target or "{last}"
  for _, line in ipairs(lines) do
    if line:match("%S") then
      vim.system({ "tmux", "send-keys", "-t", target, "-l", "--", line }):wait()
      vim.system({ "tmux", "send-keys", "-t", target, "Enter" }):wait()
    end
  end
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = vim.api.nvim_create_augroup("playbook", { clear = true }),
  pattern = "playbook.sh",
  callback = function(ev)
    vim.keymap.set("n", "<CR>", function()
      send({ vim.api.nvim_get_current_line() })
      if vim.fn.line(".") >= vim.fn.line("$") then
        return
      end
      vim.cmd("normal! j")
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
