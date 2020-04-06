" =============================================================
" Name:         vim-blameline
" Maintainer:   Danish Prakash
" HomePage:     https://github.com/danishprakash/vim-blameline
" License:      GNU GPL
" =============================================================


let s:timer_id = -1
let s:blameline_delay = 1000


function! s:syntax() abort
    syntax match BLAMELINE /::.*::/
    highlight link BLAMELINE Comment
endfunction

function! s:clear_blameline() abort
    if !has('nvim-0.3.2')
        return
    endif

    let l:buffer = bufnr('')

    call nvim_buf_clear_highlight(l:buffer, 1000, 0, -1)
endfunction


function! s:show_blame(message, hl_group) abort
    if !has('nvim-0.3.2')
        return
    endif

    let l:cursor_position = getcurpos()
    let l:line = line('.')
    let l:buffer = bufnr('')
    let l:prefix = '  '

    call nvim_buf_set_virtual_text(l:buffer, 1000, l:line-1, [[l:prefix.a:message, a:hl_group]], {})

endfunction


function! s:get_blameline(lineno) abort
    " TODO: run this as an async job

    let l:filename = expand("%:p")
    let l:cmd = join([
                \ 'git',
                \ '--no-pager',
                \ 'blame',
                \ '-L',
                \ a:lineno . ',' . a:lineno,
                \ '--relative-date',
                \ l:filename
                \ ], ' ')

    " TODO: check for git command failure
    return join(systemlist(l:cmd))
endfunction

function! s:parse_blameline(bline)
    let l:content = ""

    let l:bline = split(a:bline)
    let l:commit_sha = l:bline[0]
    let l:message = join(l:bline[1:])

    if l:commit_sha ==# '00000000'
        let l:content = "Not commited yet"
    else
        let l:content = substitute(l:message, '\v([^\(]*\([^\)]*\)).*$', '\1', '')
        let l:content = substitute(l:content, '(\|)', '', 'g')
        let l:content = split(l:content)
        let l:content = join(l:content[:len(l:content)-2])
    endif

    return l:content
endfunction

function! s:set_blameline_with_delay(delay) abort
    let l:lineno = getcurpos()[1]
    let l:line = s:parse_blameline(s:get_blameline(l:lineno))
    let l:hl_group = 'Comment'

    call s:show_blame(l:line, l:hl_group)

    " reset timer ID to prevent unnecessary timer_stop() invocations
    let s:timer_id = -1 
endfunction

function! blameline#Enable() abort
    call s:set_blameline()
    augroup Blameline
        autocmd!
        autocmd CursorMoved * call s:set_blameline()
        autocmd InsertEnter * call s:clear_blameline()
    augroup END
endfunction

function! s:stop_cursor_timer() abort
    if s:timer_id != -1
        call timer_stop(s:timer_id)
        let s:timer_id = -1
    endif
endfunction

function! s:set_blameline() abort
    if exists('g:blameline_delay')
        let s:blameline_delay = get(g:, 'blameline_delay', 1000)
    endif

    call s:clear_blameline()
    call s:stop_cursor_timer()
    let s:timer_id = timer_start(s:blameline_delay, 
                            \ function('s:set_blameline_with_delay'), 
                            \ {})
endfunction

function! s:err(msg) abort
    echohl ErrorMsg
    echom 'Blameline: '.a:msg
    echohl None
endfunction

function! blameline#Disable() abort
    call s:clear_blameline()
    augroup Blameline
        autocmd!
    augroup END
    augroup! Blameline
endfunction
