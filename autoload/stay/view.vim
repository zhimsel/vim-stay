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
  set viewoptions-=options
  set viewoptions-=localoptions
  try
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

  " ensure we only react to a fresh view load without clobbering
  " b:stay_loaded_view (which is part of the API)
  if exists('b:stay_loaded_view')
    let l:stay_loaded_view = b:stay_loaded_view
    unlet b:stay_loaded_view
  endif

  " the `doautoall SessionLoadPost` in view session files significantly
  " slows down buffer load, hence we suppress it...
  let l:eventignore = &eventignore
  set eventignore+=SessionLoadPost
  set eventignore-=SourceCmd

  try
    " cache 'viewdir' value accounting for misformatted directory specification
    if s:viewdir.option isnot &viewdir
      let s:viewdir.option = &viewdir
      let s:viewdir.path   = substitute(s:viewdir.option, '\v[/\\]*$', s:slash(), '')
    endif

    " catch sourcing of the view file with a one-off SourceCmd autocommand
    let l:pattern = s:viewdir.path.'*'.fnamemodify(bufname('%'), ':t').'*'
    execute 'autocmd SourceCmd' l:pattern
    \ 'call stay#view#source(expand(''<afile>'')) |'
    \ 'autocmd! SourceCmd' l:pattern
    silent loadview
    let l:did_load_view = exists('b:stay_loaded_view')

    " fire SessionLoadPost in a more targeted way
    if l:did_load_view is 1
      let &eventignore = l:eventignore
      " don't use s:doautocmd(): we need modelines to be evaluated!
      execute (exists('#SessionLoadPost') ? '' : 'silent') 'doautocmd SessionLoadPost'
    endif

    " respect position set by other scripts / plug-ins
    if exists('b:stay_atpos')
      call cursor(b:stay_atpos[0], b:stay_atpos[1])
      silent! normal! zOzz
    endif

    return l:did_load_view
  catch /\vE48[45]/ " no read access to existing view file
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
    if !exists('b:stay_loaded_view') && exists('l:stay_loaded_view')
      let b:stay_loaded_view = l:stay_loaded_view
    endif
    let &eventignore = l:eventignore
    silent! execute 'autocmd! SourceCmd' l:pattern
    call s:doautocmd('User', 'BufStayLoadPost')
    call s:sneak2winid(l:curwinid)
  endtry
endfunction

" Source view session {file} minding 'viewignore':
" @signature:  stay#view#source({file:String})
" @returns:    Boolean (-1 on error)
" @notes:      Exceptions are suppressed, but written to |v:errmsg|
function! stay#view#source(file) abort
  if filereadable(a:file) isnot 1 | return 0 | endif
  let l:ignores = split(get(w:, 'viewignore', get(g:, 'viewignore', '')), ',')
  let l:noargl  = empty(l:ignores) ? 0 : index(l:ignores, 'arglist') isnot -1
  let l:nolcd   = empty(l:ignores) ? 0 : index(l:ignores, 'lcd') isnot -1
  try
    if get(l:, 'noargl', 0) is 1 || get(l:, 'nolcd', 0) is 1
      let l:cmds = readfile(a:file, '')
      for l:cmd in l:cmds
        if l:cmd =~ '\v^\s*"|^\s*$' ||
        \ (l:nolcd  is 1 && l:cmd =~ '\v\C<lcd!?\s+\f+') ||
        \ (l:noargl is 1 && l:cmd =~ '\v\C<%(argl%[ocal]|argg%[lobal])!?>')
          continue
        endif
        silent execute l:cmd
      endfor
    else
      silent noautocmd execute 'source' a:file
    endif
  catch
    let v:errmsg  = "vim-stay could not source view session file ".a:file."! "
    let v:errmsg .= "Vim error ".s:exception2errmsg(v:exception)
    return -1
  endtry
  let b:stay_loaded_view = a:file
  return 1
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

" - get the path separator character
if exists('+shellslash')
  function! s:slash() abort
    return &shellslash ? '/' : '\'
  endfunction
else " MacOS can use slashes from Vim 7 on, see |mac-filename|
  function! s:slash() abort
    return '/'
  endfunction
endif

" - activate a window ID without leaving a trail
function! s:sneak2winid(id) abort
  silent noautocmd keepalt keepjumps return stay#win#gotoid(a:id)
endfunction

" - extract the error message from an {exception}
function! s:exception2errmsg(exception) abort
  return substitute(a:exception, '\v^.{-}:\zeE\d.+$', '', '')
endfunction " }}}

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
