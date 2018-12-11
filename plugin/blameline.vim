" TODO: add delay after every line change/function invocation
" TODO: skip empty lines 
" TODO: figure out an event for line change
" TODO: what to do -> we need to make sure that we change the current line
"       only when we are on that line and it should be reverted back to normal
"       as soon as we move away from this line
" TODO: also you need to figure out how to avoid the cursor to move
"       to the metadata on the same line while pressing `w` or `b`


let g:lines_visited = []
let g:line_meta_mapping = {}
let g:longest_line_length = 0
let g:line_content_mapping= {}

function! s:syntax() abort
    syntax match BLAMELINE /::.*::/
    highlight link BLAMELINE Comment
endfunction

function! blameline#run(flag) abort
    let py_exe = has('python3') ? 'python3' : 'python'
    call s:syntax()
    execute py_exe "<< EOF"

import os
import re
import vim
import time
import pprint
import threading
import subprocess


def _get_current_row_column():
    return (vim.eval("getpos('.')")[1:3])


def _get_blame_output():
    file_path = os.path.join(os.getcwd(), vim.eval("expand('%:t')"))
    output = subprocess.check_output(['git', 'blame', file_path])
    output = output.decode('utf-8').split('\n')[:-1]
    return _map_output(output)


def _map_output(output):
    for line in output:
        _line = (re.sub('[()]', '', line))
        _line = _line.split(" ")
        _line = [x for x in _line if x]

        (commit, author, date, time) = (_line[:4])
        line_no = _line[5]

        meta = ':: {}: {} {} {} ::'.format(author, commit, time, date)
        temp = vim.vars['line_meta_mapping']
        temp[line_no] = meta
        vim.vars['line_meta_mapping'] = temp

    return output


def _get_longest_line():
    global longest_line_length

    longest, current = (0, 1)
    total_lines = int(vim.eval('line("$")'))
    cursor_position = vim.current.window.cursor

    while current <= total_lines:
        vim.current.window.cursor = (current, 1)
        column_length = int(vim.eval('col("$")'))
        if column_length > longest:
            longest = column_length
        current += 1

    vim.current.window.cursor = cursor_position
    longest_line_length = longest
    vim.vars['longest_line_length'] = longest


def _get_current_line_length():
    return int(vim.eval('col("$")'))


def _setline():
    cursor_position = vim.current.window.cursor
    longest_line_length = int(vim.eval('g:longest_line_length'))
    (row, col) = _get_current_row_column()

    if row in vim.eval('g:lines_visited'):
        return
    else:
        vim.command('call add(g:lines_visited, {})'.format(int(row)))

    current_line_length = _get_current_line_length()
    current_line_content = vim.current.line

    temp = vim.vars['line_content_mapping']
    temp[row] = current_line_content
    vim.vars['line_content_mapping'] = temp

    temp1 = vim.vars['line_meta_mapping']
    meta_content = ' ' * (20) + temp1[row]
    vim.current.line += meta_content
    vim.current.window.cursor = cursor_position


def _unsetline():
    cursor_position = vim.current.window.cursor
    (row, col) = _get_current_row_column()
    temp = vim.vars['line_content_mapping']
    vim.current.line = temp[row]


def main():
    if int(vim.eval('g:longest_line_length')) == 0:
        _get_longest_line()

    output = _get_blame_output()
    (row, col) = _get_current_row_column()

    flag = int(vim.eval('a:flag'))
    if flag == 0:
        _setline()
    elif flag == 1:
        _unsetline()
    else:
        return

main()
EOF

endfunction

command! -nargs=1 Blameline call blameline#run(<args>)
