vim9script

# Imports yegappan/lsp internals, so this file must be sourced only after the
# plugin is packadd'd. As an autoload script it is sourced on first use (from
# :LspDiagAll, by which point a code filetype has loaded lsp), not at startup.
import autoload 'lsp/diag.vim'

const SEV = {1: 'E', 2: 'W', 3: 'I', 4: 'N'}

# aggregate every loaded buffer's LSP diagnostics into one quickfix list
export def All()
  var items = []
  for b in getbufinfo({bufloaded: 1})
    for d in diag.GetDiagsForBuf(b.bufnr)
      items->add({
        bufnr: b.bufnr,
        lnum: d.range.start.line + 1,
        col: d.range.start.character + 1,
        text: substitute(d.message, "\n\\+", ' ', 'g'),
        type: SEV->get(d->get('severity', 1), 'E'),
      })
    endfor
  endfor
  if empty(items)
    echo 'no diagnostics'
    return
  endif
  setqflist([], ' ', {items: items, title: 'LSP diagnostics'})
  copen
  cfirst
enddef
