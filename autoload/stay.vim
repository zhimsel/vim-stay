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
  function! stay#istemp(path) abort
    for l:tempdir in split(&backupskip, '\v\\@<!%(\\\\)*,')
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

" Check if {file} is a view session file:
" @signature:  stay#isviewfile({file:String})
" @returns:    Boolean (-1 if unable to check)
let s:viewdir = {'option': '', 'path': ''}
let s:s_event = '\C\vdoauto%[all]!?%(\s+<nomodeline>)?%(\s+\S+)?\s+SessionLoadPost'
let s:s_load  = '\C\unl%[et]!?\s+SessionLoad'
function! stay#isviewfile(file) abort
  " cache transformed 'viewdir' value accounting for misformatted directory
  " specification and option-escaped spaces
  if s:viewdir.option isnot &viewdir
    let s:viewdir.option = &viewdir
    let s:viewdir.path   = substitute(s:viewdir.option, '\v[/\\]*$', '', '')
    let s:viewdir.path   = substitute(s:viewdir.path, '\v\\@<!(\\\\)*\\ ', ' ', 'g')
  endif

  " anything outside 'viewdir' is not a view file
  if stridx(a:file, s:viewdir.path) isnot 0 | return 0 | endif

  " look into the file for signature commands:
  " - `doautoall SessionLoadPost` is characteristic of views and session files
  " - `unlet SessionLoad` is exclusive to session files
  try
    let l:tail = readfile(a:file, '', -5)
    return match(l:tail, s:s_event) isnot -1 && match(l:tail, s:s_load) is -1
  catch
  endtry
  return -1
endfunction

let &cpoptions = s:cpoptions
unlet! s:cpoptions

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
