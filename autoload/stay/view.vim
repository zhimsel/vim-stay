" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" View session handling functions
if &compatible || !has('autocmd') || !has('mksession') || v:version < 700
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions&vim

" Make a persistent view for window ID {winid}:
" @signature:  stay#view#make({winid:Number})
" @returns:    Boolean (-1 on error)
" @notes:      Exceptions are suppressed, but written to |v:errmsg|
function! stay#view#make(winid) abort
  let l:curwinid = stay#win#getid()
  if s:sneak2winid(a:winid) isnot 1
    let v:errmsg = "vim-stay could not switch to window ID: ".a:winid
    return 0
  endif

  call s:doautocmd('User', 'BufStaySavePre')
  " enforce non-storage of options as that causes odd issues
  let l:viewoptions = &viewoptions
  try
    set viewoptions-=options
    set viewoptions-=localoptions
    unlet! b:stay_atpos
    silent mkview
    return 1
  catch /\vE%(166|190|212)/ " no write access to existing view file
    let v:errmsg  = "vim-stay could not write the view session file! "
    let v:errmsg .= "Vim error ".s:exception2errmsg(v:exception)
    return -1
  catch " other errors
    let v:errmsg = 'vim-stay error '.s:exception2errmsg(v:exception)
    return -1
  finally
    call s:doautocmd('User', 'BufStaySavePost')
    let &viewoptions = l:viewoptions
    call s:sneak2winid(l:curwinid)
  endtry
endfunction

" Load a persistent view for window ID {winid}:
" @signature:  stay#view#load({winid:Number})
" @returns:    Boolean (-1 on error)
" @notes:      Exceptions are suppressed, but written to |v:errmsg|
let s:viewdir = {'option': '', 'path': ''}
function! stay#view#load(winid) abort
  let l:curwinid = stay#win#getid()
  if s:sneak2winid(a:winid) isnot 1
    let v:errmsg = "vim-stay could not switch to window ID: ".a:winid
    return 0
  endif

  " emit Pre event before we change any setting
  call s:doautocmd('User', 'BufStayLoadPre')

  " the `doautoall SessionLoadPost` in view session files significantly
  " slows down buffer load, hence we suppress it...
  let l:eventignore = &eventignore
  try
    set eventignore+=SessionLoadPost
    set eventignore-=SourceCmd
    " ensure we only react to a fresh view load without clobbering
    " b:stay_loaded_view (which is part of the API)
    if exists('b:stay_loaded_view')
      let l:stay_loaded_view = b:stay_loaded_view
      unlet b:stay_loaded_view
    endif

    " cache 'viewdir' value and normalise its directory path
    if s:viewdir.option isnot &viewdir
      let s:viewdir.option = &viewdir
      " Windows path backslashes will not work in autocommands and need to be replaced by
      " slashes; also Windows paths set in Vim options may contain both slashes and backslashes,
      " so we need to give them the foward slash treatment too to normalise misformatted options
      let l:slashes = exists('+shellslash') ? '[/\\]' : '/'
      let s:viewdir.path = substitute(&viewdir, '\v'.l:slashes.'+', '/', 'g')
    endif

    " catch sourcing of the view file with a one-off SourcePre autocommand
    let l:buftail = fnamemodify(bufname('%'), ':t')
    let l:pattern = fnameescape(s:viewdir.path).'*'.fnameescape(l:buftail).'*'
    execute 'autocmd SourcePre' l:pattern
    \ 'let b:stay_loaded_view = expand(''<sfile>'') | autocmd! SourcePre' l:pattern
    silent loadview
    let l:did_load_view = exists('b:stay_loaded_view')

    " fire SessionLoadPost in a more targeted way
    if l:did_load_view is 1
      let &eventignore = l:eventignore
      " don't use s:doautocmd(): we need modelines to be evaluated!
      execute (exists('#SessionLoadPost') ? '' : 'silent') 'doautocmd SessionLoadPost'
    endif

    " respect position set by other scripts / plug-ins
    if l:did_load_view is 1 && exists('b:stay_atpos') && getpos('.')[1:2] != b:stay_atpos
      call cursor(b:stay_atpos[0], b:stay_atpos[1])
      silent! normal! zOzz
    endif
    return l:did_load_view
  catch /E484/ " failed to open view file
    let v:errmsg  = 'vim-stay could not open the view session file! '
    let v:errmsg .= 'Vim error '.s:exception2errmsg(v:exception)
    if has('nvim')  " neovim produces this error every time; don't return it
      return 0
    else
      return -1
    endif
  catch /E485/ " no read access to existing view file
    let v:errmsg  = "vim-stay could not read the view session file! "
    let v:errmsg .= "Vim error ".s:exception2errmsg(v:exception)
    return -1
  catch /\vE%(35[0-2]|490)/ " fold errors
    let v:errmsg = 'vim-stay error '.s:exception2errmsg(v:exception)
    return 0
  catch " other errors
    let v:errmsg = 'vim-stay error '.s:exception2errmsg(v:exception)
    return -1
  finally
    " restore stale b:stay_loaded_view for API usage
    if get(l:, 'did_load_view', 0) isnot 1 && exists('l:stay_loaded_view')
      let b:stay_loaded_view = l:stay_loaded_view
    endif
    let &eventignore = l:eventignore
    call s:doautocmd('User', 'BufStayLoadPost')
    call s:sneak2winid(l:curwinid)
  endtry
endfunction

" Private helper functions: {{{
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
endfunction

" - activate a window ID without leaving a trail
function! s:sneak2winid(id) abort
  silent noautocmd keepalt return stay#win#gotoid(a:id)
endfunction

" - extract the error message from an {exception}
function! s:exception2errmsg(exception) abort
  return substitute(a:exception, '\v^.{-}:\zeE\d.+$', '', '')
endfunction " }}}

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
