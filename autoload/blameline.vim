" =============================================================
" Name:         vim-blameline
" Maintainer:   Danish Prakash
" HomePage:     https://github.com/danishprakash/vim-blameline
" License:      GNU GPL
" =============================================================


let g:line_visited = ""
let g:line_meta_mapping = {}
let g:line_commit_mapping = {}
let g:commit_meta_mapping = {}
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


function! s:git_tracked() abort
    let py_exe = has('python3') ? 'python3' : 'python'
    execute py_exe "<< EOF"

import vim
import subprocess


def is_file_git_tracked():
    file_path = vim.eval('expand("%:p")')
    process = subprocess.Popen(['git', 'ls-files', '--error-unmatch', file_path], stdout=subprocess.PIPE)
    process.communicate()[0]
    if process.returncode != 0:
        vim.command('let retvalue={}'.format(1))
    else:
        vim.command('let retvalue={}'.format(0))


is_file_git_tracked()
EOF

    return l:retvalue
endfunction


" entry point for the plugin
" checks for git and python
" and calls other functions
function! blameline#InitBlameline(flag) abort
    if !executable('git')
        return s:err("git is required")
    endif

    call s:git_tracked()
    if s:git_tracked()
        return
    endif

    call s:set_update_time()
    call s:run(a:flag)
endfunction


" retrieves output for git blame
" for the current file and creates
" mapping in the following form:
" {<line_no>: <content + blame>}
function! blameline#GetBlameOutput() abort
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
    line_commit_mapping = dict()
    commit_meta_mapping = vim.vars['commit_meta_mapping']

    for line in output:
        _line = (re.sub('[()]', '', line))
        _line = _line.split(" ")
        _line = [x for x in _line if x]
        line_no = _line[5]
        commit = _line[0]

        if commit not in commit_meta_mapping.keys():
            (commit, author, date, time) = (_line[:4])
            meta = ':: {}, {} {} - {} ::'.format(author, commit, time, date)
            commit_meta_mapping[commit] = meta

        line_commit_mapping[line_no] = commit

    vim.vars['line_commit_mapping'] = line_commit_mapping
    vim.vars['commit_meta_mapping'] = commit_meta_mapping


git_blame()
EOF
endfunction


function! s:run(flag) abort
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

    line_commit_mapping = vim.vars['line_commit_mapping']
    commit_meta_mapping = vim.vars['commit_meta_mapping']
    (row, col) = _get_current_row_column()
    if row not in line_commit_mapping.keys():
        return

    cursor_position = vim.current.window.cursor
    line_content_mapping = vim.vars['line_content_mapping']
    current_line_content = vim.current.line
    vim.vars['line_visited'] = row
    line_content_mapping[int(row)] = current_line_content
    vim.command('let g:line_content_mapping = {}'.format(line_content_mapping))

    meta_content = ' ' * (20) + commit_meta_mapping[line_commit_mapping[row]]
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

    vim.eval("setline({}, '{}')".format(row, line_content_mapping[row]))


def _raise_error():
    print("Blameline: Invalid argument")


def main():
    temp = vim.vars['line_meta_mapping']
    if not temp:
        vim.command('call blameline#GetBlameOutput()')

    flag = int(vim.eval('a:flag'))
    if flag == 0:
        _setline()
    elif flag == 1:
        _unsetline()

main()
EOF
endfunction
