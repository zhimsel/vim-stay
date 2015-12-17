" STAY EVAL SHIM MODULE
" Are these Vim patch levels, my dear?
if &compatible || v:version < 700
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions&vim

" Full forward and backward `globpath()` compatibility between Vim 7.0 and Vim 7.4:
" - no {nosuf} argument before 7.2.051 - :h  version7.txt
" - no {list}  argument before 7.4.279 - http://ftp.vim.org/pub/vim/patches/7.4/README
if v:version < 702 || (v:version is 702 && !has('patch051'))
  function! stay#shim#globpath(path, glob, ...) abort
    let l:nosuf      = get(a:, 1, 0)
    let l:list       = get(a:, 2, 0)
    let l:suffixes   = &suffixes
    let l:wildignore = &wildignore
    try
      if l:nosuf isnot 0
        set suffixes=
        set wildignore=
      endif
      let l:result = globpath(a:path, a:glob)
      return l:list isnot 0 ? s:fnames2list(l:result, 0) : l:result
    finally
      let &suffixes   = l:suffixes
      let &wildignore = l:wildignore
    endtry
  endfunction

elseif v:version < 704 || (v:version is 704 && !has('patch279'))
  function! stay#shim#globpath(path, glob, ...) abort
    let l:nosuf  = get(a:, 1, 0)
    let l:list   = get(a:, 2, 0)
    let l:result = globpath(a:path, a:glob, l:nosuf)
    return l:list isnot 0 ? s:fnames2list(l:result, l:nosuf) : l:result
  endfunction

else
  function! stay#shim#globpath(path, glob, ...) abort
    return globpath(a:path, a:glob, get(a:, 1, 0), get(a:, 2, 0))
  endfunction
endif

" Get a List out of {fnames} without mangling file names with NL in them:
" @signature:  s:fnames2list({fnames:String[NL-separated]}, {setnosuf:Boolean})
" @returns:    List<String> of file system object paths in {fnames}
function! s:fnames2list(fnames, setnosuf) abort
  let l:globcmd   = a:setnosuf is 1 ? 'glob(%s, 1)' : 'glob(%s)'
  let l:fnames    = split(a:fnames, '\n')
  let l:fragments = filter(copy(l:fnames), 'empty('.printf(l:globcmd, 'v:val').')')
  if empty(l:fragments)
    return l:fnames
  endif

  let l:fnames = filter(l:fnames, '!empty('.printf(l:globcmd, 'v:val').')')
  let l:index  = 0
  while l:index+1 < len(l:fragments)
    let l:composite = get(l:, 'composite', l:fragments[l:index])."\n".l:fragments[l:index+1]
    if !empty(eval(printf(l:globcmd, string(l:composite))))
      call add(l:fnames, l:composite)
      unlet l:composite
      let l:index += 1
    endif
    let l:index += 1
  endwhile
  return sort(l:fnames, 'i')
endfunction

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
