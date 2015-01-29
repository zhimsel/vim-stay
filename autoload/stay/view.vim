" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" View session handling functions
let s:cpo = &cpo
set cpo&vim

" Make a persistent view for window {winnr}:
" @signature:  stay#view#make({winnr:Number})
" @returns:    Boolean
function! stay#view#make(winnr) abort
  if a:winnr is -1
    return 0
  endif

  try
    let l:lazyredraw = &lazyredraw
    set lazyredraw
    let l:curwinnr   = s:gotowin(a:winnr)
    unlet! b:stay_atpos
    mkview
    call s:gotowin(l:curwinnr)
    return 1
  finally
    let &lazyredraw = l:lazyredraw
  endtry
endfunction

" Load a persistent view for window {winnr}:
" @signature:  stay#view#load({winnr:Number})
" @returns:    Boolean
function! stay#view#load(winnr) abort
  if a:winnr is -1
    return 0
  endif

  let l:curwinnr = s:gotowin(a:winnr)
  noautocmd silent loadview
  if exists('b:stay_atpos')
    call cursor(b:stay_atpos[0], b:stay_atpos[1])
    silent! normal! zOzz
  endif
  call s:gotowin(l:curwinnr)
  return 1
endfunction

" Private helper functions:
function! s:gotowin(winnr) abort
  let l:curwinnr = winnr()
  if a:winnr isnot l:curwinnr
    execute 'noautocmd keepjumps keepalt silent!' a:winnr.'wincmd w'
  endif
  return l:curwinnr
endfunction

let &cpo = s:cpo
unlet! s:cpo

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
