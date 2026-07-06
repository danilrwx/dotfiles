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

# remember recent pickers so <leader>' reopens the last; pressing it again walks
# further back (so an accidental empty picker falls through to the previous one)
var history: list<func> = []
var ridx = -1
var resuming = false

def Remember(Picker: func)
  if resuming
    return
  endif
  add(history, Picker)
  if len(history) > 10
    history = history[-10 : ]
  endif
  ridx = -1
enddef

def Resume()
  if empty(history)
    return
  endif
  ridx = ridx < 0 ? len(history) - 1 : max([0, ridx - 1])
  resuming = true
  history[ridx]()
  resuming = false
enddef
nnoremap <silent> <leader>' <scriptcmd>Resume()<cr>

def Files()
  Remember(Files)
  fzf#run(fzf#wrap('files', {options: ['--multi', '--prompt', 'Files> ']}))
enddef
command! Files Files()
nnoremap <silent> <leader>F <scriptcmd>Files()<cr>

# --- extra commands built on fzf#run/fzf#wrap (no junegunn/fzf.vim needed) ---

def BufSink(lines: list<string>)
  # --expect puts the pressed key on line 1 ('' for Enter), selections follow
  if len(lines) < 2
    return
  endif
  var nums = lines[1 :]->mapnew((_, l) => str2nr(matchstr(l, '^\d\+')))
  if lines[0] == 'ctrl-d'
    execute 'bdelete ' .. join(nums)
  else
    execute 'buffer ' .. nums[0]
  endif
enddef

def Buffers()
  Remember(Buffers)
  var bufs = getbufinfo({buflisted: 1})
    ->filter((_, b) => !empty(b.name))
    ->mapnew((_, b) => printf("%d\t%s", b.bufnr, fnamemodify(b.name, ':~:.')))
  fzf#run(fzf#wrap({
    source: bufs,
    'sink*': BufSink,
    options: ['--multi', '--expect', 'ctrl-d',
      '--header', 'Enter: open   Ctrl-D: delete   Tab: select',
      '--prompt', 'Buffers> ', '--with-nth', '2..', '-d', "\t"],
  }))
enddef
command! Buffers Buffers()
nnoremap <silent> <leader>b <scriptcmd>Buffers()<cr>

def GFiles()
  Remember(GFiles)
  fzf#run(fzf#wrap('gfiles', {
    source: 'git ls-files --cached --others --exclude-standard',
    options: ['--multi', '--prompt', 'GFiles> '],
  }))
enddef
command! GFiles GFiles()
nnoremap <silent> <leader>f <scriptcmd>GFiles()<cr>

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
  Remember(() => Grep(q))
  # -F: search the text literally, so regex-special chars don't need escaping
  var cmd = executable('ugrep') ? 'ugrep -RInk -F -I --ignore-files --color=never -- '
    : 'grep -rIn -F -- '
  fzf#run(fzf#wrap({
    source: cmd .. shellescape(q),
    'sink*': GrepSink,
    options: ['--multi', '--header', 'Enter: open   Tab: select → quickfix',
      '--prompt', $'Grep({q})> ', '--delimiter', ':'],
  }))
enddef
def GrepVisual()
  Grep(getreg('z')->split("\n")->get(0, ''))
enddef

command! -nargs=* Grep Grep(<q-args>)
nnoremap <silent> <leader>/ <scriptcmd>Grep()<cr>
# "zy yanks the selection AND leaves visual mode, so fzf opens in normal mode
# (a <Cmd> map would stay in visual and swallow keys until you type)
xnoremap <silent> <leader>/ "zy<scriptcmd>GrepVisual()<cr>
