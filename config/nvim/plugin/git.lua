-- Git history/blame keymaps & commands. Logic in lua/git.lua.
local git = require("git")

git.setup_current_line() -- always-on current-line blame

-- the picker-backed views (commits/status/file_history) are launchers, reachable
-- via `:Picker git_commits|git_status|git_file_history`; only the non-picker git
-- actions get their own commands below.
vim.api.nvim_create_user_command("GitFileLog", git.file_log, {})
vim.api.nvim_create_user_command("GitBlameLine", git.blame_line, {})
vim.api.nvim_create_user_command("GitBlame", git.blame_toggle, {})
vim.api.nvim_create_user_command("GitLineBlameToggle", git.line_blame_toggle, {})
vim.api.nvim_create_user_command("GitOpenPR", git.open_pr_at, {})

vim.keymap.set("n", "<leader>gc", git.commits, { silent = true }) -- picker: repo log
vim.keymap.set("n", "<leader>gs", git.status, { silent = true }) -- picker: git status
vim.keymap.set("n", "<leader>gf", git.file_history, { silent = true }) -- picker: file commits
vim.keymap.set("n", "<leader>gl", git.file_log, { silent = true }) -- fugitive-style file log (patches)

vim.keymap.set("n", "ghb", git.blame_line, { silent = true }) -- detailed blame float for the line
vim.keymap.set("n", "ghB", git.blame_toggle, { silent = true }) -- toggle full-file blame
vim.keymap.set("n", "gho", git.open_pr_at, { silent = true }) -- open the line's/commit's PR/MR
