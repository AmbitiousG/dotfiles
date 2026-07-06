" Basic display
set number
set relativenumber
set numberwidth=4
set foldcolumn=0
set cursorline
set showcmd
if has('termguicolors')
  set notermguicolors
endif
if exists('&signcolumn')
  set signcolumn=yes
endif

" Indentation
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent

" Search
set ignorecase
set smartcase
set hlsearch
set incsearch

" Editing
set nowrap
set scrolloff=8
set sidescrolloff=8
set mouse=a
if has('clipboard')
  set clipboard=unnamedplus
endif
if has('persistent_undo')
  set undofile
endif
set splitright
set splitbelow

" Syntax highlighting and filetype plugins
syntax enable
filetype plugin indent on
set background=dark
silent! colorscheme slate

" Leader key
let mapleader = " "

" Keymaps
nnoremap <Space>w :w<CR>
nnoremap <Space>q :q<CR>
nnoremap <Space>h :nohlsearch<CR>
nnoremap <Space>e :Ex<CR>

nnoremap <silent> <C-h> <C-w>h
nnoremap <silent> <C-j> <C-w>j
nnoremap <silent> <C-k> <C-w>k
nnoremap <silent> <C-l> <C-w>l

nnoremap <silent> <C-Up> :resize +2<CR>
nnoremap <silent> <C-Down> :resize -2<CR>
nnoremap <silent> <C-Left> :vertical resize -2<CR>
nnoremap <silent> <C-Right> :vertical resize +2<CR>

" Keep the visual selection after indenting.
vnoremap <silent> < <gv
vnoremap <silent> > >gv
