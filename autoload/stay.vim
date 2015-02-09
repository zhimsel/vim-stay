" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" Core functions (will be loaded when first autocommand is triggered)
let s:cpo = &cpo
set cpo&vim

" Check if buffer {bufnr} is persistent:
" @signature:  stay#ispersistent({bufnr:Number}, {volatile_ftypes:List<String>})
" @returns:    Boolean
" @notes:      the persistence heuristics are
"              - buffer must be listed
"              - buffer name must not be empty
"              - buffer must be of ordinary or "acwrite" 'buftype'
"              - not a preview window
"              - not a diff window
"              - buffer's 'bufhidden' must be empty or "hide"
"              - buffer must not be of a volatile file type
"              - buffer must map to a readable file
"              - buffer file must not be located in a known temp dir
function! stay#ispersistent(bufnr, volatile_ftypes) abort
  let l:bufpath = expand('#'.a:bufnr.':p')
  return bufexists(a:bufnr)
    \ && !empty(l:bufpath)
    \ && getbufvar(a:bufnr, 'stay_ignore', 0) isnot 1
    \ && getbufvar(a:bufnr, '&buflisted') is 1
    \ && index(['', 'acwrite'], getbufvar(a:bufnr, '&buftype')) isnot -1
    \ && getbufvar(a:bufnr, '&previewwindow') isnot 1
    \ && getbufvar(a:bufnr, '&diff') isnot 1
    \ && index(['', 'hide'], getbufvar(a:bufnr, '&bufhidden')) isnot -1
    \ && index(a:volatile_ftypes, getbufvar(a:bufnr, '&filetype')) is -1
    \ && filereadable(l:bufpath)
    \ && stay#istemp(l:bufpath) isnot 1
endfunction

" Check if {fname} is in a 'backupskip' location:
" @signature:  stay#istemp({fname:String})
" @returns:    Boolean
function! stay#istemp(path) abort
  let l:candidates = stay#shim#globpath(&backupskip, '**/'.fnamemodify(a:path, ':t'), 1, 1)
  return index(l:candidates, a:path) isnot -1
endfunction


let &cpo = s:cpo
unlet! s:cpo

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
