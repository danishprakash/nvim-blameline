function! blameline#run() abort
    let py_exe = has('python3') ? 'python3' : 'python'
    execute py_exe "<< EOF"

import os
import vim
import pprint
import threading
import subprocess

line_meta_mapping = dict()


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
        _line = line.split(" ")
        _line = [x for x in _line if x]

        line_no = _line[5].replace(')', '')
        commit = _line[0]
        author = _line[1].replace('(', '')
        time = _line[3]
        date = _line[2]

        meta = '{}: {} {} {}'.format(author, commit, time, date)
        line_meta_mapping[line_no] = meta

    return output


def _get_longest_line():
    longest, current = (0, 1)
    total_lines = int(vim.eval('line("$")'))
    (row, col) = vim.current.window.cursor

    while current <= total_lines:
        vim.current.window.cursor = (current, 1)
        column_length = int(vim.eval('col("$")'))
        if column_length > longest:
            longest = column_length
        current += 1

    vim.current.window.cursor = (row, col)
    return longest


def _setline():
    global line_meta_mapping

    longest_line_length = _get_longest_line()
    (row, col) = _get_current_row_column()



def main():
    global line_meta_mapping

    output = _get_blame_output()
    (row, col) = _get_current_row_column()
    print(_get_longest_line())

main()
EOF

endfunction

command! -nargs=0 Blameline call blameline#run()
