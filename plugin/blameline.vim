function! blameline#run() abort
    let py_exe = has('python3') ? 'python3' : 'python'
    execute py_exe "<< EOF"

import os
import re
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
        line = re.sub('[()]', '', line)
        _line = line.split(" ")
        _line = [x for x in _line if x]
        (commit, author, date, time) = _line[0:4]
        line_no = _line[5]
        meta = '{}: {} {} {}'.format(author, commit, time, date)
        line_meta_mapping[line_no] = meta

    return output


def _get_longest_line_length():
    line_length = 0
    while line_length <= 0:
        ex


def _set_meta_on_line():
    global line_meta_mapping
    (row, col) = _get_current_row_column()
    col += 5


def main():
    global line_meta_mapping

    output = _get_blame_output()
    (row, col) = _get_current_row_column()

main()
EOF

endfunction

command! -nargs=0 Blameline call blameline#run()
