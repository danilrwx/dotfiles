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

vim.o.langmap = table.concat(langmap_keys, ",")
vim.o.laststatus = 1
vim.o.cmdheight = 1
vim.o.list = false
vim.o.showmode = true
vim.o.cursorline = false
vim.o.colorcolumn = "120"

vim.g.lazyvim_picker = "fzf"
