vim9script

# oil-mini: edit a directory as a buffer. :w applies renames/creates/deletes,
# subpaths included (mkdir -p). <CR> opens the entry, - goes up a directory.
# A hidden 4-digit id prefix tracks each entry, so renames survive reordering
# and copy-paste; a line with no known id is a new entry, a vanished id is a
# deletion (confirmed). Depends on nothing but built-ins.

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

def Apply(): bool
  var dir = b:oil_dir
  var reg = b:oil_reg
  var seen: dict<bool> = {}
  var renames: list<list<string>> = []
  var creates: list<string> = []
  for l in getline(1, '$')->filter((_, v) => v !~ '^\s*$')
    var m = matchlist(l, '^\(\d\{4}\)\t\(.*\)$')
    if !empty(m) && reg->has_key(m[1])
      seen[m[1]] = true
      if m[2] != reg[m[1]]
        renames->add([reg[m[1]], m[2]])
      endif
    else
      creates->add(empty(m) ? l : m[2])
    endif
  endfor
  var deletes: list<string> = []
  for [id, name] in items(reg)
    if !seen->has_key(id)
      deletes->add(name)
    endif
  endfor
  if empty(renames) && empty(creates) && empty(deletes)
    return true
  endif
  var summary: list<string> = []
  for [old, new] in renames
    summary->add($'rename  {old} → {new}')
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
  for [old, new] in renames
    var src = simplify(dir .. trim(old, '/', 2))
    var dst = simplify(dir .. trim(new, '/', 2))
    if src ==# dst
      continue
    endif
    if filereadable(dst) || isdirectory(dst)
      errors->add($'rename skipped, exists: {new}')
      continue
    endif
    Mkparent(dst)
    if rename(src, dst) != 0
      errors->add($'rename failed: {old} → {new}')
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
