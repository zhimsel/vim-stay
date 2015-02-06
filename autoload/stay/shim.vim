" STAY EVAL SHIM MODULE
" Are these Vim patch levels, my dear?

" globpath:
" - no {nosuf} argument before 7.2.051 - :h  version7.txt
" - no {list}  argument before 7.4.279 - http://ftp.vim.org/pub/vim/patches/7.4/README
function! stay#shim#globpath(path, glob, nosuf, list) abort
  if     v:version < 702 || (v:version is 702 && !has('patch-051'))
    return split(globpath(a:path, a:glob), '\n')
  elseif v:version < 704 || (v:version is 704 && !has('patch-279'))
    return split(globpath(a:path, a:glob, a:nosuf), '\n')
  else
    return globpath(a:path, a:glob, a:nosuf, a:list)
  endif
endfunction

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
