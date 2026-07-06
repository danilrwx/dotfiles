vim9script

# oil-mini: edit a directory as a buffer. :w applies renames/creates/deletes and
# copies (duplicate a line -> copy), subpaths included (mkdir -p). <CR> opens the
# entry, - goes up. A hidden 4-digit id prefix tracks each entry: same id twice
# (copied line) with a new name is a copy of the original; a changed single line
# is a rename; a line with no id is a new entry; a vanished id is a deletion.
# Depends on git-less built-ins plus `cp` for copies.

def Render()
  b:oil_reg = {}
  var lines: list<string> = []
  var n = 0
  for name in readdir(b:oil_dir)->sort()
    n += 1
    var id = printf('%04d', n)
    var disp = name .. (isdirectory(b:oil_dir .. name) ? '/' : '')
    b:oil_reg[id] = disp
    lines->add(id .. "\t" .. disp)
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

def Apply(): bool
  var dir = b:oil_dir
  var reg = b:oil_reg
  var byid: dict<list<string>> = {}
  var creates: list<string> = []
  for l in getline(1, '$')->filter((_, v) => v !~ '^\s*$')
    var m = matchlist(l, '^\(\d\{4}\)\t\(.*\)$')
    if !empty(m) && reg->has_key(m[1])
      byid[m[1]] = add(get(byid, m[1], []), m[2])
    else
      creates->add(empty(m) ? l : m[2])
    endif
  endfor

  var renames: list<list<string>> = []
  var copies: list<list<string>> = []
  var deletes: list<string> = []
  for [id, oldname] in items(reg)
    if !byid->has_key(id)
      deletes->add(oldname)
      continue
    endif
    var names = byid[id]
    if index(names, oldname) >= 0
      # original kept; any other occurrence of this id is a copy of it
      for nm in names
        if nm != oldname
          copies->add([oldname, nm])
        endif
      endfor
    else
      # original name gone: first occurrence renames it, the rest copy from it
      renames->add([oldname, names[0]])
      for nm in names[1 : ]
        copies->add([oldname, nm])
      endfor
    endif
  endfor

  if empty(renames) && empty(copies) && empty(creates) && empty(deletes)
    return true
  endif

  var summary: list<string> = []
  for [old, new] in renames
    summary->add($'rename  {old} → {new}')
  endfor
  for [src, dst] in copies
    summary->add($'copy    {src} → {dst}')
  endfor
  for name in creates
    summary->add($'create  {name}')
  endfor
  for name in deletes
    summary->add($'delete  {name}')
  endfor
  if confirm("Apply changes?\n" .. join(summary, "\n"), "&Yes\n&No", 2) != 1
    return false
  endif

  var errors: list<string> = []

  # every final target name; if one is claimed twice, skip those with an error
  var tcount: dict<number> = {}
  for [old, new] in renames
    tcount[new] = get(tcount, new, 0) + 1
  endfor
  for [src, dst] in copies
    tcount[dst] = get(tcount, dst, 0) + 1
  endfor
  for name in creates
    tcount[name] = get(tcount, name, 0) + 1
  endfor

  # copies first, while the originals are still in place
  for [src, dst] in copies
    if tcount[dst] > 1
      errors->add($'copy skipped, name used twice: {dst}')
      continue
    endif
    var d2 = simplify(dir .. trim(dst, '/', 2))
    if filereadable(d2) || isdirectory(d2)
      errors->add($'copy skipped, exists: {dst}')
      continue
    endif
    Mkparent(d2)
    if CopyPath(simplify(dir .. trim(src, '/', 2)), d2) != 0
      errors->add($'copy failed: {src} → {dst}')
    endif
  endfor

  # renames in two phases via temp names so swaps/cycles (a↔b) work: first move
  # every source out to a temp, then temps into their final names.
  # ponytail: temp is .oil-tmp-N in dir; a real file of that name would clash.
  var vacated: dict<bool> = {}
  for [old, new] in renames
    vacated[trim(old, '/', 2)] = true
  endfor
  for name in deletes
    vacated[trim(name, '/', 2)] = true
  endfor
  var pending: list<list<string>> = []
  var ti = 0
  for [old, new] in renames
    if tcount[new] > 1
      errors->add($'rename skipped, name used twice: {new}')
      continue
    endif
    var dst = simplify(dir .. trim(new, '/', 2))
    if (filereadable(dst) || isdirectory(dst)) && !vacated->has_key(trim(new, '/', 2))
      errors->add($'rename skipped, exists: {new}')
      continue
    endif
    ti += 1
    var tmp = simplify(dir .. printf('.oil-tmp-%d', ti))
    if rename(simplify(dir .. trim(old, '/', 2)), tmp) != 0
      errors->add($'rename failed: {old} → {new}')
      continue
    endif
    pending->add([tmp, new])
  endfor
  for [tmp, new] in pending
    var dst = simplify(dir .. trim(new, '/', 2))
    Mkparent(dst)
    if rename(tmp, dst) != 0
      errors->add($'rename failed → {new}')
    endif
  endfor

  for name in creates
    if tcount[name] > 1
      continue
    endif
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

  for name in deletes
    if delete(simplify(dir .. trim(name, '/', 2)), name =~ '/$' ? 'rf' : '') != 0
      errors->add($'delete failed: {name}')
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
  var m = matchlist(getline('.'), '^\d\{4}\t\(.*\)$')
  if empty(m) || !Leave()
    return
  endif
  if m[1] =~ '/$'
    Open(b:oil_dir .. m[1])
  else
    execute 'edit ' .. fnameescape(b:oil_dir .. m[1])
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
    var m = matchlist(getline(lnum), '^\d\{4}\t\(.*\)$')
    if !empty(m) && (m[1] == name || m[1] == name .. '/')
      cursor(lnum, 6)
      return
    endif
  endfor
enddef

# cc/S would wipe the hidden id (turning a rename into delete+create); keep the
# id and clear only the name so the edit stays a rename.
def RenameLine()
  var m = matchlist(getline('.'), '^\(\d\{4}\t\)')
  setline('.', empty(m) ? '' : m[1])
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
  syntax match oilId '^\d\{4}\t' conceal
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
