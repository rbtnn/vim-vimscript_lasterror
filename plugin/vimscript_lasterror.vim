
scriptencoding utf-8

let g:loaded_vimscript_lasterror = 1

let s:LOCLIST = '-loclist'

function! s:vimscript_lasterror(q_args) abort
    let xs = []
    let lines = split(execute('messages'), "\n")
    if 3 <= len(lines)
        for i in range(len(lines) - 2, 1, -1)
            let file_or_func = get(matchlist(lines[i - 1], '^Error detected while processing \(.*\):$'), 1, '')
            let lnum = str2nr(get(matchlist(lines[i], '^line\s\+\(\d\+\):$'), 1, '0'))
            if empty(file_or_func)
                let file_or_func = get(matchlist(lines[i - 1], '^\(.\{-}\) の処理中にエラーが検出されました:$'), 1, '')
                let lnum = str2nr(get(matchlist(lines[i], '^行\s\+\(\d\+\):$'), 1, '0'))
            endif
            let errormsg = lines[i + 1]
            if !empty(file_or_func) && (0 < lnum)
                if filereadable(file_or_func)
                    let x = { 'filename' : expand(file_or_func), 'lnum' : lnum, 'text' : errormsg, }
                    if s:LOCLIST == a:q_args
                        let xs += [x]
                    else
                        let xs = [x]
                        break
                    endif
                else
                    let verbose_text = get(split(execute(printf('verbose %s', file_or_func)), "\n"), 1, '')
                    let m = matchlist(verbose_text, '^\s*Last set from \(.*\) line \(\d\+\)$')
                    if empty(m)
                        let m = matchlist(verbose_text, '^\s*最後にセットしたスクリプト: \(.*\) 行 \(\d\+\)$')
                    endif
                    if !empty(m)
                        let x = { 'filename' : expand(m[1]), 'lnum' : lnum + str2nr(m[2]), 'text' : errormsg, }
                        if s:LOCLIST == a:q_args
                            let xs += [x]
                        else
                            let xs = [x]
                            break
                        endif
                    endif
                endif
            endif
        endfor
    endif
    echohl Error
    if !empty(xs)
        if s:LOCLIST == a:q_args
            call setloclist(0, reverse(xs))
        else
            let x = xs[-1]
            execute printf('silent %s +%d %s', (&modified ? 'new' : 'edit'), x['lnum'], escape(x['filename'], ' '))
            echo printf('%s(%d): %s', fnamemodify(x['filename'], ':.'), x['lnum'], x['text'])
        endif
    else
        echo "[vimscript_lasterror] could not find Vim script's last error"
    endif
    echohl None
endfunction

function! VimscriptLasterrorComp(ArgLead, CmdLine, CursorPos) abort
    return [(s:LOCLIST)]
endfunction

command! -nargs=? -complete=customlist,VimscriptLasterrorComp  VimscriptLastError :call <SID>vimscript_lasterror(<q-args>)

