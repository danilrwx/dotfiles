vim9script

# oil-mini: edit a directory as a buffer. :w applies renames/creates/copies/
# deletes, subpaths included (mkdir -p). <CR> opens the entry, - goes up.
# Each line is `name<TAB><id>` with the <TAB><id> concealed at the end, so the
# name sits at column 1 and edits normally. A session-global registry maps id to
# absolute path. Rules: an entry of THIS dir with a changed name is a rename
# (a name like ../x or sub/x moves it); a duplicated line is a copy; a line whose
# id belongs to ANOTHER dir (pasted in) is a copy in; a line with no id is a new
# file; an id gone from its dir is a deletion. All confirmed. `cp` for copies.

var registry: dict<string> = {}   # id -> absolute path
var seq = 0

def Parse(l: string): list<string>
  # -> [name, id] for an entry line, [] for a create line
  var m = matchlist(l, '^\(.*\)\t\(\d\+\)$')
  return (!empty(m) && registry->has_key(m[2])) ? [m[1], m[2]] : []
enddef

def Render()
  b:oil_reg = {}
  var lines: list<string> = []
  for name in readdir(b:oil_dir)->sort()
    var full = simplify(b:oil_dir .. name)
    seq += 1
    var id = printf('%d', seq)
    registry[id] = full
    var disp = name .. (isdirectory(full) ? '/' : '')
    b:oil_reg[id] = disp
    lines->add(disp .. "\t" .. id)
  endfor
  silent keepjumps deletebufline('%', 1, '$')
  if !empty(lines)
    setline(1, lines)
  endif
  setlocal nomodified
enddef

def Mkparent(p: string)
  var d = fnamemodify(p, ':h')
  if !isdirectory(d)
    mkdir(d, 'p')
  endif
enddef

def CopyPath(src: string, dst: string): number
  system('cp -Rp -- ' .. shellescape(src) .. ' ' .. shellescape(dst))
  return v:shell_error
enddef

def Rel(dir: string, p: string): string
  return stridx(p, dir) == 0 ? strpart(p, len(dir)) : p
enddef

def Apply(): bool
  var dir = b:oil_dir
  var reg = b:oil_reg
  var byid: dict<list<string>> = {}
  var creates: list<string> = []
  for l in getline(1, '$')->filter((_, v) => v !~ '^\s*$')
    var p = Parse(l)
    if empty(p)
      creates->add(matchstr(l, '^\%(.*\ze\t\d\+$\|.*\)'))
    else
      byid[p[1]] = add(get(byid, p[1], []), p[0])
    endif
  endfor

  var renames: list<list<string>> = []
  var copies: list<list<string>> = []
  for [id, names] in items(byid)
    var src = registry[id]
    var targets = names->mapnew((_, nm) => simplify(dir .. trim(nm, '/', 2)))
    if !reg->has_key(id)
      # pasted from another dir -> copy in, never touch the foreign source
      for t in targets
        copies->add([src, t])
      endfor
    elseif index(targets, src) >= 0
      for t in targets
        if t != src
          copies->add([src, t])
        endif
      endfor
    else
      renames->add([src, targets[0]])
      for t in targets[1 : ]
        copies->add([src, t])
      endfor
    endif
  endfor

  var deletes: list<string> = []
  for [id, disp] in items(reg)
    if !byid->has_key(id)
      deletes->add(registry[id])
    endif
  endfor

  if empty(renames) && empty(copies) && empty(creates) && empty(deletes)
    return true
  endif

  var summary: list<string> = []
  for [src, dst] in renames
    summary->add($'rename  {Rel(dir, src)} → {Rel(dir, dst)}')
  endfor
  for [src, dst] in copies
    summary->add($'copy    {Rel(dir, src)} → {Rel(dir, dst)}')
  endfor
  for name in creates
    summary->add($'create  {name}')
  endfor
  for full in deletes
    summary->add($'delete  {Rel(dir, full)}')
  endfor
  if confirm("Apply changes?\n" .. join(summary, "\n"), "&Yes\n&No", 2) != 1
    return false
  endif

  var errors: list<string> = []

  var tcount: dict<number> = {}
  for [src, dst] in renames
    tcount[dst] = get(tcount, dst, 0) + 1
  endfor
  for [src, dst] in copies
    tcount[dst] = get(tcount, dst, 0) + 1
  endfor

  for [src, dst] in copies
    if tcount[dst] > 1
      errors->add($'copy skipped, name used twice: {Rel(dir, dst)}')
      continue
    endif
    if filereadable(dst) || isdirectory(dst)
      errors->add($'copy skipped, exists: {Rel(dir, dst)}')
      continue
    endif
    Mkparent(dst)
    if CopyPath(src, dst) != 0
      errors->add($'copy failed: {Rel(dir, src)} → {Rel(dir, dst)}')
    endif
  endfor

  # renames in two phases via temp names so swaps/cycles and cross-dir moves work
  # ponytail: temp is .oil-tmp-N in dir; a real file of that name would clash.
  var vacated: dict<bool> = {}
  for [src, dst] in renames
    vacated[src] = true
  endfor
  for full in deletes
    vacated[full] = true
  endfor
  var pending: list<list<string>> = []
  var ti = 0
  for [src, dst] in renames
    if tcount[dst] > 1
      errors->add($'rename skipped, name used twice: {Rel(dir, dst)}')
      continue
    endif
    if (filereadable(dst) || isdirectory(dst)) && !vacated->has_key(dst)
      errors->add($'rename skipped, exists: {Rel(dir, dst)}')
      continue
    endif
    ti += 1
    var tmp = simplify(dir .. printf('.oil-tmp-%d', ti))
    if rename(src, tmp) != 0
      errors->add($'rename failed: {Rel(dir, src)} → {Rel(dir, dst)}')
      continue
    endif
    pending->add([tmp, dst])
  endfor
  for [tmp, dst] in pending
    Mkparent(dst)
    if rename(tmp, dst) != 0
      errors->add($'rename failed → {Rel(dir, dst)}')
    endif
  endfor

  for name in creates
    var dst = simplify(dir .. name)
    if filereadable(dst) || isdirectory(dst)
      continue
    endif
    try
      Mkparent(dst)
      if name =~ '/$'
        mkdir(dst, 'p')
      else
        writefile([], dst)
      endif
    catch
      errors->add($'create failed: {name}')
    endtry
  endfor

  for full in deletes
    if delete(full, isdirectory(full) ? 'rf' : '') != 0
      errors->add($'delete failed: {Rel(dir, full)}')
    endif
  endfor

  if !empty(errors)
    echohl WarningMsg
    for e in errors
      echom 'oil: ' .. e
    endfor
    echohl None
  endif
  return true
enddef

def Enter()
  var p = Parse(getline('.'))
  if empty(p)
    return
  endif
  setlocal nomodified
  var full = registry[p[1]]
  if isdirectory(full)
    Open(full .. '/')
  else
    execute 'edit ' .. fnameescape(full)
  endif
enddef

def Up()
  setlocal nomodified
  Open(fnamemodify(trim(b:oil_dir, '/', 2), ':h') .. '/')
enddef

def Focus(name: string)
  if empty(name)
    return
  endif
  for lnum in range(1, line('$'))
    var p = Parse(getline(lnum))
    if !empty(p) && (p[0] == name || p[0] == name .. '/')
      cursor(lnum, 1)
      return
    endif
  endfor
enddef

# cc/S would wipe the hidden id suffix (turning a rename into delete+create);
# keep the suffix and clear only the name so the edit stays a rename.
def RenameLine()
  var m = matchlist(getline('.'), '\t\(\d\+\)$')
  setline('.', empty(m) ? '' : "\t" .. m[1])
  cursor(line('.'), 1)
  startinsert
enddef

def OnWrite()
  if Apply()
    Render()
  endif
enddef

export def Open(path = '')
  var d = fnamemodify(empty(path) ? expand('%:p:h') : path, ':p')
  if !isdirectory(d)
    return
  endif
  var leaving = exists('b:oil_dir') ? fnamemodify(trim(b:oil_dir, '/', 2), ':t') : expand('%:t')
  # 'oil:' not 'oil://' — a :// name is hijacked by netrw's URL handler
  execute 'silent edit ' .. fnameescape('oil:' .. d)
  b:oil_dir = d
  setlocal buftype=acwrite noswapfile bufhidden=wipe
  setlocal conceallevel=3 concealcursor=nvic
  syntax clear
  syntax match oilId '\t\d\+$' conceal
  nnoremap <buffer> <silent> <CR> <ScriptCmd>Enter()<CR>
  nnoremap <buffer> <silent> -    <ScriptCmd>Up()<CR>
  nnoremap <buffer> <silent> cc   <ScriptCmd>RenameLine()<CR>
  nnoremap <buffer> <silent> S    <ScriptCmd>RenameLine()<CR>
  autocmd! BufWriteCmd <buffer>
  autocmd BufWriteCmd <buffer> OnWrite()
  Render()
  Focus(leaving)
enddef

command! -nargs=? -complete=dir Oil Open(<q-args>)
