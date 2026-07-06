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

def GrepItem(line: string): dict<any>
  # ugrep gives file:line:col:text, grep gives file:line:text
  var m = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\):\(.*\)$')
  if !empty(m)
    return {filename: m[1], lnum: str2nr(m[2]), col: str2nr(m[3]), text: m[4]}
  endif
  m = matchlist(line, '^\(.\{-}\):\(\d\+\):\(.*\)$')
  return empty(m) ? {} : {filename: m[1], lnum: str2nr(m[2]), col: 1, text: m[3]}
enddef

def GrepSink(lines: list<string>)
  var items = lines->mapnew((_, l) => GrepItem(l))->filter((_, i) => !empty(i))
  if empty(items)
    return
  endif
  if len(items) == 1
    execute 'edit ' .. fnameescape(items[0].filename)
    cursor(items[0].lnum, items[0].col)
  else
    setqflist([], ' ', {items: items, title: 'Grep'})
    copen
    cfirst
  endif
enddef

def Grep(query: string = '')
  var q = empty(query) ? expand('<cword>') : query
  if empty(q)
    return
  endif
  # -F: search the text literally, so regex-special chars don't need escaping
  var cmd = executable('ugrep') ? 'ugrep -RInk -F -I --ignore-files --color=never -- '
    : 'grep -rIn -F -- '
  fzf#run(fzf#wrap({
    source: cmd .. shellescape(q),
    'sink*': GrepSink,
    options: ['--multi', '--prompt', $'Grep({q})> ', '--delimiter', ':'],
  }))
enddef
def GrepVisual()
  Grep(getreg('z')->split("\n")->get(0, ''))
enddef

command! -nargs=* Grep Grep(<q-args>)
nnoremap <silent> <leader>g <scriptcmd>Grep()<cr>
# "zy yanks the selection AND leaves visual mode, so fzf opens in normal mode
# (a <Cmd> map would stay in visual and swallow keys until you type)
xnoremap <silent> <leader>g "zy<scriptcmd>GrepVisual()<cr>
