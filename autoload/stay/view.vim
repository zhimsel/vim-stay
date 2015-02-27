" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" View session handling functions
let s:cpoptions = &cpoptions
set cpoptions&vim

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
    if !s:win.goto(a:winnr)
      return 0
    endif
    unlet! b:stay_atpos
    call s:doautocmd('User', 'BufStaySavePre')
    mkview
    call s:doautocmd('User', 'BufStaySavePost')
    call s:win.back()
    return 1
  finally
    let &lazyredraw = l:lazyredraw
  endtry
endfunction

" Load a persistent view for window {winnr}:
" @signature:  stay#view#load({winnr:Number})
" @returns:    Boolean
function! stay#view#load(winnr) abort
  if a:winnr is -1 || !s:win.goto(a:winnr)
    return 0
  endif

  call s:doautocmd('User', 'BufStayLoadPre')
  try   " significantly slows down buffer loads without noautocmd
    noautocmd silent loadview
  catch " silently return on errors
    return 0
  endtry
  call s:doautocmd('User', 'BufStayLoadPost')
  call s:doautocmd('SessionLoadPost')

  if exists('b:stay_atpos')
    call cursor(b:stay_atpos[0], b:stay_atpos[1])
    silent! normal! zOzz
  endif
  call s:win.back()
  return 1
endfunction

" Private helper functions: {{{
" - window navigation stack
let s:win = {'stack': []}

function! s:win.activate(winnr) abort
  if winnr() isnot a:winnr
    execute 'noautocmd keepjumps keepalt silent' a:winnr.'wincmd w'
  endif
endfunction

function! s:win.goto(winnr) abort
  let l:oldwinnr = winnr()
  call self.activate(a:winnr)
  call add(self.stack, l:oldwinnr)
  return winnr() is a:winnr
endfunction

function! s:win.back() abort
  if len(self.stack) > 0
    let l:towinnr = remove(self.stack, -1)
    call self.activate(l:towinnr)
  endif
  return exists('l:towinnr') && winnr() is l:towinnr
endfunction

" - apply {event} autocommands, optionally matching pattern {a:1},
"   but only if there are any
"   1. avoids flooding message history with "No matching autocommands"
"   2. avoids re-applying modelines in Vim < 7.3.442, which doesn't honor |<nomodeline>|
"   see https://groups.google.com/forum/#!topic/vim_dev/DidKMDAsppw
function! s:doautocmd(event, ...) abort
  let l:event = a:0 ? [a:event, a:1] : [a:event]
  if exists('#'.join(l:event, '#'))
    execute 'doautocmd <nomodeline>' join(l:event, ' ')
  endif
endfunction " }}}

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
