vim9script

# Native git signs, buffer-based & async (gitgutter-style): diff the live buffer
# against the git index via `git diff --no-index` in a job, so signs stay correct
# even before saving. ]c/[c jump between hunks, ghp previews, ghu reverts.
# Depends on git + bash.

highlight default GitSignAdd    ctermfg=green  guifg=#00af5f
highlight default GitSignChange ctermfg=yellow guifg=#d7af00
highlight default GitSignDelete ctermfg=red    guifg=#d70000

sign_define('GitAdd',    {text: '▎', texthl: 'GitSignAdd',    numhl: 'GitSignAdd'})
sign_define('GitChange', {text: '▎', texthl: 'GitSignChange', numhl: 'GitSignChange'})
sign_define('GitDelete', {text: '▁', texthl: 'GitSignDelete', numhl: 'GitSignDelete'})

const GROUP = 'gitsigns'
# only diff tracked files: outside a repo (or for an untracked file) git show is
# empty and --no-index would mark every line added — so bail unless tracked.
const DIFF = 'git -C "$0" ls-files --error-unmatch -- "$1" >/dev/null 2>&1 || exit 0; git -C "$0" diff --no-color -U0 --no-index -- <(git -C "$0" show ":./$1" 2>/dev/null) "$2" 2>/dev/null || true'
var jobs: dict<job> = {}
var acc: dict<list<string>> = {}
var hunks: dict<list<dict<any>>> = {}

def Place(buf: number, tmp: string)
  delete(tmp)
  if !bufexists(buf)
    return
  endif
  sign_unplace(GROUP, {buffer: buf})
  var hs: list<dict<any>> = []
  var cur: dict<any> = {}
  for line in get(acc, buf, [])
    var m = matchlist(line, '^@@ -\d\+,\=\(\d*\) +\(\d\+\),\=\(\d*\) @@')
    if !empty(m)
      if !empty(cur)
        hs->add(cur)
      endif
      var new_start = str2nr(m[2])
      var new_cnt = m[3] == '' ? 1 : str2nr(m[3])
      cur = {
        new_start: new_start,
        new_cnt: new_cnt,
        old_cnt: m[1] == '' ? 1 : str2nr(m[1]),
        lnum: new_cnt == 0 ? max([1, new_start]) : new_start,
        old_lines: [],
        new_lines: [],
      }
    elseif !empty(cur)
      if line[0] == '-'
        cur.old_lines->add(strpart(line, 1))
      elseif line[0] == '+'
        cur.new_lines->add(strpart(line, 1))
      endif
    endif
  endfor
  if !empty(cur)
    hs->add(cur)
  endif
  for h in hs
    if h.new_cnt == 0
      sign_place(0, GROUP, 'GitDelete', buf, {lnum: h.lnum, priority: 10})
    else
      var name = h.old_cnt == 0 ? 'GitAdd' : 'GitChange'
      for l in range(h.new_start, h.new_start + h.new_cnt - 1)
        sign_place(0, GROUP, name, buf, {lnum: l, priority: 10})
      endfor
    endif
  endfor
  hunks[buf] = hs
enddef

def Refresh()
  if &buftype != '' || !filereadable(expand('%:p'))
    return
  endif
  var buf = bufnr('%')
  if jobs->has_key(buf) && job_status(jobs[buf]) == 'run'
    return
  endif
  var dir = expand('%:p:h')
  var name = expand('%:t')
  var tmp = tempname()
  writefile(getline(1, '$'), tmp)
  acc[buf] = []
  jobs[buf] = job_start(['bash', '-c', DIFF, dir, name, tmp], {
    out_cb: (ch, msg) => acc[buf]->add(msg),
    close_cb: (ch) => Place(buf, tmp),
  })
enddef

def HunkAt(cur: number): dict<any>
  for h in get(hunks, bufnr('%'), [])
    if h.new_cnt == 0 ? cur == h.lnum : (cur >= h.new_start && cur < h.new_start + h.new_cnt)
      return h
    endif
  endfor
  return {}
enddef

def NextHunk()
  if &diff
    normal! ]c
    return
  endif
  var hs = get(hunks, bufnr('%'), [])
  if empty(hs)
    return
  endif
  var cur = line('.')
  for h in hs
    if h.lnum > cur
      cursor(h.lnum, 1)
      return
    endif
  endfor
  cursor(hs[0].lnum, 1)
enddef

def PrevHunk()
  if &diff
    normal! [c
    return
  endif
  var hs = get(hunks, bufnr('%'), [])
  if empty(hs)
    return
  endif
  var cur = line('.')
  for h in reverse(copy(hs))
    if h.lnum < cur
      cursor(h.lnum, 1)
      return
    endif
  endfor
  cursor(hs[-1].lnum, 1)
enddef

def PreviewHunk()
  var h = HunkAt(line('.'))
  if empty(h)
    return
  endif
  var lines = mapnew(h.old_lines, (_, l) => '-' .. l) + mapnew(h.new_lines, (_, l) => '+' .. l)
  if empty(lines)
    return
  endif
  var id = popup_atcursor(lines, {padding: [0, 1, 0, 1], border: [1, 1, 1, 1], moved: 'any'})
  setbufvar(winbufnr(id), '&filetype', 'diff')
enddef

def UndoHunk()
  var h = HunkAt(line('.'))
  if empty(h)
    return
  endif
  if h.new_cnt > 0
    deletebufline('%', h.new_start, h.new_start + h.new_cnt - 1)
  endif
  if !empty(h.old_lines)
    appendbufline('%', h.new_cnt > 0 ? h.new_start - 1 : h.new_start, h.old_lines)
  endif
  cursor(h.lnum, 1)
  Refresh()
enddef

nnoremap <silent> ]c  <ScriptCmd>NextHunk()<CR>
nnoremap <silent> [c  <ScriptCmd>PrevHunk()<CR>
nnoremap <silent> ghp <ScriptCmd>PreviewHunk()<CR>
nnoremap <silent> ghu <ScriptCmd>UndoHunk()<CR>

augroup gitsigns
  autocmd!
  autocmd BufReadPost,BufWritePost,CursorHold,CursorHoldI,TextChanged,InsertLeave * Refresh()
augroup END
