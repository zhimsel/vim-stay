# Stay at my cursor, boy!

[![Project status][badge-status]][vimscripts]
[![Current release][badge-release]][releases]
[![Open issues][badge-issues]][issues]
[![License][badge-license]][license]
[![Lint status][badge-lint]][job-lint]

*vim-stay* adds automated view session creation and restoration whenever editing a buffer, across Vim sessions and window life cycles. It also alleviates Vim's tendency to lose view state when cycling through buffers (via `argdo`, `bufdo` et al.). It is smart about which buffers should be persisted and which should not, making the procedure painless and invisible.

If you have wished Vim would be smarter about keeping your editing state, *vim-stay* is for you.

## Installation

1. The old way: download and source the vimball from the [releases page][releases], then run `:helptags {dir}` on your runtimepath/doc directory. Updating the plug-in via `:GetLatestVimScripts` is supported. Or,
1. The plug-in manager way: using a git-based plug-in manager (Pathogen, Vundle, NeoBundle, Vim-Plug etc.), simply add `zhimsel/vim-stay` to the list of plug-ins, source that and issue your manager's install command. Or,
1. The Vim package way (requires Vim 7.4 with patch 1384): create a `pack/vim-stay/start/` directory in your `'packagepath'` and clone this repository into it. Run `:helptags {dir}` on the `doc` directory of the created repo. Run `:runtime plugin/stay.vim` to load *vim-stay* (or restart Vim).

## Usage

Recommended: `set viewoptions=cursor,folds,slash,unix` (but at the very least do `set viewoptions-=options`). Edit as usual. See the [documentation][doc] for more.

## Rationale

Keeping editing session state should be a given in an editor; unluckily, Vim's solution for this, *view sessions*, are not easily automated [without encountering painful bumps][mkview-wikia]. As the one plug-in available that aimed to fix this, Zhou Yi Chao’s [*restore_view.vim*][chao-plugin], limited itself to Vim editing sessions, didn’t play well with other position setting plug-ins like [vim-fetch][vim-fetch] and as there were [some issues with its heuristics][heuristics], *vim-stay* was born.

## License

*vim-stay* is licensed under [the terms of the MIT license according to the accompanying license file][license].

[badge-status]:  https://img.shields.io/badge/status-maintained-green.svg?style=flat-square
[badge-release]: https://img.shields.io/github/release/zhimsel/vim-stay.svg?style=flat-square
[badge-issues]:  https://img.shields.io/github/issues/zhimsel/vim-stay.svg?style=flat-square
[badge-license]: https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square
[badge-lint]:    https://img.shields.io/github/actions/workflow/status/zhimsel/vim-stay/lint.yaml?label=linting
[job-lint]:      https://github.com/zhimsel/vim-stay/actions/workflows/lint.yaml
[chao-plugin]:   http://www.vim.org/scripts/script.php?script_id=4021
[doc]:           doc/vim-stay.txt
[heuristics]:    https://github.com/zhimsel/vim-stay/issues/2
[issues]:        https://github.com/zhimsel/vim-stay/issues
[license]:       LICENSE.md
[mkview-wikia]:  http://vim.wikia.com/wiki/Make_views_automatic
[releases]:      https://github.com/zhimsel/vim-stay/releases
[vim-fetch]:     http://www.vim.org/scripts/script.php?script_id=5089
[vimscripts]:    http://www.vim.org/scripts/script.php?script_id=5099
