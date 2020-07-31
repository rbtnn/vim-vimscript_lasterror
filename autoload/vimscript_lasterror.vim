
scriptencoding utf-8

let s:TEST_LOG = expand('<sfile>:h:h:gs?\?/?') . '/test.log'
let s:TITLE = "Vim script's errors"
let s:LOCLIST = '-loclist'
let s:QUICKFIX = '-quickfix'

function! vimscript_lasterror#exec(q_args) abort
    try
        if -1 == index([(s:LOCLIST), (s:QUICKFIX), ''], a:q_args)
            throw '[vimscript_lasterror] invalid arguments'
        endif
        let xs = vimscript_lasterror#parse_messages()
        if !empty(xs)
            if s:LOCLIST == a:q_args
                call setloclist(0, reverse(xs), 'r')
                call setloclist(0, [], 'r', { 'title': s:TITLE, })
            elseif s:QUICKFIX == a:q_args
                call setqflist(reverse(xs), 'r')
                call setqflist([], 'r', { 'title': s:TITLE, })
            else
                let x = xs[0]
                if filereadable(get(x, 'filename', ''))
                    execute printf('silent %s +%d %s', (&modified ? 'new' : 'edit'), x['lnum'], escape(x['filename'], ' '))
                    normal! zz
                    throw printf('%s(%d): %s', fnamemodify(x['filename'], ':.'), x['lnum'], x['text'])
                else
                    let text = ''
                    if !empty(get(x, 'filename', ''))
                        let text = text . x['filename']
                    endif
                    if has_key(x, 'lnum')
                        let text = text . printf('(%d)', x['lnum'])
                    endif
                    if !empty(text)
                        let text = text . ':'
                    endif
                    if has_key(x, 'text')
                        let text = text . ' ' . x['text']
                    endif
                    throw text
                endif
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

function! vimscript_lasterror#parse_messages() abort
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
                if -1 != match(file_or_func, '\.\.')
                    let file_or_func = split(file_or_func, '\.\.')[-1]
                endif

                if (file_or_func =~# '^function ')
                    let file_or_func = file_or_func[9:]
                elseif (file_or_func =~# '^script ')
                    let file_or_func = file_or_func[7:]
                endif

                if filereadable(file_or_func)
                    let xs += [{ 'filename' : expand(file_or_func), 'lnum' : lnum, 'text' : errormsg, }]
                elseif file_or_func =~# '^<lambda>'
                    let text = printf('%s(%d): %s', file_or_func, lnum, errormsg)
                    let xs += [{ 'text' : text, }]
                else
                    try
                        let verbose_text = get(split(execute(printf('verbose function %s', file_or_func)), "\n"), 1, '')
                        let m = matchlist(verbose_text, '^\s*Last set from \(.*\) line \(\d\+\)$')
                        if empty(m)
                            let m = matchlist(verbose_text, '^\s*最後にセットしたスクリプト: \(.*\) \%(行\|line\) \(\d\+\)$')
                        endif
                        if !empty(m)
                            let xs += [{ 'filename' : expand(m[1]), 'lnum' : lnum + str2nr(m[2]), 'text' : errormsg, }]
                        else
                            let text = printf('%s(%d): %s', file_or_func[len('function '):], lnum, errormsg)
                            let xs += [{ 'text' : text, }]
                        endif
                    catch
                        let xs += [{ 'text' : v:exception, }]
                    endtry
                endif
            endif
        endfor
    endif
    return xs
endfunction

function! vimscript_lasterror#run_tests() abort
    if filereadable(s:TEST_LOG)
        call delete(s:TEST_LOG)
    endif

    let v:errors = []

    let FixPath = { path -> substitute(path, '[\/]\+', '/', 'g') }

    let temp = tempname()

    messages clear
    call writefile([
        \ 'function! s:test_1() abort',
        \ '    let i = 1 = 2',
        \ 'endfunction',
        \ 'call s:test_1()',
        \ ], temp)
    execute printf('source %s', escape(temp, ' \'))
    let xs = vimscript_lasterror#parse_messages()
    call assert_match('^E15', xs[0]['text'])
    call assert_equal(2, xs[0]['lnum'])
    call assert_equal(FixPath(temp), FixPath(xs[0]['filename']))

    messages clear
    call writefile([
        \ 'let i = 3 = 4',
        \ ], temp)
    execute printf('source %s', escape(temp, ' \'))
    let xs = vimscript_lasterror#parse_messages()
    call assert_match('^E15', xs[0]['text'])
    call assert_equal(1, xs[0]['lnum'])
    call assert_equal(FixPath(temp), FixPath(xs[0]['filename']))

    messages clear
    call writefile([
        \ 'let F = { -> execute("5 = 6") }',
        \ 'call F()',
        \ ], temp)
    execute printf('source %s', escape(temp, ' \'))
    let xs = vimscript_lasterror#parse_messages()
    call assert_match('^<lambda>\d\+(1): \(E488:\|E16:\)', xs[0]['text'])

    call delete(temp)

    if !empty(v:errors)
        call writefile(v:errors, s:TEST_LOG)
        for err in v:errors
            echohl Error
            echo err
            echohl None
        endfor
    endif
endfunction

function! vimscript_lasterror#comp(ArgLead, CmdLine, CursorPos) abort
    return filter([(s:LOCLIST), (s:QUICKFIX)], { i,x -> -1 != match(x, a:ArgLead) })
endfunction

