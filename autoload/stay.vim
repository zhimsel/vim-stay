" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" Core functions (will be loaded when first autocommand is triggered)
let s:cpo = &cpo
set cpo&vim

" Check if buffer {bufnr} is persistent:
" @signature:  stay#ispersistent({bufnr:Number}, {volatile_ftypes:List<String>})
" @returns:    Boolean
" @notes:      the persistence heuristics are
"              - buffer must be listed
"              - buffer must be of ordinary or "acwrite" 'buftype'
"              - not a preview window
"              - not a diff window
"              - buffer's 'bufhidden' must be empty or "hide"
"              - buffer must not be of a volatile file type
"              - buffer must map to a readable file
function! stay#ispersistent(bufnr, volatile_ftypes) abort
  return bufexists(a:bufnr)
    \ && getbufvar(a:bufnr, 'stay_ignore', 0) isnot 1
    \ && getbufvar(a:bufnr, '&buflisted') is 1
    \ && index(['', 'acwrite'], getbufvar(a:bufnr, '&buftype')) isnot -1
    \ && getbufvar(a:bufnr, '&previewwindow') isnot 1
    \ && getbufvar(a:bufnr, '&diff') isnot 1
    \ && index(['', 'hide'], getbufvar(a:bufnr, '&bufhidden')) isnot -1
    \ && index(a:volatile_ftypes, getbufvar(a:bufnr, '&filetype')) is -1
    \ && filereadable(fnamemodify(bufname(a:bufnr), ':p'))
endfunction

let &cpo = s:cpo
unlet! s:cpo

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
