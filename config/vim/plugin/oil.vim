vim9script

# oil-mini: edit a directory as a buffer. :w applies renames/creates/copies/
# deletes, subpaths included (mkdir -p). <CR> opens the entry, - goes up.
# Each line carries the entry's absolute path as a hidden (concealed) prefix, so
# identity is global: editing the name renames; duplicating a line copies; a
# line pasted from another oil dir moves the file here; a line with no prefix is
# a new entry; a prefix that vanished from its dir is a deletion. All confirmed.
# Depends on built-ins plus `cp` for copies.

def Render()
  b:oil_reg = {}
  var lines: list<string> = []
  for name in readdir(b:oil_dir)->sort()
    var full = simplify(b:oil_dir .. name)
    var disp = name .. (isdirectory(full) ? '/' : '')
    b:oil_reg[full] = disp
    lines->add(full .. "\t" .. disp)
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
  var byfull: dict<list<string>> = {}
  var creates: list<string> = []
  for l in getline(1, '$')->filter((_, v) => v !~ '^\s*$')
    var ti = stridx(l, "\t")
    if ti < 0
      creates->add(l)
    else
      var full = strpart(l, 0, ti)
      byfull[full] = add(get(byfull, full, []), strpart(l, ti + 1))
    endif
  endfor

  var renames: list<list<string>> = []
  var copies: list<list<string>> = []
  for [full, names] in items(byfull)
    var targets: list<string> = []
    for nm in names
      targets->add(simplify(dir .. trim(nm, '/', 2)))
    endfor
    if index(targets, full) >= 0
      for t in targets
        if t != full
          copies->add([full, t])
        endif
      endfor
    else
      renames->add([full, targets[0]])
      for t in targets[1 : ]
        copies->add([full, t])
      endfor
    endif
  endfor

  var deletes: list<string> = []
  for [full, disp] in items(reg)
    if !byfull->has_key(full)
      deletes->add(full)
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

  # a destination claimed more than once is skipped
  var tcount: dict<number> = {}
  for [src, dst] in renames
    tcount[dst] = get(tcount, dst, 0) + 1
  endfor
  for [src, dst] in copies
    tcount[dst] = get(tcount, dst, 0) + 1
  endfor

  # copies first, while sources are still in place
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

  # renames in two phases via temp names so swaps/cycles (a↔b) work: move every
  # source to a temp, then temps into their finals. Handles cross-dir moves too.
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
    if delete(full, reg[full] =~ '/$' ? 'rf' : '') != 0
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
  var l = getline('.')
  var ti = stridx(l, "\t")
  if ti < 0 || !Leave()
    return
  endif
  var full = strpart(l, 0, ti)
  if isdirectory(full)
    Open(full .. '/')
  else
    execute 'edit ' .. fnameescape(full)
  endif
enddef

def Up()
  if !Leave()
    return
  endif
  Open(fnamemodify(trim(b:oil_dir, '/', 2), ':h') .. '/')
enddef

def Focus(name: string)
  if empty(name)
    return
  endif
  for lnum in range(1, line('$'))
    var l = getline(lnum)
    var ti = stridx(l, "\t")
    if ti < 0
      continue
    endif
    var nm = strpart(l, ti + 1)
    if nm == name || nm == name .. '/'
      cursor(lnum, ti + 2)
      return
    endif
  endfor
enddef

# cc/S would wipe the hidden path prefix (turning a rename into delete+create);
# keep the prefix and clear only the name so the edit stays a rename.
def RenameLine()
  var l = getline('.')
  var ti = stridx(l, "\t")
  setline('.', ti < 0 ? '' : strpart(l, 0, ti + 1))
  startinsert!
enddef

def Leave(): bool
  if !&modified
    return true
  endif
  if confirm('Discard unsaved oil edits?', "&Yes\n&No", 2) == 1
    setlocal nomodified
    return true
  endif
  return false
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
  syntax match oilId '^[^\t]*\t' conceal
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
