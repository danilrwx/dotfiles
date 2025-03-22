local langmap_keys = {
  'ёЁ;`~', '№;#',
  'йЙ;qQ', 'цЦ;wW', 'уУ;eE', 'кК;rR', 'еЕ;tT', 'нН;yY', 'гГ;uU', 'шШ;iI', 'щЩ;oO', 'зЗ;pP', 'хХ;[{', 'ъЪ;]}',
  'фФ;aA', 'ыЫ;sS', 'вВ;dD', 'аА;fF', 'пП;gG', 'рР;hH', 'оО;jJ', 'лЛ;kK', 'дД;lL', [[жЖ;\;:]], [[эЭ;'\"]],
  'яЯ;zZ', 'чЧ;xX', 'сС;cC', 'мМ;vV', 'иИ;bB', 'тТ;nN', 'ьЬ;mM', [[бБ;\,<]], 'юЮ;.>',
}
vim.o.langmap = table.concat(langmap_keys, ',')

vim.keymap.set('n', '<esc>', ':noh<Return><esc>', { desc = 'Hide highlights by esc' })
vim.keymap.set('n', '<a-q>', ':bd<cr>', { desc = 'Close buffer by A-q' })

vim.keymap.set('n', '<c-s>', "<cmd>w<cr><esc>", { desc = 'Save buffer by C-s' })

vim.keymap.set("n", "<c-d>", "<C-d>zz", { desc = 'Center view after paging' })
vim.keymap.set("n", "<c-u>", "<C-u>zz", { desc = 'Center view after paging' })

vim.keymap.set("i", "<c-c>", "<esc>", { desc = 'Escape from insert mode' })

-- greatest remap ever
vim.keymap.set("x", "<leader>p", [["_dP]])

-- next greatest remap ever : asbjornHaland
vim.keymap.set({ "n", "v" }, "<leader>y", [["+y]])
vim.keymap.set("n", "<leader>Y", [["+Y]])

vim.keymap.set({ "n", "v" }, "<eader>d", [["_d]])

vim.keymap.set("n", "<c-j>", "<cmd>cnext<cr>zz")
vim.keymap.set("n", "<c-k>", "<cmd>cprev<cr>zz")
vim.keymap.set("n", "<leader>j", "<cmd>lnext<cr>zz")
vim.keymap.set("n", "<leader>k", "<cmd>lprev<cr>zz")

vim.keymap.set("n", "<c-t>l", "<cmd>tabnext<cr>")
vim.keymap.set("n", "<c-t>h", "<cmd>tabprev<cr>")
vim.keymap.set("n", "<c-t>n", "<cmd>tabnew<cr>")
vim.keymap.set("n", "<c-t>c", "<cmd>tabclose<cr>")

vim.keymap.set("n", "<leader>q", Funcs.toggle_quickfix)
