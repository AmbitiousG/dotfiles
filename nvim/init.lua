-- 基础显示
vim.opt.number = true                 -- 显示绝对行号
vim.opt.relativenumber = true         -- 显示相对行号，方便 5j / 3k 跳转
vim.opt.numberwidth = 4               -- 固定最小行号列宽
vim.opt.foldcolumn = "0"              -- 不额外显示折叠列
vim.opt.cursorline = true             -- 高亮当前行
vim.opt.showcmd = true                -- 显示未完成的命令
vim.opt.termguicolors = false         -- 禁用真彩色，使用终端基础配色
vim.opt.signcolumn = "yes"            -- 左侧诊断/标记列固定显示，避免界面抖动

-- 缩进
vim.opt.tabstop = 4                   -- Tab 显示为 4 空格宽度
vim.opt.shiftwidth = 4                -- 自动缩进宽度
vim.opt.expandtab = true              -- Tab 转空格
vim.opt.smartindent = true            -- 智能缩进

-- 搜索
vim.opt.ignorecase = true             -- 搜索忽略大小写
vim.opt.smartcase = true              -- 搜索包含大写时自动区分大小写
vim.opt.hlsearch = true               -- 高亮搜索结果
vim.opt.incsearch = true              -- 输入搜索时实时跳转

-- 编辑体验
vim.opt.wrap = false                  -- 不自动换行
vim.opt.scrolloff = 8                 -- 光标上下保留 8 行
vim.opt.sidescrolloff = 8
vim.opt.mouse = "a"                   -- 启用鼠标
vim.opt.clipboard = "unnamedplus"     -- 使用系统剪贴板
vim.opt.undofile = true               -- 持久化 undo
vim.opt.splitright = true             -- 垂直分屏默认开在右边
vim.opt.splitbelow = true             -- 水平分屏默认开在下面

-- 基础语法高亮和文件类型识别
vim.cmd("syntax enable")
vim.cmd("filetype plugin indent on")
vim.opt.background = "dark"
pcall(vim.cmd, "colorscheme slate")

-- Leader 键，常用设为空格
vim.g.mapleader = " "

-- 快捷键
local keymap = vim.keymap.set
local opts = { noremap = true, silent = true }
local visible_opts = { noremap = true, silent = false }

-- 保存 / 退出
keymap("n", "<Space>w", ":w<CR>", visible_opts)
keymap("n", "<Space>q", ":q<CR>", visible_opts)

-- 清除搜索高亮
keymap("n", "<Space>h", ":nohlsearch<CR>", visible_opts)

-- 打开文件浏览器 netrw
keymap("n", "<Space>e", ":Ex<CR>", visible_opts)

-- 窗口切换
keymap("n", "<C-h>", "<C-w>h", opts)
keymap("n", "<C-j>", "<C-w>j", opts)
keymap("n", "<C-k>", "<C-w>k", opts)
keymap("n", "<C-l>", "<C-w>l", opts)

-- 调整窗口大小
keymap("n", "<C-Up>", ":resize +2<CR>", opts)
keymap("n", "<C-Down>", ":resize -2<CR>", opts)
keymap("n", "<C-Left>", ":vertical resize -2<CR>", opts)
keymap("n", "<C-Right>", ":vertical resize +2<CR>", opts)

-- 普通模式下用 jk 退出插入模式
-- keymap("i", "jk", "<Esc>", opts)

-- 可视模式下缩进后保持选区
keymap("v", "<", "<gv", opts)
keymap("v", ">", ">gv", opts)
