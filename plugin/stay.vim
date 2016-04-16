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
" 3rd party integrations:
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
function! s:MakeView(bufnr, winid) abort
  if stay#ispersistent(a:bufnr, g:volatile_ftypes)
    if stay#view#make(a:winid) is -1
      echomsg v:errmsg
    endif
  endif
endfunction

" conditionally load view session file for {bufnr} in {winid}
function! s:LoadView(bufnr, winid) abort
  if stay#ispersistent(a:bufnr, g:volatile_ftypes)
    if stay#view#load(a:winid) is -1
      echomsg v:errmsg
    endif
  endif
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
      autocmd SourcePre ?* call s:ViewSourced(expand('<afile>'))
      autocmd BufLeave,BufWinLeave ?* nested
      \ call s:MakeView(expand('<abuf>')), stay#win#getid(winnr())
      autocmd BufWinEnter ?* nested
      \ call s:LoadView(expand('<abuf>')), stay#win#getid(winnr())
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
