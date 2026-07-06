vim9script

# Make fzf's bundled base plugin (:FZF, fzf#run) available — from brew or apt,
# no clone. brew keeps it under <prefix>/plugin (add to rtp + source it); apt
# ships it as a standalone example file (source directly).
var loaded = false
for d in ['/opt/homebrew/opt/fzf', '/usr/local/opt/fzf', '/home/linuxbrew/.linuxbrew/opt/fzf', expand('~/.fzf')]
  if isdirectory(d)
    execute 'set runtimepath+=' .. d
    if filereadable(d .. '/plugin/fzf.vim')
      execute 'source ' .. d .. '/plugin/fzf.vim'
    endif
    loaded = true
    break
  endif
endfor
if !loaded
  for f in ['/usr/share/vim/vimfiles/plugin/fzf.vim', '/usr/share/doc/fzf/examples/fzf.vim']
    if filereadable(f)
      execute 'source ' .. f
      break
    endif
  endfor
endif

nnoremap <silent> <leader>f :FZF<cr>

# --- extra commands built on fzf#run/fzf#wrap (no junegunn/fzf.vim needed) ---

def BufSink(line: string)
  execute 'buffer ' .. matchstr(line, '^\d\+')
enddef

def Buffers()
  var bufs = getbufinfo({buflisted: 1})
    ->filter((_, b) => !empty(b.name))
    ->mapnew((_, b) => printf("%d\t%s", b.bufnr, fnamemodify(b.name, ':~:.')))
  fzf#run(fzf#wrap({
    source: bufs,
    sink: BufSink,
    options: ['--prompt', 'Buffers> ', '--with-nth', '2..', '-d', "\t"],
  }))
enddef
command! Buffers Buffers()
nnoremap <silent> <leader>b <scriptcmd>Buffers()<cr>

def GFiles()
  fzf#run(fzf#wrap({
    source: 'git ls-files --cached --others --exclude-standard',
    options: ['--prompt', 'GFiles> '],
  }))
enddef
command! GFiles GFiles()
nnoremap <silent> <leader>G <scriptcmd>GFiles()<cr>

def RgSink(line: string)
  var m = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\):')
  if empty(m)
    return
  endif
  execute 'edit ' .. fnameescape(m[1])
  cursor(str2nr(m[2]), str2nr(m[3]))
enddef

def Rg(query: string = '')
  var base = 'rg --column --line-number --no-heading --color=always --smart-case -- '
  fzf#run(fzf#wrap({
    source: base .. fzf#shellescape(query),
    sink: RgSink,
    options: ['--ansi', '--disabled', '--query', query, '--prompt', 'Rg> ',
              '--delimiter', ':', '--bind', 'change:reload:' .. base .. '{q} || true'],
  }))
enddef
command! -nargs=* Rg Rg(<q-args>)
nnoremap <silent> <leader>g <scriptcmd>Rg()<cr>
