" A LESS SIMPLISTIC TAKE ON RESTORE_VIEW.VIM
" Maintainer: Martin Kopischke <martin@kopischke.net>
" License:    MIT (see LICENSE.md)
" Version:    1.1.0
if &compatible || !has('autocmd') || !has('mksession') || v:version < 700
  finish
endif

let s:cpo = &cpo
set cpo&vim

" Set defaults:
let s:defaults = {}
let s:defaults.volatile_ftypes = ['gitcommit', 'gitrebase', 'gitsendmail']
for [s:key, s:val] in items(s:defaults)
  execute 'let g:'.s:key. '= get(g:, "'.s:key.'", '.string(s:val).')'
  unlet! s:key s:val
endfor

" Set up 3rd party integrations:
function! s:integrate() abort
  let s:integrations = []
  for l:file in globpath(&rtp, 'autoload/stay/integrate/*.vim', 1, 1)
    try
      let l:name = fnamemodify(l:file, ':t:r')
      if index(s:integrations, l:name) is -1
        call call('stay#integrate#'.l:name.'#setup', [])
        call add(s:integrations, l:name)
      endif
    catch /E117/ " no setup function found
      continue
    catch " integration setup execution errors
      echomsg "Error setting up" l:name "integration:" v:errmsg
      continue
    endtry
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

  " vim-fetch integration
  autocmd User BufFetchPosPost let b:stay_atpos = b:fetch_lastpos

  " generic, extensible 3rd party integration
  call s:integrate()
augroup END

let &cpo = s:cpo
unlet! s:cpo

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
