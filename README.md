
# vim-vimscript\_lasterror
[![vim](https://github.com/rbtnn/vim-vimscript_lasterror/workflows/vim/badge.svg)](https://github.com/rbtnn/vim-vimscript_lasterror/actions?query=workflow%3Avim)
[![neovim](https://github.com/rbtnn/vim-vimscript_lasterror/workflows/neovim/badge.svg)](https://github.com/rbtnn/vim-vimscript_lasterror/actions?query=workflow%3Aneovim)

This plugin provides to jump to the Vim script's last error.

![](https://raw.githubusercontent.com/rbtnn/vim-vimscript_lasterror/master/vimscript_lasterror.gif)

## Usage

### :VimscriptLastError [-loclist] [-quickfix] [-messages]
If arguments are not specified, try jumping to the Vim script's last error.  
If `-loclist` is specified, set Vim script's errors to current loclist.  
If `-quickfix` is specified, set Vim script's errors to quickfix.  
If `-messages` is specified, dump the output of `:messages` to new window.
Typing `<cr>` under a Vim script's error line in the window, You can jump to the location.


## Remarks

* This plugin find Vim script's errors from output of `:messages`.
" This plugin does not treat E384 as a error(=`search hit TOP without match for:`)
" This plugin does not treat E385 as a error(=`search hit BOTTOM without match for:`)
" This plugin does not treat E553 as a error(=`No more items`)

## Concepts

* This plugin supports Vim and Neovim.
* This plugin does not provide to customize user-settings.
* This plugin provides only one command.

## Inspired by

* [Vim scriptのエラーメッセージをパースしてquickfixに表示する - Qiita](https://qiita.com/tmsanrinsha/items/0787352360997c387e84)

## License

Distributed under MIT License. See LICENSE.
