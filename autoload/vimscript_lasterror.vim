
scriptencoding utf-8

let s:TEST_LOG = expand('<sfile>:h:h:gs?\?/?') . '/test.log'
let s:TITLE = "Vim script's errors"
let s:LOCLIST = '-loclist'
let s:QUICKFIX = '-quickfix'
let s:MESSAGES = '-messages'

" Does not treat E384 as a error(=`search hit TOP without match for:`)
" Does not treat E385 as a error(=`search hit BOTTOM without match for:`)
" Does not treat E553 as a error(=`No more items`)
let s:NOT_TREAT_PATTERN = '^\(' .. join(['E384', 'E385', 'E553'], '\|') .. '\): '

function! vimscript_lasterror#exec(q_args) abort
	if -1 == index([(s:LOCLIST), (s:QUICKFIX), (s:MESSAGES), ''], a:q_args)
		echohl Error
		echo '[vimscript_lasterror] invalid arguments'
		echohl None
	else
		if s:MESSAGES == a:q_args
			new
			setlocal modifiable noreadonly
			silent! call deletebufline(bufnr(), 1, '$')
			call setbufline(bufnr(), 1, filter(split(execute('messages'), "\n"), { i, x -> !empty(x) }))
			setlocal buftype=nofile nomodifiable readonly
			call clearmatches(winnr())
			call matchadd('Error', '^E\d\+:.*$')
			nnoremap <silent><nowait><buffer><cr>   :<C-u>call vimscript_lasterror#parse_messages_curr()<cr>
		else
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
						if s:find_window_by_path(x['filename'])
							execute printf(':%d', x['lnum'])
						else
							new
							call s:open_file(x['filename'], x['lnum'])
						endif
						normal! zz
						echohl Error
						echo x['text']
						echohl None
					endif
				endif
			else
				echohl Error
				echo "[vimscript_lasterror] could not find any Vim script's errors"
				echohl None
			endif
		endif
	endif
endfunction

function! vimscript_lasterror#parse_messages_curr() abort
	let err_i = line('.') - 1
	let lines = getbufline(bufnr(), 1, '$')
	call map(lines, { i, x -> s:parse_messages(x) })
	if get(lines[err_i], 'kind', '') == 'message'
		for lnum_i in range(err_i - 1, 0, -1)
			if get(lines[lnum_i], 'kind', '') == 'lnum'
				for pos_i in range(lnum_i - 1, 0, -1)
					if get(lines[pos_i], 'kind') == 'pos'
						let x = s:xxx([lines[pos_i]['pos'], str2nr(lines[lnum_i]['lnum']), lines[err_i]['message']])
						if filereadable(get(x, 'filename', ''))
							if s:find_window_by_path(x['filename'])
								execute printf(':%d', x['lnum'])
							else
								new
								call s:open_file(x['filename'], x['lnum'])
							endif
							normal! zz
							echohl Error
							echo x['text']
							echohl None
						endif
						break
					endif
				endfor
				break
			endif
		endfor
	endif
endfunction

function! s:xxx(x) abort
	let file_or_func = a:x[0]
	let lnum = a:x[1]
	let errormsg = a:x[2]

	if -1 != match(file_or_func, '\.\.')
		let file_or_func = split(file_or_func, '\.\.')[-1]
	endif

	if (file_or_func =~# '^function ')
		let file_or_func = file_or_func[9:]
	elseif (file_or_func =~# '^script ')
		let file_or_func = file_or_func[7:]
	endif

	if filereadable(file_or_func)
		return s:new_error(errormsg, file_or_func, expand(file_or_func), lnum)
	elseif file_or_func =~# '^<lambda>'
		let text = printf('%s(%d): %s', file_or_func, lnum, errormsg)
		return s:new_error(text, file_or_func, '', -1)
	else
		try
			let verbose_text = get(split(execute(printf('verbose function %s', file_or_func)), "\n"), 1, '')
			let m = matchlist(verbose_text, '^\s*Last set from \(.*\) line \(\d\+\)$')
			if empty(m)
				let m = matchlist(verbose_text, '^\s*最後にセットしたスクリプト: \(.*\) \%(行\|line\) \(\d\+\)$')
			endif
			if !empty(m)
				return s:new_error(errormsg, file_or_func, expand(m[1]), lnum + str2nr(m[2]))
			else
				let text = printf('%s(%d): %s', file_or_func[len('function '):], lnum, errormsg)
				return s:new_error(text, file_or_func, '', -1)
			endif
		catch
			return s:new_error(v:exception, file_or_func, '', -1)
		endtry
	endif
endfunction

function! s:find_window_by_path(path) abort
	for x in filter(getwininfo(), { _, x -> x['tabnr'] == tabpagenr() })
		if x['bufnr'] == s:strict_bufnr(a:path)
			execute printf(':%dwincmd w', x['winnr'])
			return v:true
		endif
	endfor
	return v:false
endfunction

function! s:strict_bufnr(path) abort
	let bnr = bufnr(a:path)
	let fname1 = fnamemodify(a:path, ':t')
	let fname2 = fnamemodify(bufname(bnr), ':t')
	if (-1 == bnr) || (fname1 != fname2)
		return -1
	else
		return bnr
	endif
endfunction

function! s:open_file(path, lnum) abort
	let bnr = s:strict_bufnr(a:path)
	if -1 == bnr
		execute printf('edit %s', fnameescape(a:path))
	else
		silent! execute printf('buffer %d', bnr)
	endif
	if 0 < a:lnum
		call cursor([a:lnum, 1])
	endif
endfunction

function! vimscript_lasterror#parse_messages() abort
	let xs = []
	let lines = reverse(split(execute('messages'), "\n"))
	call map(lines, { i, x -> s:parse_messages(x) })
	call filter(lines, { i, x -> !empty(x) })
	for err_i in range(0, len(lines) - 1)
		if lines[err_i]['kind'] == 'message'
			for lnum_i in range(err_i + 1, len(lines) - 1)
				if lines[lnum_i]['kind'] == 'lnum'
					for pos_i in range(lnum_i + 1, len(lines) - 1)
						if lines[pos_i]['kind'] == 'pos'
							let x = s:xxx([lines[pos_i]['pos'], str2nr(lines[lnum_i]['lnum']), lines[err_i]['message']])
							if -1 == index(xs, x)
								let xs += [x]
							endif
							break
						endif
					endfor
					break
				endif
			endfor
		endif
	endfor
	return xs
endfunction

function! s:parse_messages(line) abort
	if (a:line =~# '^E\d\+: ') && (a:line !~# s:NOT_TREAT_PATTERN)
		return { 'kind' : 'message', 'message' : a:line, }
	endif

	let lnum_m = matchlist(a:line, '^line\s\+\(\d\+\):$')
	if empty(lnum_m)
		let lnum_m = matchlist(a:line, '^行\s\+\(\d\+\):$')
	endif
	if !empty(lnum_m)
		return { 'kind' : 'lnum', 'lnum' : lnum_m[1], }
	endif

	let pos_m = matchlist(a:line, '^Error detected while \%(processing\|compiling\) \(.*\):$')
	if empty(pos_m)
		let pos_m = matchlist(a:line, '^\(.\{-}\) の処理中にエラーが検出されました:$')
	endif
	if !empty(pos_m)
		return { 'kind' : 'pos', 'pos' : pos_m[1], }
	endif

	return {}
endfunction

function! s:new_error(text, file_or_func, filename, lnum) abort
	return { 'filename' : a:filename, 'lnum' : a:lnum, 'text' : a:text, 'file_or_func' : a:file_or_func, }
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
		\ '" THIS IS A OUTTER COMMENT LINE.',
		\ 'function! s:test_scriptfunc() abort',
		\ '    " THIS IS A INNER COMMENT LINE.',
		\ '    let i = 1 = 2',
		\ 'endfunction',
		\ 'call s:test_scriptfunc()',
		\ ], temp)
	execute printf('source %s', escape(temp, ' \'))
	let xs = vimscript_lasterror#parse_messages()
	call assert_match('^\(E15\|E488\)', xs[0]['text'])
	call assert_match('^<SNR>\d\+_test_scriptfunc$', xs[0]['file_or_func'])
	call assert_equal(4, xs[0]['lnum'])
	call assert_equal(FixPath(temp), FixPath(xs[0]['filename']))

	messages clear
	call writefile([
		\ '" THIS IS A OUTTER COMMENT LINE.',
		\ 'function! Test_globalfunc() abort',
		\ '    " THIS IS AN INNER COMMENT LINE.',
		\ '    let i = 3 = 4',
		\ 'endfunction',
		\ 'call Test_globalfunc()',
		\ ], temp)
	execute printf('source %s', escape(temp, ' \'))
	let xs = vimscript_lasterror#parse_messages()
	call assert_match('^\(E15\|E488\)', xs[0]['text'])
	call assert_equal('Test_globalfunc', xs[0]['file_or_func'])
	call assert_equal(4, xs[0]['lnum'])
	call assert_equal(FixPath(temp), FixPath(xs[0]['filename']))

	messages clear
	call writefile([
		\ '" THIS IS A OUTTER COMMENT LINE.',
		\ 'function! Test_globalfunc() abort',
		\ '    " THIS IS AN INNER COMMENT LINE.',
		\ '    function! s:test_scriptfunc() abort',
		\ '        " THIS IS AN INNER COMMENT LINE.',
		\ '        let i = 5 = 6',
		\ '    endfunction',
		\ '    call s:test_scriptfunc()',
		\ 'endfunction',
		\ 'call Test_globalfunc()',
		\ ], temp)
	execute printf('source %s', escape(temp, ' \'))
	let xs = vimscript_lasterror#parse_messages()
	call assert_match('^\(E15\|E488\)', xs[0]['text'])
	call assert_match('^<SNR>\d\+_test_scriptfunc$', xs[0]['file_or_func'])
	call assert_equal(6, xs[0]['lnum'])
	call assert_equal(FixPath(temp), FixPath(xs[0]['filename']))

	messages clear
	call writefile([
		\ '" THIS IS A OUTTER COMMENT LINE.',
		\ 'let i = 7 = 8',
		\ ], temp)
	execute printf('source %s', escape(temp, ' \'))
	let xs = vimscript_lasterror#parse_messages()
	call assert_match('^\(E15\|E488\)', xs[0]['text'])
	call assert_equal(FixPath(temp), FixPath(xs[0]['file_or_func']))
	call assert_equal(2, xs[0]['lnum'])
	call assert_equal(FixPath(temp), FixPath(xs[0]['filename']))

	messages clear
	call writefile([
		\ '" THIS IS A OUTTER COMMENT LINE.',
		\ 'let F = { -> execute("9 = 10") }',
		\ 'call F()',
		\ ], temp)
	execute printf('source %s', escape(temp, ' \'))
	let xs = vimscript_lasterror#parse_messages()
	call assert_match('^<lambda>\d\+$', xs[0]['file_or_func'])
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
	return filter([(s:LOCLIST), (s:QUICKFIX), (s:MESSAGES)], { i,x -> -1 != match(x, a:ArgLead) })
endfunction

