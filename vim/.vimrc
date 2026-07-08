set nocompatible

let mapleader = " "

set expandtab
set shiftwidth=2
set tabstop=2
set number
set relativenumber
set ignorecase
set smartcase
set scrolloff=8
set mouse=a
set splitright
set splitbelow
set cursorline

if has("persistent_undo")
  set undofile
  let s:undo_dir = expand("~/.vim/undo")
  if !isdirectory(s:undo_dir)
    call mkdir(s:undo_dir, "p", 0700)
  endif
  execute "set undodir=" . fnameescape(s:undo_dir)
endif

if has("termguicolors") && ($COLORTERM ==# "truecolor" || $COLORTERM ==# "24bit")
  set termguicolors
endif

if &term =~# 'xterm\|screen\|tmux'
  let s:cursor_block = "\<Esc>[2 q"
  let s:cursor_bar = "\<Esc>[5 q"
  let s:cursor_underline = "\<Esc>[3 q"

  let &t_ti .= s:cursor_block
  let &t_SI = s:cursor_bar
  let &t_SR = s:cursor_underline
  let &t_EI = s:cursor_block
  let &t_te .= s:cursor_bar
endif

set background=dark
colorscheme slate

syntax enable
filetype plugin indent on

nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>
nnoremap <leader>h :nohlsearch<CR>
nnoremap <leader>e :Ex<CR>

nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-j> <C-w>j
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-l> <C-w>l

vnoremap <silent> < <gv
vnoremap <silent> > >gv
