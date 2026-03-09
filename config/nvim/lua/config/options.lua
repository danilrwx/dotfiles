local langmap_keys = {
  "ёЁ;`~",
  "№;#",
  "йЙ;qQ",
  "цЦ;wW",
  "уУ;eE",
  "кК;rR",
  "еЕ;tT",
  "нН;yY",
  "гГ;uU",
  "шШ;iI",
  "щЩ;oO",
  "зЗ;pP",
  "хХ;[{",
  "ъЪ;]}",
  "фФ;aA",
  "ыЫ;sS",
  "вВ;dD",
  "аА;fF",
  "пП;gG",
  "рР;hH",
  "оО;jJ",
  "лЛ;kK",
  "дД;lL",
  [[жЖ;\;:]],
  [[эЭ;'\"]],
  "яЯ;zZ",
  "чЧ;xX",
  "сС;cC",
  "мМ;vV",
  "иИ;bB",
  "тТ;nN",
  "ьЬ;mM",
  [[бБ;\,<]],
  "юЮ;.>",
}

vim.opt.langmap = table.concat(langmap_keys, ",")
vim.opt.spelllang = "ru_ru,en_us"
vim.opt.undodir = os.getenv("HOME") .. "/.vim/undodir"
vim.opt.undofile = true
vim.opt.list = false
vim.opt.showmode = true
vim.opt.cursorline = false
vim.opt.laststatus = 1
vim.opt.cmdheight = 1
-- vim.opt.clipboard = ""
