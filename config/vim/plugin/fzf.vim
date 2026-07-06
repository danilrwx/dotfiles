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

# remember recent pickers and cycle between them: <leader>' steps to the older
# one, <leader>" to the newer, both wrapping around. Reopening a picker moves it
# to the front (dedup), so the ring holds each distinct picker once.
var history: list<func> = []
var ridx = -1
var resuming = false

def Remember(Picker: func)
  if resuming
    return
  endif
  var i = indexof(history, (_, F) => F == Picker)
  if i >= 0
    remove(history, i)
  endif
  add(history, Picker)
  if len(history) > 10
    history = history[-10 : ]
  endif
  ridx = -1
enddef

def Cycle(step: number)
  if empty(history)
    return
  endif
  var n = len(history)
  ridx = ridx < 0 ? n - 1 : (ridx + step % n + n) % n
  resuming = true
  history[ridx]()
  resuming = false
enddef
nnoremap <silent> <leader>' <scriptcmd>Cycle(-1)<cr>
nnoremap <silent> <leader>" <scriptcmd>Cycle(1)<cr>

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

# live grep (fzf-lua style): --disabled hands the query to grep instead of
# filtering, and change:reload re-runs grep on every keystroke. {q} is the
# grep pattern (a regex); an empty query is guarded so the list starts blank.
def LiveGrep(query: string = '')
  var tool = executable('ugrep') ? 'ugrep -RInk --ignore-files --color=never'
    : 'grep -rIn'
  var reload = $'[ -n {{q}} ] && {tool} -- {{q}} . 2>/dev/null || true'
  Remember(() => LiveGrep(query))
  fzf#run(fzf#wrap({
    'sink*': GrepSink,
    options: ['--disabled', '--multi', '--delimiter', ':', '--query', query,
      '--prompt', 'LiveGrep> ',
      '--header', 'type to search   Enter: open   Tab: select → quickfix',
      '--bind', 'start:reload:' .. reload,
      '--bind', 'change:reload:' .. reload],
  }))
enddef
def LiveGrepVisual()
  LiveGrep(getreg('z')->split("\n")->get(0, ''))
enddef

command! -nargs=* LiveGrep LiveGrep(<q-args>)
# <leader>/ empty, <leader>? seeds the word under the cursor
nnoremap <silent> <leader>/ <scriptcmd>LiveGrep()<cr>
nnoremap <silent> <leader>? <scriptcmd>LiveGrep(expand('<cword>'))<cr>
# "zy yanks the selection AND leaves visual mode, so fzf opens in normal mode
# (a <Cmd> map would stay in visual and swallow keys until you type)
xnoremap <silent> <leader>/ "zy<scriptcmd>LiveGrepVisual()<cr>
