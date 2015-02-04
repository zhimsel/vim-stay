[![Project status][badge-status]][vimscripts]
[![Current release][badge-release]][releases]
[![Open issues][badge-issues]][issues]
[![License][badge-license]][license]

## Stay at my cursor, boy!

*vim-stay* adds automated view session creation and restoration whenever editing a buffer, across Vim sessions and window life cycles. It also alleviates Vim's tendency to lose view state when cycling through buffers (via `argdo`, `bufdo` et al.). It is smart about which buffers should be persisted and which should not, making the procedure painless and invisible.

If you have wished Vim would be smarter about keeping your editing state, *vim-stay* is for you.

### Installation

1. The old way: download and source the vimball from the [releases page][releases], then run `:helptags {dir}` on your runtimepath/doc directory. Or,
2. The plug-in manager way: using a git-based plug-in manager (Pathogen, Vundle, NeoBundle etc.), simply add `kopischke/vim-stay` to the list of plug-ins, source that and issue your manager's install command.

### Usage

Recommended: `set viewoptions=cursor,folds,slash,unix`. Edit as usual. See the [documentation][doc] for more.

### Rationale

Keeping editing session state should be a given in an editor; unluckily, Vim's solution for this, *view sessions*, are not easily automated [without encountering painful bumps][mkview-wikia]. As the one plug-in I found that aims to fix this, Zhou Yi Chao’s [*restore_view.vim*][chao-plugin], limits itself to Vim editing sessions, doesn’t play well with other position setting plug-ins like my own [vim-fetch][vim-fetch] and as [I wasn’† very happy with its heuristics][heuristics], I wrote my own.

### License

*vim-stay* is licensed under [the terms of the MIT license according to the accompanying license file][license].

[badge-status]:  http://img.shields.io/badge/status-active-brightgreen.svg?style=flat-square
[badge-release]: http://img.shields.io/github/release/kopischke/vim-stay.svg?style=flat-square
[badge-issues]:  http://img.shields.io/github/issues/kopischke/vim-stay.svg?style=flat-square
[badge-license]: http://img.shields.io/badge/license-MIT-blue.svg?style=flat-square
[chao-plugin]:   http://www.vim.org/scripts/script.php?script_id=4021
[doc]:           doc/vim-stay.txt
[heuristics]:    https://github.com/kopischke/vim-stay/issues/2
[issues]:        https://github.com/kopischke/vim-stay/issues
[license]:       LICENSE.md
[mkview-wikia]:  http://vim.wikia.com/wiki/Make_views_automatic
[releases]:      https://github.com/kopischke/vim-stay/releases
[vim-fetch]:     http://www.vim.org/scripts/script.php?script_id=5089
[vimscripts]:    http://www.vim.org/scripts/script.php?script_id=5099
