
scriptencoding utf-8

let g:loaded_vimscript_lasterror = 1

let s:TITLE = "Vim script's errors"

let s:LOCLIST = '-loclist'
let s:QUICKFIX = '-quickfix'

function! s:vimscript_lasterror(q_args) abort
    try
        if -1 == index([(s:LOCLIST), (s:QUICKFIX), ''], a:q_args)
            throw '[vimscript_lasterror] invalid arguments'
        endif
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
                        if (s:LOCLIST == a:q_args) || (s:QUICKFIX == a:q_args)
                            let xs += [x]
                        else
                            let xs = [x]
                            break
                        endif
                    else
                        if (file_or_func =~# '^function ') && (-1 != match(file_or_func, '\.\.'))
                            let file_or_func = printf('function %s', split(file_or_func, '\.\.')[-1])
                        endif
                        if file_or_func =~# '^function <lambda>'
                            let text = printf('%s(%d): %s', file_or_func[len('function '):], lnum, errormsg)
                            if (s:LOCLIST == a:q_args) || (s:QUICKFIX == a:q_args)
                                let xs += [{ 'text' : text, }]
                            else
                                throw text
                            endif
                        else
                            let verbose_text = get(split(execute(printf('verbose %s', file_or_func)), "\n"), 1, '')
                            let m = matchlist(verbose_text, '^\s*Last set from \(.*\) line \(\d\+\)$')
                            if empty(m)
                                let m = matchlist(verbose_text, '^\s*最後にセットしたスクリプト: \(.*\) 行 \(\d\+\)$')
                            endif
                            if !empty(m)
                                let x = { 'filename' : expand(m[1]), 'lnum' : lnum + str2nr(m[2]), 'text' : errormsg, }
                                if (s:LOCLIST == a:q_args) || (s:QUICKFIX == a:q_args)
                                    let xs += [x]
                                else
                                    let xs = [x]
                                    break
                                endif
                            endif
                        endif
                    endif
                endif
            endfor
        endif
        if !empty(xs)
            if s:LOCLIST == a:q_args
                call setloclist(0, reverse(xs), 'r')
                call setloclist(0, [], 'r', { 'title': s:TITLE, })
            elseif s:QUICKFIX == a:q_args
                call setqflist(reverse(xs), 'r')
                call setqflist([], 'r', { 'title': s:TITLE, })
            else
                let x = xs[-1]
                execute printf('silent %s +%d %s', (&modified ? 'new' : 'edit'), x['lnum'], escape(x['filename'], ' '))
                normal! zz
                throw printf('%s(%d): %s', fnamemodify(x['filename'], ':.'), x['lnum'], x['text'])
            endif
        else
            throw "[vimscript_lasterror] could not find any Vim script's errors"
        endif
    catch
        echohl Error
        echo v:exception
        echohl None
    endtry
endfunction

function! VimscriptLasterrorComp(ArgLead, CmdLine, CursorPos) abort
    return filter([(s:LOCLIST), (s:QUICKFIX)], { i,x -> -1 != match(x, a:ArgLead) })
endfunction

command! -nargs=? -complete=customlist,VimscriptLasterrorComp  VimscriptLastError :call <SID>vimscript_lasterror(<q-args>)

