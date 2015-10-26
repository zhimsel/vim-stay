" FASTFOLD INTEGRATION MODULE
" https://github.com/Konfekt/FastFold
let s:cpoptions = &cpoptions
set cpoptions&vim

" - cancel integration if FastFold is not found
if empty(findfile('plugin/fastfold.vim', &rtp))
  let &cpoptions = s:cpoptions
  unlet! s:cpoptions
  finish
endif

" - register integration autocommands if FastFold plug-in is found
function! stay#integrate#fastfold#setup() abort
  autocmd User BufStaySavePre  unsilent call stay#integrate#fastfold#save_pre()
  autocmd User BufStaySavePost unsilent call stay#integrate#fastfold#save_post()
  autocmd User BufStayLoadPost,BufStaySavePost let b:isPersistent = 1
endfunction

" - on User event 'BufStaySavePre': restore original 'foldmethod'
function! stay#integrate#fastfold#save_pre() abort
  if index(split(&viewoptions, ','), 'folds') isnot -1
    let [l:fdmlocal, l:fdmorig] = [&l:foldmethod, get(w:, 'lastfdm', &l:foldmethod)]
    if l:fdmlocal is# 'manual'
      noautocmd silent let &l:foldmethod = l:fdmorig
    endif
  endif
endfunction

" - on User event 'BufStaySavePost': restore FastFold 'foldmethod'
function! stay#integrate#fastfold#save_post() abort
  if &foldmethod isnot# 'manual' && exists('w:lastfdm')
    noautocmd silent let &l:foldmethod = 'manual'
  endif
endfunction

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
