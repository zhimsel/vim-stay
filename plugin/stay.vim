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

" Plug-in defaults:
let s:defaults = {}
" - bona fide file types that should never be persisted
let s:defaults.volatile_ftypes = [
  \ 'gitcommit', 'gitrebase', 'gitsendmail',
  \ 'hgcommit', 'hgcommitmsg', 'hgstatus', 'hglog', 'hglog-changelog', 'hglog-compact',
  \ 'svn', 'cvs', 'cvsrc', 'bzr',
  \ ]

" Loader for 3rd party integrations:
function! s:integrate() abort
  let s:integrations = []
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
endfunction

" Set up global configuration, autocommands, commands:
function! s:setup(defaults) abort
  " - make defaults available as individual global variables,
  "   respecting pre-set global vars unless {defaults} is 1
  for [s:key, s:val] in items(s:defaults)
    let g:{s:key} = a:defaults is 1 ? s:val : get(g:, s:key, s:val)
    unlet! s:key s:val
  endfor

  " - 'stay' autocommand group (also used by integrations)
  augroup stay
    autocmd!

    " |v:this_session| is not set for view sessions, so we roll our own
    autocmd SourcePre ?*
          \ if stay#isviewfile(expand('<afile>')) is 1 |
          \   let b:stay_loaded_view = expand('<afile>') |
          \ endif

    " default buffer handling
    autocmd BufLeave,BufWinLeave ?* nested
          \ if stay#ispersistent(str2nr(expand('<abuf>')), g:volatile_ftypes) |
          \   if stay#view#make(stay#win#getid(winnr())) is -1 |
          \     echomsg v:errmsg |
          \   endif |
          \ endif
    autocmd BufWinEnter ?* nested
          \ if stay#ispersistent(str2nr(expand('<abuf>')), g:volatile_ftypes) |
          \   if stay#view#load(stay#win#getid(winnr())) is -1 |
          \     echomsg v:errmsg |
          \   endif |
          \ endif

    " generic, extensible 3rd party integration
    call s:integrate()
  augroup END

  " - ex commands
  command! -bang -nargs=? CleanViewdir
        \ call stay#viewdir#clean(expand('<bang>') is '!', <args>)
  command! -bang -nargs=0 StayReload
        \ call <SID>setup(expand('<bang>') is '!')
endfunction

call s:setup(0)

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
