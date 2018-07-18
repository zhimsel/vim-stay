" AUTOLOAD FUNCTION LIBRARY FOR VIM-STAY
" Window handling functions
if &compatible || v:version < 700
  finish
endif

let s:cpoptions = &cpoptions
set cpoptions&vim

" PUBLIC API {{{
" Shim for versions of Vim without native window ID support
if v:version < 704 || (v:version is 704 && !has('patch1518'))
  if has('windows')
    let s:needbeam = 1

    " Get a list of window IDs for windows containing buffer {bufnr}:
    " @signature:  stay#win#findbuf({bufnr:Number)
    " @returns:    List<Number>
    " @see:        |win_findbuf()|
    function! stay#win#findbuf(bufnr) abort
      let l:winnids = []
      let l:tabnrs  = range(1, tabpagenr('$'))
      call filter(l:tabnrs, 'index(tabpagebuflist(v:val), a:bufnr) isnot -1')
      if !empty(l:tabnrs)
        let l:home = s:home()
        try
          for l:tab in l:tabnrs
            call s:beam('tab', l:tab)
            let l:bufwins  = filter(range(1, winnr('$')), 'winbufnr(v:val) is a:bufnr')
            let l:winnids += map(l:bufwins, 'stay#win#getid(v:val)')
          endfor
        finally
          call s:scotty(l:home)
        endtry
      endif
      return l:winnids
    endfunction

  else " Stubs for Vim with no support for multiple windows
    function! stay#win#findbuf(bufnr) abort
      return bufnr('%') is a:bufnr ? [1] : []
    endfunction
  endif

else " Wrapper around native window ID functions
  function! stay#win#findbuf(bufnr) abort
    return win_findbuf(a:bufnr)
  endfunction
endif

" Shims for versions of Vim without native window ID support
if v:version < 704 || (v:version is 704 && !has('patch1517'))
  if has('windows')
    let s:needbeam = 1
    let s:idvar    = '_winid' " global counter and window ID var name
    let s:maxid    = 0        " shadow and sanity check for global counter

    " Get the window ID for the specified window:
    " @signature:  stay#win#getid([{win:Number}[, {tab:Number}]])
    " @returns:    Number
    " @see:        |win_getid()|
    " @caveats:    Although the Number ID returned is guaranteed to be unique
    "              for every window this function is called on, the IDs are
    "              assigned lazily, not internally for every created window
    "              like with the native functions. They neither match
    "              - the creation sequence of windows
    "              - the total number of active or created windows
    function! stay#win#getid(...) abort
      let l:winnr = a:0 > 0 ? a:1 : winnr()
      let l:tabnr = a:0 > 1 ? a:2 : tabpagenr()

      let l:winid = gettabwinvar(l:tabnr, l:winnr, s:idvar)
      if !empty(l:winid) | return l:winid | endif

      let l:winid     = max([get(g:, s:idvar, 0), s:maxid]) + 1
      let s:maxid     = l:winid
      let g:{s:idvar} = l:winid
      call settabwinvar(l:tabnr, l:winnr, s:idvar, l:winid)
      return l:winid
    endfunction

    " Go to the window with ID {expr}:
    " @signature:  stay#win#gotoid({expr:Expression})
    " @returns:    Boolean (false if the window cannot be found)
    " @see:        |win_gotoid()|
    function! stay#win#gotoid(expr) abort
      let l:target = stay#win#id2tabwin(a:expr)
      let l:home   = s:home()
      if !s:beam('tab', l:target[0]) || !s:beam('win', l:target[1])
        call s:scotty(l:home)
        return 0
      endif
      return 1
    endfunction

    " Get the tab and window number of the window with ID {expr}
    " @signature:  stay#win#id2tabwin({expr:Expression})
    " @returns:    List<Number>
    " @see:        |win_id2tabwin()|
    function! stay#win#id2tabwin(expr) abort
      if tabpagenr('$') > 1
        let l:home = s:home()
        try
          for l:tabnr in range(1, tabpagenr('$'))
            call s:beam('tab', l:tabnr)
            let l:winnr = stay#win#id2win(a:expr)
            if l:winnr isnot 0
              return [tabpagenr(), l:winnr]
            endif
          endfor
          return [0, 0]
        finally " restore active tab page and window
          call s:scotty(l:home)
        endtry
      else
        let l:winnr = stay#win#id2win(a:expr)
        return l:winnr isnot 0 ? [1, l:winnr] : [0, 0]
      endif
    endfunction

    " Get the window number of the window with ID {expr}
    " @signature:  stay#win#id2win({expr:Expression})
    " @returns:    Number
    " @see:        |win_id2win()|
    function! stay#win#id2win(expr) abort
      let l:wincnt = range(1, winnr('$'))
      let l:winnrs = filter(l:wincnt, 'getwinvar(v:val, '.string(s:idvar).') is '.string(a:expr))
      return empty(l:winnrs) ? 0 : l:winnrs[0]
    endfunction

  else " Stubs for Vim with no support for multiple windows
    function! stay#win#getid(...) abort
      return get(a:, 1, 1) is 1 && get(a:, 2, 1) is 1
    endfunction

    function! stay#win#gotoid(expr) abort
      return a:expr is 1
    endfunction

    function! stay#win#id2tabwin(expr) abort
      return a:expr is 1 ? [1, 1] : [0, 0]
    endfunction

    function! stay#win#id2win(expr) abort
      return a:expr is 1
    endfunction
  endif

else " Wrappers around native window ID functions
  function! stay#win#getid(...) abort
    return call('win_getid', a:000)
  endfunction

  function! stay#win#gotoid(expr) abort
    return win_gotoid(a:expr)
  endfunction

  function! stay#win#id2tabwin(expr) abort
    return win_id2tabwin(a:expr)
  endfunction

  function! stay#win#id2win(expr) abort
    return win_id2win(a:expr)
  endfunction
endif "}}}

" PRIVATE API {{{
if get(s:, 'needbeam', 0) is 1
  " - activate a window or tab without leaving a trail
  let s:beamdcmds = { 'tab': 'tabnext %i', 'win': '%iwincmd w' }
  let s:beamtests = { 'tab': 'tabpagenr', 'win': 'winnr' }
  function! s:beam(scope, number) abort
    if a:number < 1 || call(s:beamtests[a:scope], []) is a:number
      return 1
    endif
    silent execute 'noautocmd' 'keepalt' printf(s:beamdcmds[a:scope], a:number)
    return call(s:beamtests[a:scope], []) is a:number
  endfunction

  " - nothing like home in the void
  function! s:home() abort
    return [tabpagenr(), winnr()]
  endfunction

  " - go home. fast.
  function! s:scotty(home) abort
    return s:beam('tab', a:home[0]) && s:beam('win', a:home[1])
  endfunction
endif "}}}

let &cpoptions = s:cpoptions
unlet! s:cpoptions s:needbeam

" vim:set sw=2 sts=2 ts=2 et fdm=marker fmr={{{,}}}:
