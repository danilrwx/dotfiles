vim.cmd [[packadd packer.nvim]]

return require("packer").startup(function(Plug)
  -- Packer
  Plug "wbthomason/packer.nvim"

  -- Стартовый экран
  Plug "mhinz/vim-startify"

  -- Тема
  Plug "marko-cerovac/material.nvim"

  -- Нижняя панель
  Plug {
    "nvim-lualine/lualine.nvim",
    requires = { "kyazdani42/nvim-web-devicons", opt = true }
  }

  -- Добавляет end в конец блока
  Plug "tpope/vim-endwise"

  -- Переключение раскладки в insert
  Plug "rlue/vim-barbaric"

  -- Файловый менеджер
  Plug "kevinhwang91/rnvimr"

  -- Великий гит
  Plug "kdheepak/lazygit.nvim"
  Plug "tpope/vim-fugitive"
  Plug "lewis6991/gitsigns.nvim"

  -- LSP
  Plug "williamboman/nvim-lsp-installer"
  Plug "neovim/nvim-lspconfig"
  Plug "lukas-reineke/lsp-format.nvim"

  -- Автокомплит
  Plug { "ms-jpq/coq_nvim", run = "python3 -m coq deps" }
  Plug "ms-jpq/coq.artifacts"
  Plug "ms-jpq/coq.thirdparty"

  -- Приятные мелочи
  Plug "kosayoda/nvim-lightbulb"
  Plug "b0o/schemastore.nvim"
  Plug "ziontee113/syntax-tree-surfer"

  -- Подсветка синтаксиса
  Plug { "nvim-treesitter/nvim-treesitter", run = ":TSUpdate" }
  Plug "nvim-treesitter/nvim-treesitter-textobjects"
  Plug "windwp/nvim-ts-autotag"
  Plug "andymass/vim-matchup"
  Plug "JoosepAlviste/nvim-ts-context-commentstring"

  -- Для руби
  Plug "tpope/vim-rails"
  Plug "vim-ruby/vim-ruby"
  Plug "tpope/vim-bundler"
  Plug "slim-template/vim-slim"

  -- Для go
  Plug "ray-x/go.nvim"

  -- Парные теги
  Plug "windwp/nvim-autopairs"

  -- Подсветка парных тегов
  Plug "Valloric/MatchTagAlways"

  -- Работа с парными тегами
  Plug "kylechui/nvim-surround"

  -- Плавный скролл
  Plug "karb94/neoscroll.nvim"

  -- Подсветка отступов
  Plug "nathanaelkane/vim-indent-guides"

  -- Зависимости для popup плагинов
  Plug "nvim-lua/plenary.nvim"
  Plug "nvim-lua/popup.nvim"

  -- Поиск
  Plug "nvim-telescope/telescope.nvim"

  -- Найти и заменить
  Plug "windwp/nvim-spectre"

  -- Прозрачность
  Plug "xiyaowong/nvim-transparent"

  Plug "numToStr/Comment.nvim"

  -- Terminal
  Plug "s1n7ax/nvim-terminal"
end)
