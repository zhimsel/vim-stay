" A LESS SIMPLISTIC TAKE ON RESTORE_VIEW.VIM
" Maintainer: Zach Himsel <zach@himsel.net>
" License:    MIT (see LICENSE.md)
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
" - verbosity of echomsg error / status reporting
"  -1 no messages
"   0 important error messages (default)
"   1 all status and error messages
let s:defaults.stay_verbosity = 0

" Loaded 3rd party integrations:
let s:integrations = [] " }}}

" PLUG-IN MACHINERY {{{
" Echo v:errmsg if {level} is below g:stay_verbosity.
" Makes sure we do not echo messages that are not vim-stay errors:
function! s:HandleErrMsg(level) abort
  if a:level < min([1, g:stay_verbosity])
    echomsg v:errmsg
  endif
endfunction

" Conditionally create a view session file for {bufnr} in {winid}:
function! s:MakeView(stage, bufnr, winid) abort
  " do not create a view session if a call with a lower {stage} number
  " did so recently (currently hardwired to 1 second or less ago)
  let l:state = stay#getbufstate(a:bufnr)
  let l:left  = get(l:state, 'left', {})
  if a:stage > 1 && !empty(l:left) && localtime() - get(l:left, a:stage-1, 0) <= 1
    return 0
  endif

  if pumvisible() ||
  \ !stay#isviewwin(a:winid) ||
  \ !stay#ispersistent(a:bufnr, g:volatile_ftypes)
    return 0
  endif

  let l:done = stay#view#make(a:winid)
  call s:HandleErrMsg(l:done)
  if l:done is  1
    let l:state.left = extend(l:left, {string(a:stage): localtime()})
  endif
  return l:done
endfunction

" Conditionally load view session file for {bufnr} in {winid}:
function! s:LoadView(bufnr, winid) abort
  if exists('g:SessionLoad') ||
  \  pumvisible() ||
  \ !stay#isviewwin(a:winid) ||
  \ !stay#ispersistent(a:bufnr, g:volatile_ftypes)
    return 0
  endif

  let l:done = stay#view#load(a:winid)
  call s:HandleErrMsg(l:done)
  return l:done
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
    augroup END

    " - ex commands
    command! -bar -bang -nargs=? CleanViewdir
    \ call stay#viewdir#clean(expand('<bang>') is '!', <args>)
    command! -bar -bang -nargs=0 StayReload
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
          let v:errmsg = "No vim-stay integration setup function found for ".l:name
          call s:HandleErrMsg(0)
          continue
        catch " integration setup execution errors
          let v:errmsg = "Skipped vim-stay integration for ".l:name." due to error: ".v:errmsg
          call s:HandleErrMsg(-1)
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
