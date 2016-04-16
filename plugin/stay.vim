" A LESS SIMPLISTIC TAKE ON RESTORE_VIEW.VIM
" Maintainer: Martin Kopischke <martin@kopischke.net>
" License:    MIT (see LICENSE.md)
" Version:    1.3.1
" GetLatestVimScripts: 5099  1 :AutoInstall: vim-stay
if &compatible || !has('autocmd') || !has('mksession') || v:version < 700
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions&vim

" PLUG-IN CONFIGURATION {{{
" Defaults:
let s:defaults = {}
" - bona fide file types that should never be persisted
let s:defaults.volatile_ftypes = [
\ 'gitcommit', 'gitrebase', 'gitsendmail',
\ 'hgcommit', 'hgcommitmsg', 'hgstatus', 'hglog', 'hglog-changelog', 'hglog-compact',
\ 'svn', 'cvs', 'cvsrc', 'bzr',
\ ]
let s:integrations = [] " }}}

" PLUG-IN MACHINERY {{{
" Set b:stay_loaded_view to a sourced view session's file path
" (|v:this_session| is not set for view sessions, so we roll our own)
function! s:ViewSourced(file) abort
  if stay#isviewfile(a:file) is 1
    let b:stay_loaded_view = a:file
  endif
endfunction

" conditionally create a view session file for {bufnr} in {winid}
function! s:MakeView(stage, bufnr, winid) abort
  " do not create a view session if a call with a lower {stage} number
  " did so recently (currently hardwired to 1 second or less ago)
  let l:left = getbufvar(a:bufnr, 'stay_left')
  if a:stage > 1 && !empty(l:left) && localtime() - get(l:left, a:stage-1, 0) <= 1
    return 0
  endif

  if pumvisible() ||
  \ !stay#isviewwin(a:winid) ||
  \ !stay#ispersistent(a:bufnr, g:volatile_ftypes)
    return 0
  endif

  let l:done = stay#view#make(a:winid)
  if l:done is -1 | echomsg v:errmsg | endif
  call setbufvar(a:bufnr, 'stay_left', extend(l:left, {string(a:stage): localtime()}))
  return l:done
endfunction

" conditionally load view session file for {bufnr} in {winid}
function! s:LoadView(bufnr, winid) abort
  if exists('g:SessionLoad') ||
  \  pumvisible() ||
  \ !stay#isviewwin(a:winid) ||
  \ !stay#ispersistent(a:bufnr, g:volatile_ftypes)
    return 0
  endif

  let l:done = stay#view#load(a:winid)
  if l:done is -1 | echomsg v:errmsg | endif
  return l:done
endfunction

" Override 'autoread' in persistent buffers:
function! s:NoAutoread(bufnr) abort
  if getbufvar(a:bufnr, '&autoread') is 1 &&
  \ stay#ispersistent(a:bufnr, g:volatile_ftypes) is 1
    call setbufvar(a:bufnr, '&autoread', 0)
    let l:state = stay#getbufstate(a:bufnr)
    let l:state.autoread = 1
  endif
endfunction

" Save / load view session files for all windows of buffer {bufnr}:
function! s:StickyViews(step, bufnr) abort
  if !stay#ispersistent(a:bufnr, g:volatile_ftypes) | return 0 | endif

  let l:state = stay#getbufstate(a:bufnr)
  if a:step is 'make' && !empty(v:fcs_reason) && empty(v:fcs_choice)
    " emulate overridden 'autoread' setting
    let v:fcs_choice =
    \ get(l:state, 'autoread', 0) is 1 &&
    \ getbufvar(a:bufnr, '&modified') isnot 1 &&
    \ v:fcs_reason isnot 'deleted' ? 'reload' : 'ask'
  endif

  let l:curwin = stay#win#getid(winnr()) " Vim maintains the current window
  let l:winids = filter(stay#win#findbuf(a:bufnr), 'v:val isnot l:curwin')
  if a:step is 'make' " save the window IDs for the 'load' step
    let l:state.sticky = copy(l:winids)
  elseif a:step isnot 'load' || empty(get(l:state, 'sticky', []))
    return 0
  else " ensure we only load in window IDs we made a view for
    call filter(l:winids, 'index(l:state.sticky, v:val) isnot -1')
  endif

  for l:idx in range(len(l:winids))
    let l:viewidx = min([l:idx + 1, 9])
    if stay#view#{a:step}(l:winids[l:idx], l:viewidx) is -1
      echomsg v:errmsg
    endif
  endfor
endfunction

" Set up global configuration, autocommands, commands:
function! s:Setup(force) abort
  " core functionality (skipped unless {force} is 1)
  if a:force is 1
    " - make defaults available as individual global variables
    for [l:key, l:val] in items(s:defaults)
      let g:{l:key} = l:val
      unlet! l:val
    endfor

    " - autocommands
    augroup stay
      autocmd!
      " view session file loading recognition
      autocmd SourcePre ?* call s:ViewSourced(expand('<afile>'))

      " ensure a newly visible buffer loads its view
      autocmd BufWinEnter ?* nested
      \ call s:LoadView(str2nr(expand('<abuf>')), stay#win#getid(winnr()))
      " make sure the view is always in sync with window state
      autocmd WinLeave    ?* nested
      \ call s:MakeView(2, str2nr(expand('<abuf>')), stay#win#getid(winnr()))
      " catch hiding of buffers and quitting
      autocmd BufWinLeave ?* nested
      \ call s:MakeView(3, str2nr(expand('<abuf>')), stay#win#getid(winnr()))
      " catch saving and renaming of buffers
      autocmd BufFilePost,BufWritePost ?* nested
      \ call s:MakeView(1, str2nr(expand('<abuf>')), stay#win#getid(winnr()))

      " preserve views on file reloads
      autocmd BufEnter,BufWinEnter ?*
      \ call s:NoAutoread(str2nr(expand('<abuf>')))
      autocmd FileChangedShell     ?* nested
      \ call s:StickyViews('make', str2nr(expand('<abuf>')))
      autocmd FileChangedShellPost ?* nested
      \ call s:StickyViews('load', str2nr(expand('<abuf>')))
    augroup END

    " - ex commands
    command! -bang -nargs=? CleanViewdir
    \ call stay#viewdir#clean(expand('<bang>') is '!', <args>)
    command! -bang -nargs=0 StayReload
    \ call <SID>Setup(expand('<bang>') is '!')
  endif

  " load 3rd party integrations (new ones only unless {force} is 1)
  augroup stay_integrate
    if a:force is 1
      autocmd!
      let s:integrations = []
    endif
    for l:file in stay#shim#globpath(&rtp, 'autoload/stay/integrate/*.vim', 1, 1)
      let l:name = fnamemodify(l:file, ':t:r')
      if index(s:integrations, l:name) is -1
        try
          call call('stay#integrate#'.l:name.'#setup', [])
        catch /E117/ " no setup function found
          continue
        catch " integration setup execution errors
          echomsg "Skipped vim-stay integration for" l:name "due to error:" v:errmsg
          continue
        endtry
        call add(s:integrations, l:name)
      endif
    endfor
  augroup END
endfunction " }}}

" PLUG-IN SETUP
call s:Setup(1)

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
