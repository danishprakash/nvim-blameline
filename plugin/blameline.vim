" TODO: add syntax highlighting
" TODO: set line on every line change
" TODO: add delay after every line change/function invocation
" TODO: skip empty lines 


let g:longest_line_length = 0
let g:lines_visited = []

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

line_meta_mapping = dict()
line_content_mapping = dict()


def _get_current_row_column():
    return (vim.eval("getpos('.')")[1:3])


def _get_blame_output():
    file_path = os.path.join(os.getcwd(), vim.eval("expand('%:t')"))
    output = subprocess.check_output(['git', 'blame', file_path])
    output = output.decode('utf-8').split('\n')[:-1]
    return _map_output(output)


def _map_output(output):
    global line_meta_mapping

    for line in output:
        _line = (re.sub('[()]', '', line))
        _line = _line.split(" ")
        _line = [x for x in _line if x]

        (commit, author, date, time) = (_line[:4])
        line_no = _line[5]

        meta = ':: {}: {} {} {} ::'.format(author, commit, time, date)
        line_meta_mapping[line_no] = meta

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
    vim.command('let g:longest_line_length={}'.format(longest))


def _get_current_line_length():
    return int(vim.eval('col("$")'))


def _setline():
    global line_meta_mapping
    global line_content_mapping

    cursor_position = vim.current.window.cursor
    longest_line_length = int(vim.eval('g:longest_line_length'))
    (row, col) = _get_current_row_column()

    if row in vim.eval('g:lines_visited'):
        return
    else:
        vim.command('call add(g:lines_visited, {})'.format(int(row)))

    current_line_length = _get_current_line_length()
    current_line_content = vim.current.line
    line_content_mapping[row] = current_line_content
    meta_content = ' '*(20) + line_meta_mapping[row]
    vim.current.line += meta_content
    vim.current.window.cursor = cursor_position


def _unsetline():
    global line_meta_mapping
    cursor_position = vim.current.window.cursor
    (row, col) = _get_current_row_column()
    try:
        vim.current.line = line_content_mapping[int(row)]
    except:
        pass



def main():
    global line_meta_mapping
    global line_content_mapping

    if int(vim.eval('g:longest_line_length')) == 0:
        _get_longest_line()

    output = _get_blame_output()
    (row, col) = _get_current_row_column()

    print(line_content_mapping)

    flag = int(vim.eval('a:flag'))
    if flag == 0:
        print("here")
        _setline()
    elif flag == 1:
        print("there")
        _unsetline()
    else:
        print("ERROR")
        return

main()
EOF

endfunction

command! -nargs=1 Blameline call blameline#run(<args>)
