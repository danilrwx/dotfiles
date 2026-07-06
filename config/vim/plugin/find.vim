vim9script

# Native fuzzy file find (habamax-style): list files once, fuzzy-filter with
# matchfuzzy() via the built-in 'findfunc'. Use `:find <fuzzy><Tab>` / <leader>f.
# Plus `:Grep <pat>` -> quickfix using 'grepprg'. No fzf, no vendored code.

var files_cache: list<string> = []
augroup findCache
  autocmd!
  autocmd CmdlineEnter : files_cache = []
augroup END

def FindCmd(): string
  if executable('fd')
    return 'fd . --path-separator / --type f --hidden --follow --exclude .git'
  elseif executable('rg')
    return 'rg --path-separator / --files --hidden --glob !.git'
  elseif executable('find')
    return 'find . -type f -not -path "*/.git/*"'
  endif
  return ''
enddef

def Find(arg: string, _): list<string>
  if empty(files_cache)
    var cmd = FindCmd()
    files_cache = empty(cmd)
      ? globpath('.', '**', 1, 1)->filter((_, v) => !isdirectory(v))
      : systemlist(cmd)->mapnew((_, v) => substitute(v, '^\./', '', ''))
  endif
  return empty(arg) ? files_cache : files_cache->matchfuzzy(arg)
enddef

set findfunc=Find

nnoremap <leader>e :find<space>

# quickfix grep via grepprg (interactive fzf grep is :Grep in plugin/fzf.vim)
command! -nargs=+ -bar Grepq {
  var cmd = $'{&grepprg} {<q-args>}'
  cgetexpr system(cmd)
  setqflist([], 'a', {title: cmd})
  belowright cwindow
}
