
let g:loaded_vimscript_lasterror = 1

function! s:vimscript_lasterror() abort
    let x = {}
    let lines = split(execute('messages'), "\n")
    if 3 <= len(lines)
        for i in range(len(lines) - 2, 1, -1)
            let file_or_func = get(matchlist(lines[i - 1], '^Error detected while processing \(.*\):$'), 1, '')
            let lnum = str2nr(get(matchlist(lines[i], '^line\s\+\(\d\+\):$'), 1, '0'))
            let errormsg = lines[i + 1]
            if !empty(file_or_func) && (0 < lnum)
                if filereadable(file_or_func)
                    let x = { 'filename' : file_or_func, 'lnum' : lnum, 'text' : errormsg, }
                    break
                else
                    let m = matchlist(get(split(execute(printf('verbose %s', file_or_func)), "\n"), 1, ''), '^\s*Last set from \(.*\) line \(\d\+\)$')
                    if !empty(m)
                        let x = { 'filename' : m[1], 'lnum' : lnum + str2nr(m[2]), 'text' : errormsg, }
                        break
                    endif
                endif
            endif
        endfor
    endif
    echohl Error
    if !empty(x)
        execute printf('silent %s%s +%d %s', (&modified ? 'new' : 'edit'), a:q_bang, x['lnum'], escape(x['filename'], ' '))
        echo printf('%s(%d): %s', fnamemodify(x['filename'], ':.'), x['lnum'], x['text'])
    else
        echo "[vimscript_lasterror] could not find Vim script's last error"
    endif
    echohl None
endfunction

command! -nargs=0  VimscriptLastError :call <SID>vimscript_lasterror()

