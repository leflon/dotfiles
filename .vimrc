call plug#begin()
Plug 'vim-airline/vim-airline'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'crusoexia/vim-monokai'
call plug#end()

"Performance
set re=0

"Base settings
syntax on
colorscheme monokai
filetype on
set noswapfile
set noequalalways
set autoread
set hidden


"Indents
set tabstop=2
set shiftwidth=0
set softtabstop=0
set noexpandtab


"Code features

" Autosave
autocmd InsertLeave * silent! write
let g:coc_global_extensions = ['coc-git', 'coc-tsserver'] 

" Autocompletion with TAB and Enter
function! CheckBackspace() abort
  let col = col('.') - 1
  return !col || getline('.')[col - 1]  =~# '\s'
endfunction
inoremap <silent><expr> <TAB>
      \ coc#pum#visible() ? coc#pum#next(1) :
      \ CheckBackspace() ? "\<Tab>" :
      \ coc#refresh()
inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

" Make <CR> to accept selected completion item or notify coc.nvim to format
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                              \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

" Code navigation
nmap <silent><nowait> gd <Plug>(coc-definition)
nmap <silent><nowait> gy <Plug>(coc-type-definition)
nmap <silent><nowait> gi <Plug>(coc-implementation)
nmap <silent><nowait> gr <Plug>(coc-references)

" Highlight the symbol and its references when holding the cursor
autocmd CursorHold * silent call CocActionAsync('highlight')

" Symbol renaming
nmap <leader>rn <Plug>(coc-rename)

nnoremap <silent> K :call ShowDocumentation()<CR>

function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

nnoremap <silent><nowait> <space>a  :<C-u>CocList diagnostics<cr>

set statusline^=%{coc#status()}%{get(b:,'coc_current_function','')}
nmap <leader>a  <Plug>(coc-codeaction-selected)


"UI

""General
set ls=2
set noshowmode "Displayed by airline
set noshowcmd
set shortmess+=F


""Editor
set nu rnu
set cursorline
set scl=yes
hi CursorLine ctermbg=235 cterm=NONE
hi CursorLineNr cterm=BOLD ctermfg=214
hi SignColumn ctermbg=235


"""Show indents/trailing on Visual
augroup ShowIndentsOnVisual
	autocmd!
	autocmd ModeChanged *:[vV\x16]* set list
	autocmd ModeChanged [vV\x16]*:* set nolist
augroup END

set lcs=tab:→\ ,lead:.,trail:█
highlight SpecialKey ctermbg=237 cterm=bold ctermfg=204


""Statusline & Tabline
set ls=2
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

""Windows

"""Global keybinds

nnoremap <Left> <Nop>
nnoremap <Right> <Nop>
nnoremap <Up> <Nop>
nnoremap <Down> <Nop>

nnoremap <silent> <Left> <C-w>h
nnoremap <silent> <Right> <C-w>l
nnoremap <silent> <Up> <C-w>k
nnoremap <silent> <Down> <C-w>j

nnoremap <silent> + <C-w>5>
nnoremap <silent> - <C-w>5<
nnoremap <silent> = <C-w>=


set termwinkey=<C-x>
tnoremap <Left> <Left>
tnoremap <Right> <Right>
tnoremap <Up> <Up>
tnoremap <Down> <Down>
tnoremap <Esc> <Nop>
tnoremap <Esc> <C-x><S-n>
tnoremap <leader><Esc> <C-x><S-n>
tnoremap <leader><Left> <C-x>h
tnoremap <leader><Right> <C-x>l
tnoremap <leader><Up> <C-x>k
tnoremap <leader><Down> <C-x>j

augroup ReadOnlyHooks
	autocmd!
	autocmd BufReadPost,BufEnter * if &readonly | call ReadOnlyMappings() | endif
augroup END

function! ReadOnlyMappings()
	nnoremap <buffer><silent> q :bd<CR>
	nnoremap <buffer><silent> <Esc> :bd<CR>
endfunction

""" File explorer pane

function! s:PruneNoNameBufs() abort
	for buf in getbufinfo()
		if buf.name == '' && !getbufvar(buf.bufnr, '&modified')
			exe 'bwipeout ' . buf.bufnr
		endif
	endfor
endfunction

function! s:OnBufEnter(_) abort
	if &filetype ==# 'netrw'
		call s:PruneNoNameBufs()
	endif
endfunction

augroup PreventNetwrNoName
	autocmd!
	autocmd BufEnter * call timer_start(0, funcref('s:OnBufEnter'))
augroup END


nnoremap <silent> <C-k>e :25Lexplore<CR>

"""Terminal pane

let g:pl#term#cols = 70
let g:pl#term#winid = v:null

function! GetTerminals() abort
	return map(filter(getbufinfo({'buflisted':1}), {_, b -> getbufvar(b.bufnr, '&buftype') ==# 'terminal' }), { _, b -> b.bufnr })
endfunction

function! OnTermExit(bufid) abort
	if len(GetTerminals()) - 1 > 0
		call TermNavigate(-1)
	endif

	exe 'bd ' . a:bufid
endfunction

function! OpenNewTerm(curwin=0) abort
	setlocal splitright
	let l:term = term_start(&shell, { "stoponexit": 0, "vertical": 1, "curwin": a:curwin, "term_cols": g:pl#term#cols })

	call term_getjob(l:term)->job_setoptions({ "exit_cb": { _, __ -> OnTermExit(l:term)}})
endfunction

function! OpenTermWindow(stay_in = 1) abort
	if (g:pl#term#winid != v:null) 
		return 
	endif
	let l:prev_win_id = win_getid()

	200wincmd l
	200wincmd j

	if len(GetTerminals()) == 0
		call OpenNewTerm()
	else 
		exe 'rightb ' . g:pl#term#cols . 'vsp | buffer ' . GetTerminals()[0]
	endif

	let g:pl#term#winid = win_getid()

	if a:stay_in == 0
		call win_gotoid(l:prev_win_id)
	endif
endfunction

function! HideTermWindow()
	if g:pl#term#winid != v:null
		exe 'close ' . g:pl#term#winid
		let g:pl#term#winid = v:null
	endif
endfunction

function! ToggleTerm() abort
	if g:pl#term#winid == v:null
		call OpenTermWindow(1)
	else
		call HideTermWindow()
	endif
endfunction

function! TermNavigate(dir) abort
	if g:pl#term#winid == v:null || win_getid() != g:pl#term#winid
		echohl ErrorMsg
		echom "Can't use this function outside the term window (" . win_getid('%') . "," . g:pl#term#winid . ")"
		echohl None
		return
	endif

	let l:idx = index(GetTerminals(), bufnr('%'))
	if l:idx == -1
		return
	endif

	if a:dir == 1 "Go Right
		if l:idx == len(GetTerminals()) - 1
			call OpenNewTerm(1)
		else
			exe 'buffer ' . GetTerminals()[l:idx + 1]
		endif
	else
		exe 'buffer ' . GetTerminals()[l:idx - 1]
	endif
endfunction
	

augroup TerminalPaneAutoCommands
	autocmd!
	autocmd WinClosed * if expand('<amatch>') == g:pl#term#winid | let g:pl#term#winid = v:null | endif
	autocmd WinResized * if g:pl#term#winid != v:null | let g:pl#term#cols = winwidth(g:pl#term#winid) | endif
	autocmd ModeChanged *:[nN]* if &buftype ==# 'terminal' | set nonumber norelativenumber | set signcolumn=no | endif
augroup END

nnoremap <silent> <C-J> :call ToggleTerm()<CR>
nnoremap <silent> <leader><leader> :call ToggleTerm()<CR>
tnoremap <silent> <C-J> <C-x>:call ToggleTerm()<CR>
tnoremap <silent> <leader><leader> <C-x>:call ToggleTerm()<CR>
tnoremap <silent> <S-Right> <C-x>:call TermNavigate(1)<CR>
tnoremap <silent> <S-Left> <C-x>:call TermNavigate(-1)<CR>


""" Editor pane

function! Bnav(dir) abort
	if &filetype == 'netrw' 
		return
	endif
	if a:dir == 1
		bnext
	else
		bprevious
	endif

	" Ignore buffers in other windows, and ignore all terminals
	if len(win_findbuf(bufnr('%'))) > 1 || &buftype ==# 'terminal'
		call Bnav(a:dir)
	endif
endfunction

function! Bclose() abort
	let l:bufnr = bufnr('%')
	call Bnav(1)
	exe 'bd! ' . l:bufnr
endfunction

nnoremap <silent> <Tab> :call Bnav(1)<CR>
nnoremap <silent> <S-Tab> :call Bnav(-1)<CR>
nnoremap <silent> <leader>d :call Bclose()<CR>
nnoremap <silent> <leader>q :call Bclose()<CR>
nnoremap <silent> <C-w> :call Bclose()<CR>

function! KillTerms() abort
		for t in GetTerminals()
			exe 'bd! ' . t
		endfor
endfunction 

function! OnQuitHook() abort
	let l:wins = len(getwininfo())
	let l:curwin = win_getid()

	if l:wins == 1 
		call KillTerms()
	endif
endfunction

augroup OnQuit
	autocmd QuitPre * :call OnQuitHook()
augroup END


" Fzf
nnoremap <silent> <C-e> :Files<CR>
nnoremap <silent> <C-S-e> :Hist<CR>

augroup FzfArrowKeys
	autocmd FileType fzf tnoremap <buffer> <Up> <Up>
	autocmd FileType fzf tnoremap <buffer> <Down> <Down>
	autocmd FileType fzf tnoremap <buffer> <Left> <Left>
	autocmd FileType fzf tnoremap <buffer> <Right> <Right>
	autocmd FileType fzf tnoremap <buffer> <Esc> <Esc>
augroup END


