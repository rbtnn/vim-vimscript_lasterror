
# vim-vimscript\_lasterror [![Build Status](https://travis-ci.org/rbtnn/vim-vimscript_lasterror.svg?branch=master)](https://travis-ci.org/rbtnn/vim-vimscript_lasterror)


This plugin provides to jump to the Vim script's last error.

![](https://raw.githubusercontent.com/rbtnn/vim-vimscript_lasterror/master/vimscript_lasterror.gif)

## Usage

### :VimscriptLastError [-loclist] [-quickfix]
If `-loclist` and `-quickfix` are not specified, jump to the Vim script's last error.  
If `-loclist` is specified, set Vim script's errors to current loclist.  
If `-quickfix` is specified, set Vim script's errors to quickfix.  

## Remarks

* This plugin find Vim script's errors from output of `:messages`.
* This plugin does not support a lambda function's error such as `VimscriptLasterrorComp[1]..<lambda>59`.

## Concepts

* This plugin supports Vim and Neovim.
* This plugin does not provide to customize user-settings.
* This plugin provides only one command.

## Inspired by

* [Vim scriptのエラーメッセージをパースしてquickfixに表示する - Qiita](https://qiita.com/tmsanrinsha/items/0787352360997c387e84)

## License

Distributed under MIT License. See LICENSE.
