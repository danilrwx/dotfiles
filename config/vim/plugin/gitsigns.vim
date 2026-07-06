vim9script

# Native git signs, buffer-based & async (gitgutter-style): diff the live buffer
# against the git index via `git diff --no-index` in a job. Signs stay correct
# even before saving. Depends on git + bash (process substitution).

highlight default GitSignAdd    ctermfg=green  guifg=#00af5f
highlight default GitSignChange ctermfg=yellow guifg=#d7af00
highlight default GitSignDelete ctermfg=red    guifg=#d70000

sign_define('GitAdd',    {text: '▎', texthl: 'GitSignAdd'})
sign_define('GitChange', {text: '▎', texthl: 'GitSignChange'})
sign_define('GitDelete', {text: '▁', texthl: 'GitSignDelete'})

const GROUP = 'gitsigns'
const DIFF = 'git -C "$0" diff --no-color -U0 --no-index -- <(git -C "$0" show ":./$1" 2>/dev/null) "$2" 2>/dev/null || true'
var jobs: dict<job> = {}
var acc: dict<list<string>> = {}

def Place(buf: number, tmp: string)
  delete(tmp)
  if !bufexists(buf)
    return
  endif
  sign_unplace(GROUP, {buffer: buf})
  for line in get(acc, buf, [])
    var m = matchlist(line, '^@@ -\d\+,\=\(\d*\) +\(\d\+\),\=\(\d*\) @@')
    if empty(m)
      continue
    endif
    var old_cnt = m[1] == '' ? 1 : str2nr(m[1])
    var new_start = str2nr(m[2])
    var new_cnt = m[3] == '' ? 1 : str2nr(m[3])
    if new_cnt == 0
      sign_place(0, GROUP, 'GitDelete', buf, {lnum: max([1, new_start]), priority: 10})
    else
      var name = old_cnt == 0 ? 'GitAdd' : 'GitChange'
      for l in range(new_start, new_start + new_cnt - 1)
        sign_place(0, GROUP, name, buf, {lnum: l, priority: 10})
      endfor
    endif
  endfor
enddef

def Refresh()
  if &buftype != '' || empty(expand('%'))
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

augroup gitsigns
  autocmd!
  autocmd BufReadPost,BufWritePost,CursorHold,CursorHoldI,TextChanged,InsertLeave * Refresh()
augroup END
