" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" Core functions (will be loaded when first autocommand is triggered)
let s:cpo = &cpo
set cpo&vim

" Check if buffer {bufnr} is persistent:
" @signature:  stay#ispersistent({bufnr:Number}, {volatile_ftypes:List<String>})
" @returns:    Boolean
function! stay#ispersistent(bufnr, volatile_ftypes) abort
  return bufexists(a:bufnr)
    \ && getbufvar(a:bufnr, 'stay_ignore', 0) isnot 1
    \ && index(['', 'acwrite'], getbufvar(a:bufnr, '&buftype')) isnot -1
    \ && getbufvar(a:bufnr, '&previewwindow') isnot 1
    \ && getbufvar(a:bufnr, '&diff') isnot 1
    \ && getbufvar(a:bufnr, '&bufhidden') isnot# 'wipe'
    \ && index(a:volatile_ftypes, getbufvar(a:bufnr, '&filetype')) is -1
    \ && filereadable(fnamemodify(bufname(a:bufnr), ':p'))
endfunction

let &cpo = s:cpo
unlet! s:cpo

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
