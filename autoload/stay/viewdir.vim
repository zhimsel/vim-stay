" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" 'viewdir' handling functions
if &compatible || v:version < 700
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions&vim

" Remove view session files from 'viewdir':
" @signature:  stay#viewdir#clean({bang:String}, [{keepdays:Number}])
" @optargs:    {keepdays} keep files not older than this in days (default: 0)
" @returns:    List<Number> tuple of deletion candidates count, deleted files count
function! stay#viewdir#clean(bang, ...) abort
  let l:keepsecs   = max([get(a:, 1, 0) * 86400, 0])
  let l:candidates = stay#shim#globpath(&viewdir, '*', 1, 1)
  call filter(l:candidates, 'localtime() - getftime(v:val) > l:keepsecs')
  let l:candcount  = len(l:candidates)
  let l:delcount   = 0
  if a:bang is 1 ||
  \ input("Type 'Y' to delete ".l:candcount." view session files: ") is# 'Y'
    for l:file in l:candidates
      let l:delcount += (delete(l:file) is 0)
    endfor
  endif
  return [l:candcount, l:delcount]
endfunction

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
