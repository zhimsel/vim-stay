" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" Core functions (will be loaded when first autocommand is triggered)
if &compatible || v:version < 700
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions&vim

" Check if the buffer {bufnr} is persistent:
" @signature:  stay#ispersistent({bufnr:Number}, {volatile_ftypes:List<String>})
" @returns:    Boolean
" @notes:      the persistence heuristics are
"              - buffer name must not be empty
"              - buffer must not be marked as ignored
"              - buffer must be listed
"              - buffer must be of ordinary or "acwrite" 'buftype'
"              - buffer's 'bufhidden' must be empty or "hide"
"              - buffer must map to a readable file
"              - buffer must not be of a volatile file type
"              - buffer file must not be located in a known temp dir
function! stay#ispersistent(bufnr, volatile_ftypes) abort
  let l:bufpath = expand('#'.a:bufnr.':p') " empty on invalid buffer numbers
  return
  \ !empty(l:bufpath) &&
  \ getbufvar(a:bufnr, 'stay_ignore') isnot 1 &&
  \ getbufvar(a:bufnr, '&buflisted') is 1 &&
  \ index(['', 'acwrite'], getbufvar(a:bufnr, '&buftype')) isnot -1 &&
  \ index(['', 'hide'], getbufvar(a:bufnr, '&bufhidden')) isnot -1 &&
  \ filereadable(l:bufpath) &&
  \ stay#isftype(a:bufnr, a:volatile_ftypes) isnot 1 &&
  \ stay#istemp(l:bufpath) isnot 1
endfunction

" Check if the window with ID {winid} is eligible for view saving:
" @signature:  stay#isviewwin({winid:Number})
" @returns:    Boolean
" @notes:      a window is considered eligible when
"              - it exists
"              - it is not a preview window
"              - it is not a diff window
function! stay#isviewwin(winid) abort
  let [l:tabnr, l:winnr] = stay#win#id2tabwin(a:winid)
  return
  \ l:tabnr isnot 0 &&
  \ l:winnr isnot 0 &&
  \ gettabwinvar(l:tabnr, l:winnr, '&previewwindow') isnot 1 &&
  \ gettabwinvar(l:tabnr, l:winnr, '&diff') isnot 1
endfunction

" Check if {fname} is in a 'backupskip' location:
" @signature:  stay#istemp({fname:String})
" @returns:    Boolean
if exists('*glob2regpat') " fastest option, Vim 7.4 with patch 668 only
  let s:backupskip = {'option': '', 'items': []}
  function! stay#istemp(path) abort
    " cache List of option-unescaped 'backuspkip' values
    if s:backupskip.option isnot &backupskip
      let s:backupskip.option = &backupskip
      let s:backupskip.items  = split(s:backupskip.option, '\v\\@<!%(\\\\)*,')
      let s:backupskip.items  = map(s:backupskip.items,
      \ "substitute(v:val, '\v\\@<!%(\\\\)*\\\zs[ ,]', '\\0', 'g')")
    endif
    for l:tempdir in s:backupskip.items
      if a:path =~# glob2regpat(l:tempdir)
        return 1
      endif
    endfor
    return 0
  endfunction
elseif has('wildignore') " ~ slower by x 1.75
  function! stay#istemp(path) abort
    let l:wildignore = &wildignore
    try
      let &wildignore = &backupskip
      return empty(expand(a:path))
    finally
      let &wildignore = l:wildignore
    endtry
  endfunction
else
  " assume Vim builds without |+wildignore| are performance constrained,
  " which makes using |globpath()| filtering on 'backupskip' a non-option
  " (it's about a 100 times slower than the 'wildignore' / |expand()| hack)
  function! stay#istemp(path) abort " @vimlint(EVL103, 1) unused argument {path}
    return -1
  endfunction " @vimlint(EVL103, 0)
endif

" Check if one of {bufnr}'s 'filetype' parts is on the {ftypes} List:
" @signature:  stay#isftype({bufnr:Number}, {ftypes:List<String>})
" @returns:    Boolean
" @notes:      - tests individual parts of composite (dotted) 'filetype's
"              - comparison is always case sensitive
function! stay#isftype(bufnr, ftypes) abort
  let l:candidates = split(getbufvar(a:bufnr, '&filetype'), '\.')
  return !empty(filter(l:candidates, 'index(a:ftypes, v:val) isnot -1'))
endfunction

" Get the buffer state Dictionary for {bufnr}:
" @signature:  stay#getbufstate({bufnr:Expression})
" @returns:    Dictionary
function! stay#getbufstate(bufnr) abort
  let l:state = getbufvar(a:bufnr, '_stay')
  if l:state is ''
    unlet l:state | let l:state = {}
    call setbufvar(a:bufnr, '_stay', l:state)
  endif
  return l:state
endfunction

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
