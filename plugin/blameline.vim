" TODO: also you need to figure out how to avoid the cursor from
"       moving to the metadata on the same line while pressing
"       `w` or `e`
" TODO: add header for this file, similar to py-splice
" TODO: raise proper errors
" TODO: skip files that are not a valid git directory 
" TODO: handle buffer change
" TODO: handle file change using some other event (TextChanged or FileChanged)
" TODO: pull out the _get_blame_output() function and create another
"       user accessible command which would invoke this function 
"       to update the git blame output and also would do this on every
"       file change (see above todo)
" TODO: ask for user confirmation if the file has been changed locally
"       before starting the plugin
" TODO: if file has changed, use TextChanged to run blame_output()
"       again and skip lines for whose blame output is not there
" TODO: need to figure out how to escape lines with single/double
"       quotes beginning/ending
"
let g:line_visited = ""
let g:line_meta_mapping = {}
let g:line_content_mapping = {}
let g:blameline_update_time = 4000


function! s:syntax() abort
    syntax match BLAMELINE /::.*::/
    highlight link BLAMELINE Comment
endfunction


" updates `ut` or `updatetime` as per
" global var g:blameline_update_time
" which determines the delay in
" triggering the CursorHold event
function! s:set_update_time() abort
    let &updatetime=g:blameline_update_time
endfunction


function! s:err(msg) abort
    echohl ErrorMsg
    echom 'Blameline: '.a:msg
    echohl None
endfunction


" entry point for the plugin
" checks for git and python
" and calls other functions
function! blameline#init(flag) abort
    if !executable('git')
        return s:err("git is required")
    endif
    call s:set_update_time()
    call blameline#run(a:flag)
endfunction


" retrieves output for git blame
" for the current file and creates
" mapping in the following form:
" {<line_no>: <content + blame>}
function! s:get_blame_output() abort
    let py_exe = has('python3') ? 'python3' : 'python'
    execute py_exe "<< EOF"

import re
import vim
import subprocess


def git_blame():
    file_path = vim.eval('expand("%:p")')
    output = subprocess.check_output(['git', 'blame', file_path])
    output = output.decode('utf-8').split('\n')[:-1]
    create_mapping(output)


def create_mapping(output):
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

git_blame()
EOF
endfunction


function! blameline#run(flag) abort
    let py_exe = has('python3') ? 'python3' : 'python'
    call s:syntax()
    execute py_exe "<< EOF"

import vim


def _get_current_row_column():
    return (vim.eval("getpos('.')")[1:3])


def _get_current_line_length():
    return int(vim.eval('col("$")'))


def _setline():
    if vim.current.line == '':
        return

    line_meta_mapping = vim.vars['line_meta_mapping']
    (row, col) = _get_current_row_column()
    if row not in line_meta_mapping.keys():
        return

    cursor_position = vim.current.window.cursor
    line_content_mapping = vim.vars['line_content_mapping']
    current_line_length = _get_current_line_length()
    current_line_content = vim.current.line

    vim.vars['line_visited'] = row
    line_content_mapping[int(row)] = current_line_content
    vim.command('let g:line_content_mapping = {}'.format(line_content_mapping))

    meta_content = ' ' * (20) + line_meta_mapping[row]
    vim.current.line += meta_content
    vim.current.window.cursor = cursor_position


def _unsetline():
    row = vim.vars['line_visited']
    if not row:
        return

    line_content_mapping = vim.vars['line_content_mapping']
    (crow, ccol) = _get_current_row_column()
    if crow == row or row not in line_content_mapping.keys():
        return

    vim.eval("setline({}, '{}')".format(row, temp[row]))


def _raise_error():
    print("Blameline: Invalid argument")
    pass


def main():
    temp = vim.vars['line_meta_mapping']
    if not temp:
        vim.command('call s:get_blame_output()')

    flag = int(vim.eval('a:flag'))
    if flag == 0:
        _setline()
    elif flag == 1:
        _unsetline()

main()
EOF
endfunction

command! -nargs=1 Blameline call blameline#init(<args>)

augroup blame
    autocmd!
    autocmd CursorHold * :Blameline(0)
    autocmd CursorMoved * :Blameline(1)
augroup END
