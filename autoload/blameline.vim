" =============================================================
" Name:         nvim-blameline
" Maintainer:   Danish Prakash
" HomePage:     https://github.com/danishprakash/nvim-blameline
" License:      GNU GPL
" =============================================================


let s:timer_id = -1
let s:blameline_delay = 1000

" avoid setting autocmd(s) for the following filetypes (non-exhaustive)
let g:blameline_filetype_blacklist = [
\   'help',
\   'nerdtree',
\   'quickfix',
\   'tags',
\]

" to show blameline on the buffer or not
function s:should_not_enable() abort
    let l:buffer = bufnr('')
    let l:filetype = getbufvar(l:buffer, '&filetype')

    " do nothing when there's no filetype.
    if l:filetype is# ''
        return 1
    endif

    " do nothing if it's a blacklisted filetype
    if index(get(g:, 'blameline_filetype_blacklist', []), l:filetype) >= 0
        return 1
    endif

    " do nothing in terminal buffers
    let l:buftype = getbufvar(l:buffer, '&buftype')
    if l:buftype is# 'terminal'
        return 1
    endif

    " do nothing for directories.
    let l:filename = fnamemodify(bufname(l:buffer), ':t')
    if l:filename is# '.'
        return 1
    endif
endfunction

" clears the blameline from the buffer
function! s:clear_blameline() abort
    if !has('nvim-0.3.2')
        return
    endif

    call s:stop_cursor_timer()

    let l:buffer = bufnr('')
    call nvim_buf_clear_highlight(l:buffer, 1000, 0, -1)
endfunction

" api call to show virtual text
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

" gets blame info for lineno
function! s:get_blameline(lineno) abort
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
    return join(systemlist(l:cmd))
endfunction

" strips blame output of unwanted info
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

" show blameline with delay
function! s:set_blameline_with_delay(delay) abort
    let l:lineno = getcurpos()[1]
    let l:line = s:parse_blameline(s:get_blameline(l:lineno))
    let l:hl_group = 'Comment'

    call s:show_blame(l:line, l:hl_group)

    " reset timer ID to prevent unnecessary timer_stop() invocations
    let s:timer_id = -1 
endfunction

" creates autocmds for the plugin
function! blameline#Enable() abort
    call s:set_blameline()
    augroup Blameline
        autocmd!
        autocmd CursorMoved * call s:set_blameline()
        autocmd InsertEnter * call s:clear_blameline()
        autocmd TermEnter * call s:clear_blameline()  " HACK
    augroup END
endfunction

" stops running timers with callbacks
function! s:stop_cursor_timer() abort
    if s:timer_id != -1
        call timer_stop(s:timer_id)
        let s:timer_id = -1
    endif
endfunction

" wrapper over set_blameline_with_delay
function! s:set_blameline() abort
    if s:should_not_enable() > 0
        call s:stop_cursor_timer()
        return
    endif

    if exists('g:blameline_delay')
        let s:blameline_delay = get(g:, 'blameline_delay', 1000)
    endif

    call s:clear_blameline()
    call s:stop_cursor_timer()

    let s:timer_id = timer_start(s:blameline_delay, 
                            \ function('s:set_blameline_with_delay'), 
                            \ {})
endfunction

" disable blameline
function! blameline#Disable() abort
    call s:clear_blameline()
    augroup Blameline
        autocmd!
    augroup END
    augroup! Blameline
endfunction
