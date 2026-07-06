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

# Unified picker framework with resumable state. Each picker has a name and a
# launcher(query). Every fzf runs with --print-query so the typed query comes
# back on the first output line; we stash it in `saved` and re-seed --query when
# the picker is reopened, so state (and, for live grep, the result) survives.
# History of picker names lets you cycle between them: <leader>'/<leader>" when
# fzf is closed, ctrl-o (an --expect key) from inside fzf. fzf cursor position
# and multi-selection are not restored — only the query.
var saved: dict<string> = {}
var launchers: dict<func> = {}
var history: list<string> = []
var ridx = -1
var resuming = false

def Open(name: string, query: string)
  if !resuming
    var i = index(history, name)
    if i >= 0
      remove(history, i)
    endif
    add(history, name)
    if len(history) > 10
      history = history[-10 : ]
    endif
    # point at the just-opened picker so the first Cycle steps to a neighbour
    ridx = len(history) - 1
  endif
  launchers[name](query)
enddef

def Cycle(step: number)
  if empty(history)
    return
  endif
  var n = len(history)
  ridx = ((ridx < 0 ? n - 1 : ridx) + step % n + n) % n
  var name = history[ridx]
  resuming = true
  Open(name, get(saved, name, ''))
  resuming = false
enddef
nnoremap <silent> <leader>' <scriptcmd>Cycle(-1)<cr>
nnoremap <silent> <leader>" <scriptcmd>Cycle(1)<cr>

# common sink: line 0 is the query (--print-query), line 1 the --expect key
# ('' for Enter), the rest the selection. Saves the query, routes ctrl-o to the
# picker ring, otherwise hands (key, items) to the picker's accept handler.
def Finish(name: string, lines: list<string>, OnAccept: func)
  if empty(lines)
    return
  endif
  saved[name] = lines[0]
  var key = get(lines, 1, '')
  if key == 'ctrl-o'
    Cycle(-1)
    return
  endif
  OnAccept(key, lines[2 : ])
enddef

def BaseOpts(prompt: string, query: string, expectKeys: string): list<string>
  return ['--print-query', '--multi', '--expect', expectKeys,
    '--query', query, '--prompt', prompt]
enddef

def OpenFiles(_: string, items: list<string>)
  for f in items
    execute 'edit ' .. fnameescape(f)
  endfor
enddef

def LaunchFiles(query: string)
  fzf#run({
    'sink*': (lines) => Finish('files', lines, OpenFiles),
    options: BaseOpts('Files> ', query, 'ctrl-o') + ['--header', 'Ctrl-O: prev'],
  })
enddef

def LaunchGFiles(query: string)
  fzf#run({
    source: 'git ls-files --cached --others --exclude-standard',
    'sink*': (lines) => Finish('gfiles', lines, OpenFiles),
    options: BaseOpts('GFiles> ', query, 'ctrl-o') + ['--header', 'Ctrl-O: prev'],
  })
enddef

def BufAccept(key: string, items: list<string>)
  var nums = items->mapnew((_, l) => str2nr(matchstr(l, '^\d\+')))
  if empty(nums)
    return
  endif
  if key == 'ctrl-d'
    execute 'bdelete ' .. join(nums)
  else
    execute 'buffer ' .. nums[0]
  endif
enddef

def LaunchBuffers(query: string)
  var bufs = getbufinfo({buflisted: 1})
    ->filter((_, b) => !empty(b.name))
    ->mapnew((_, b) => printf("%d\t%s", b.bufnr, fnamemodify(b.name, ':~:.')))
  fzf#run({
    source: bufs,
    'sink*': (lines) => Finish('buffers', lines, BufAccept),
    options: BaseOpts('Buffers> ', query, 'ctrl-d,ctrl-o') + ['--with-nth', '2..',
      '-d', "\t", '--header', 'Enter: open  Ctrl-D: delete  Tab: select  Ctrl-O: prev'],
  })
enddef

def GrepItem(line: string): dict<any>
  # ugrep gives file:line:col:text, grep gives file:line:text
  var m = matchlist(line, '^\(.\{-}\):\(\d\+\):\(\d\+\):\(.*\)$')
  if !empty(m)
    return {filename: m[1], lnum: str2nr(m[2]), col: str2nr(m[3]), text: m[4]}
  endif
  m = matchlist(line, '^\(.\{-}\):\(\d\+\):\(.*\)$')
  return empty(m) ? {} : {filename: m[1], lnum: str2nr(m[2]), col: 1, text: m[3]}
enddef

def GrepAccept(_: string, items: list<string>)
  var found = items->mapnew((_, l) => GrepItem(l))->filter((_, i) => !empty(i))
  if empty(found)
    return
  endif
  if len(found) == 1
    execute 'edit ' .. fnameescape(found[0].filename)
    cursor(found[0].lnum, found[0].col)
  else
    setqflist([], ' ', {items: found, title: 'Grep'})
    copen
    cfirst
  endif
enddef

# live grep: --disabled hands the query to grep instead of filtering, and
# change:reload re-runs grep on every keystroke. {q} is the grep pattern (a
# regex); an empty query is guarded so the list starts blank.
def LaunchGrep(query: string)
  var tool = executable('ugrep') ? 'ugrep -RInk --ignore-files --color=never'
    : 'grep -rIn'
  var reload = $'[ -n {{q}} ] && {tool} -- {{q}} . 2>/dev/null || true'
  fzf#run({
    'sink*': (lines) => Finish('livegrep', lines, GrepAccept),
    options: BaseOpts('LiveGrep> ', query, 'ctrl-o') + ['--disabled',
      '--delimiter', ':',
      '--header', 'type to search  Enter: open  Tab: → quickfix  Ctrl-O: prev',
      '--bind', 'start:reload:' .. reload,
      '--bind', 'change:reload:' .. reload],
  })
enddef

launchers = {
  files: LaunchFiles,
  gfiles: LaunchGFiles,
  buffers: LaunchBuffers,
  livegrep: LaunchGrep,
}

command! Files Open('files', '')
command! GFiles Open('gfiles', '')
command! Buffers Open('buffers', '')
command! -nargs=* LiveGrep Open('livegrep', <q-args>)

nnoremap <silent> <leader>F <scriptcmd>Open('files', '')<cr>
nnoremap <silent> <leader>f <scriptcmd>Open('gfiles', '')<cr>
nnoremap <silent> <leader>b <scriptcmd>Open('buffers', '')<cr>
# <leader>/ empty, <leader>? seeds the word under the cursor
nnoremap <silent> <leader>/ <scriptcmd>Open('livegrep', '')<cr>
nnoremap <silent> <leader>? <scriptcmd>Open('livegrep', expand('<cword>'))<cr>
# "zy yanks the selection AND leaves visual mode, so fzf opens in normal mode
# (a <Cmd> map would stay in visual and swallow keys until you type)
xnoremap <silent> <leader>/ "zy<scriptcmd>Open('livegrep', getreg('z')->split("\n")->get(0, ''))<cr>
