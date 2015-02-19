" A LESS SIMPLISTIC TAKE ON RESTORE_VIEW.VIM
" Maintainer: Martin Kopischke <martin@kopischke.net>
" License:    MIT (see LICENSE.md)
" Version:    1.1.1
if &compatible || !has('autocmd') || !has('mksession') || v:version < 700
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions&vim

" Set defaults:
let s:defaults = {}
" - bona fide file types that should never be persisted
let s:defaults.volatile_ftypes = [
  \ 'gitcommit', 'gitrebase', 'gitsendmail',
  \ 'hgcommit', 'hgcommitmsg', 'hgstatus', 'hglog', 'hglog-changelog', 'hglog-compact',
  \ 'svn', 'cvs', 'cvsrc', 'bzr',
  \ ]
" - make defaults available as individual global variables
for [s:key, s:val] in items(s:defaults)
  execute 'let g:'.s:key. '= get(g:, "'.s:key.'", '.string(s:val).')'
  unlet! s:key s:val
endfor

" Set up 3rd party integrations:
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

" Set up autocommands:
augroup stay
  autocmd!
  " default buffer handling
  autocmd BufLeave,BufWinLeave ?*
        \ if stay#ispersistent(str2nr(expand('<abuf>')), g:volatile_ftypes) |
        \   call stay#view#make(bufwinnr(str2nr(expand('<abuf>')))) |
        \ endif
  autocmd BufWinEnter ?*
        \ if stay#ispersistent(str2nr(expand('<abuf>')), g:volatile_ftypes) |
        \   call stay#view#load(bufwinnr(str2nr(expand('<abuf>')))) |
        \ endif

  " generic, extensible 3rd party integration
  call s:integrate()
augroup END

" Set up commands:
command! -bang -nargs=? CleanViewdir
       \ call stay#viewdir#clean(expand('<bang>') is '!', <args>)

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
