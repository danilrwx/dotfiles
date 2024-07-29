local langmap_keys = {
  'ёЁ;`~', '№;#',
  'йЙ;qQ', 'цЦ;wW', 'уУ;eE', 'кК;rR', 'еЕ;tT', 'нН;yY', 'гГ;uU', 'шШ;iI', 'щЩ;oO', 'зЗ;pP', 'хХ;[{', 'ъЪ;]}',
  'фФ;aA', 'ыЫ;sS', 'вВ;dD', 'аА;fF', 'пП;gG', 'рР;hH', 'оО;jJ', 'лЛ;kK', 'дД;lL', [[жЖ;\;:]], [[эЭ;'\"]],
  'яЯ;zZ', 'чЧ;xX', 'сС;cC', 'мМ;vV', 'иИ;bB', 'тТ;nN', 'ьЬ;mM', [[бБ;\,<]], 'юЮ;.>',
}
vim.o.langmap = table.concat(langmap_keys, ',')

vim.keymap.set('n', '<Esc>', ':noh<Return><Esc>', { desc = 'Hide highlights by Esc' })
vim.keymap.set('n', '<C-t>', ':!topen-bash<Return><Esc>', { desc = 'Open new tmux page by C-t' })
vim.keymap.set('n', '<A-q>', ':bd<CR>', { desc = 'Close buffer by A-q' })

vim.keymap.set('n', '<C-s>', "<cmd>w<cr><esc>", { desc = 'Save buffer by C-s' })

vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = 'Center view after paging' })
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = 'Center view after paging' })

vim.keymap.set("i", "<C-c>", "<Esc>", { desc = 'Escape from insert mode' })

vim.keymap.set("n", "<Leader>e", [[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
  { desc = 'Change word by cursor over all buffer' })

-- greatest remap ever
vim.keymap.set("x", "<Leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<Leader>y", [["+y]])
vim.keymap.set("n", "<Leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<eader>d", [["_d]])

vim.keymap.set("n", "<C-j>", "<cmd>cnext<CR>zz")
vim.keymap.set("n", "<C-k>", "<cmd>cprev<CR>zz")
vim.keymap.set("n", "<Leader>j", "<cmd>lnext<CR>zz")
vim.keymap.set("n", "<Leader>k", "<cmd>lprev<CR>zz")

vim.keymap.set("n", "<Leader>tl", "<cmd>tabnext<CR>")
vim.keymap.set("n", "<Leader>th", "<cmd>tabprev<CR>")
vim.keymap.set("n", "<Leader>tn", "<cmd>tabnew<CR>")
vim.keymap.set("n", "<Leader>tc", "<cmd>tabclose<CR>")

vim.keymap.set("n", "<Leader>q", Funcs.toggle_quickfix)
