vim9script

# unimpaired-style bracket motions, mirroring Neovim 0.11's defaults.
# ]c/[c (git hunks, gitsigns) and ]d/[d (LSP diagnostics, lsp.vim) stay as-is.

# quickfix
nnoremap <silent> ]q <cmd>execute v:count1 .. 'cnext'<cr>
nnoremap <silent> [q <cmd>execute v:count1 .. 'cprevious'<cr>
nnoremap <silent> ]Q <cmd>clast<cr>
nnoremap <silent> [Q <cmd>cfirst<cr>

# location list
nnoremap <silent> ]l <cmd>execute v:count1 .. 'lnext'<cr>
nnoremap <silent> [l <cmd>execute v:count1 .. 'lprevious'<cr>
nnoremap <silent> ]L <cmd>llast<cr>
nnoremap <silent> [L <cmd>lfirst<cr>

# buffers
nnoremap <silent> ]b <cmd>execute v:count1 .. 'bnext'<cr>
nnoremap <silent> [b <cmd>execute v:count1 .. 'bprevious'<cr>
nnoremap <silent> ]B <cmd>blast<cr>
nnoremap <silent> [B <cmd>bfirst<cr>

# argument list
nnoremap <silent> ]a <cmd>execute v:count1 .. 'next'<cr>
nnoremap <silent> [a <cmd>execute v:count1 .. 'previous'<cr>

# tags
nnoremap <silent> ]t <cmd>execute v:count1 .. 'tnext'<cr>
nnoremap <silent> [t <cmd>execute v:count1 .. 'tprevious'<cr>

# blank lines around the cursor
nnoremap <silent> ]<space> <cmd>call append(line('.'), repeat([''], v:count1))<cr>
nnoremap <silent> [<space> <cmd>call append(line('.') - 1, repeat([''], v:count1))<bar>call cursor(line('.') + v:count1, col('.'))<cr>
