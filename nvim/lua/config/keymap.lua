local map = require("config.remap").map
local nmap = require("config.remap").nmap
local vmap = require("config.remap").vmap
local noremap = require("config.remap").noremap
local vnoremap = require("config.remap").vnoremap
local nnoremap = require("config.remap").nnoremap

nnoremap("<expr> k", "(v:count == 0 ? 'gk' : 'k')")
nnoremap("<expr> j", "(v:count == 0 ? 'gj' : 'j')")
nnoremap("<expr> л", "(v:count == 0 ? 'gk' : 'k')")
nnoremap("<expr> о", "(v:count == 0 ? 'gj' : 'j')")

map("<C-k>", "<C-w><Up>")
map("<C-j>", "<C-w><Down>")
map("<C-l>", "<C-w><Right>")
map("<C-h>", "<C-w><Left>")

vmap("\"y", "\"*y")
nmap("\"y", "\"*y")
nmap("\"Y", "\"*Y")
nmap("\"p", "\"*p")
nmap("\"P", "\"*P")

nnoremap("gV", "`[v`]")

nnoremap("<leader>=", ":res +5<CR>")
nnoremap("<leader>-", ":res -5<CR>")
nnoremap("<leader>0", ":vertical res +5<CR>")
nnoremap("<leader>9", ":vertical res -5<CR>")

nnoremap("<leader>sc", ":noh<CR>")

-- Двигать линии с шифтом
noremap("J :m", "'>+1<CR>gv=gv")
vnoremap("K :m", "'<-2<CR>gv=gv")

noremap("<leader>h", ":<C-u>split<CR>")
noremap("<leader>v", ":<C-u>vsplit<CR>")

nmap("<leader>w", ":update<CR>")

map("<leader>vl", ":vsp $MYVIMRC<CR>")
map("<leader>vr", ":source $MYVIMRC<CR>")

vmap("gcc", "<plug>NERDCommenterToggle")
nmap("gcc", "<plug>NERDCommenterToggle")

nnoremap("<leader>ff", ":Format<CR>")

-- Ranger
nmap("<leader><leader>", ":RnvimrToggle<CR>")

-- Lazygit
nnoremap("<leader>gg", ":LazyGit<CR>")

-- Закрываем окрытый буфер
nmap("<leader>bq", ":bd<CR>")
nmap("<tab>", ":bn<CR>")

-- Spectre
nnoremap("<leader>S", ":lua require('spectre').open()<CR>")

nnoremap("<leader>sw", ":lua require('spectre').open_visual({select_word=true})<CR>")
vnoremap("<leader>s", ":lua require('spectre').open_visual()<CR>")
nnoremap("<leader>sp", "viw:lua require('spectre').open_file_search()<CR>")

-- Telescope
nnoremap("<leader>b", "<cmd>Telescope buffers<cr>")
nnoremap("<leader>sf", "<cmd>Telescope find_files<cr>")
nnoremap("<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<cr>")
nnoremap("<leader>sg", "<cmd>Telescope live_grep<cr>")
nnoremap("<leader>sd", "<cmd>Telescope diagnostics<cr>")
nnoremap("<leader>sc", "<cmd>Telescope git_commits<cr>")
nnoremap("<leader>sr", "<cmd>Telescope lsp_references<cr>")
nnoremap("<leader>so", "<cmd>Telescope lsp_document_symbols<cr>")
nnoremap("<leader>sa", "<cmd>Telescope lsp_range_code_actions<cr>")
nnoremap("<leader>sh", "<cmd>Telescope help_tags<cr>")
