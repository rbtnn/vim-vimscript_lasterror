
let g:loaded_vimscript_lasterror = 1

command! -nargs=? -complete=customlist,vimscript_lasterror#comp  VimscriptLastError :call vimscript_lasterror#exec(<q-args>)

