" TODO: also you need to figure out how to avoid the cursor from
"       moving to the metadata on the same line while pressing
"       `w` or `e`
" TODO: add header for this file, similar to py-splice
" TODO: raise proper errors
" TODO: use threads for parallel execution
" TODO: add delay after every line change/function invocation
"       see below
" TODO: add g:blameline_delay for offset of meta display
"       this will update the updatetime value of CursorHold
"       event in vim
" TODO: skip files that are not a valid git directory 

let g:line_visited = ""
let g:line_meta_mapping = {}
let g:line_content_mapping = {}


function! s:syntax() abort
    syntax match BLAMELINE /::.*::/
    highlight link BLAMELINE Comment
endfunction


function! blameline#run(flag) abort
    let py_exe = has('python3') ? 'python3' : 'python'
    call s:syntax()
    execute py_exe "<< EOF"

import vim



EOF
endfunction


function! blameline#run(flag) abort
    let py_exe = has('python3') ? 'python3' : 'python'
    call s:syntax()
    execute py_exe "<< EOF"

import os
import re
import vim
import threading
import subprocess


def _get_current_row_column():
    return (vim.eval("getpos('.')")[1:3])


def _get_current_line_length():
    return int(vim.eval('col("$")'))


def _get_blame_output():
    file_path = vim.eval('expand("%:p")')
    output = subprocess.check_output(['git', 'blame', file_path])
    output = output.decode('utf-8').split('\n')[:-1]
    _map_output(output)


def _map_output(output):
    temp = dict()
    for line in output:
        _line = (re.sub('[()]', '', line))
        _line = _line.split(" ")
        _line = [x for x in _line if x]

        (commit, author, date, time) = (_line[:4])
        line_no = _line[5]

        meta = ':: {}: {} {} {} ::'.format(author, commit, time, date)
        temp[line_no] = meta

    vim.vars['line_meta_mapping'] = temp


def _setline():
    if vim.current.line == '':
        return

    cursor_position = vim.current.window.cursor
    (row, col) = _get_current_row_column()
    vim.vars['line_visited'] = row

    current_line_length = _get_current_line_length()
    current_line_content = vim.current.line

    temp = vim.vars['line_content_mapping']
    temp[int(row)] = current_line_content
    vim.command('let g:line_content_mapping = {}'.format(temp))

    temp1 = vim.vars['line_meta_mapping']
    meta_content = ' ' * (20) + temp1[row]
    vim.current.line += meta_content
    vim.current.window.cursor = cursor_position


def _unsetline():
    row = vim.vars['line_visited']
    if not row:
        return

    (crow, ccol) = _get_current_row_column()
    if crow == row:
        return

    temp = vim.vars['line_content_mapping']
    vim.eval('setline({}, "{}")'.format(row, temp[row]))


def _raise_error():
    print("Blameline: Invalid argument")
    pass


def main():
    temp = vim.vars['line_meta_mapping']
    if not temp:
        _get_blame_output()

    flag = int(vim.eval('a:flag'))
    if flag == 0:
        _setline()
    elif flag == 1:
        _unsetline()

main()
EOF

endfunction

command! -nargs=1 Blameline call blameline#run(<args>)

augroup blame
    autocmd!
    autocmd CursorHold * :Blameline(0)
    autocmd CursorMoved * :Blameline(1)
augroup END
