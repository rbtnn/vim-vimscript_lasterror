
# vim-vimscript\_lasterror
[![vim](https://github.com/rbtnn/vim-vimscript_lasterror/workflows/vim/badge.svg)](https://github.com/rbtnn/vim-vimscript_lasterror/actions?query=workflow%3Avim)
[![neovim](https://github.com/rbtnn/vim-vimscript_lasterror/workflows/neovim/badge.svg)](https://github.com/rbtnn/vim-vimscript_lasterror/actions?query=workflow%3Aneovim)

This plugin provides to jump to the Vim script's last error.

![](https://raw.githubusercontent.com/rbtnn/vim-vimscript_lasterror/master/vimscript_lasterror.gif)

## Usage

### :VimscriptLastError [-loclist] [-quickfix]
If `-loclist` and `-quickfix` are not specified, jump to the Vim script's last error.  
If `-loclist` is specified, set Vim script's errors to current loclist.  
If `-quickfix` is specified, set Vim script's errors to quickfix.  

## Remarks

* This plugin find Vim script's errors from output of `:messages`.
* Ignore E384 and E385.

## Concepts

* This plugin supports Vim and Neovim.
* This plugin does not provide to customize user-settings.
* This plugin provides only one command.

## Inspired by

* [Vim scriptのエラーメッセージをパースしてquickfixに表示する - Qiita](https://qiita.com/tmsanrinsha/items/0787352360997c387e84)

## License

Distributed under MIT License. See LICENSE.
