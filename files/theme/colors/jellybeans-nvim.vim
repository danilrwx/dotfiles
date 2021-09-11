set background=dark
let g:colors_name="jellybeans-nvim"

lua package.loaded['lush_theme.jellybeans-nvim'] = nil
lua require('lush')(require('lush_theme.jellybeans-nvim'))
