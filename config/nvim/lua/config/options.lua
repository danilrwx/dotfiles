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
vim.opt.undofile = true
vim.opt.list = false
vim.opt.showmode = true
vim.opt.cursorline = false
vim.opt.laststatus = 1
vim.opt.cmdheight = 1

vim.g.snacks_animate = false

vim.filetype.add({
  filename = {
    ["werf.inc.yaml"] = "helm",
  },
})

if vim.g.neovide then
  vim.g.neovide_input_macos_option_key_is_meta = "only_left"

  vim.o.guifont = "Iosevka Nerd Font:h16"

  vim.g.neovide_refresh_rate = 120
end
