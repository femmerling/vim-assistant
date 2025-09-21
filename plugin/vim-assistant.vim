" vim-assistant.vim - AI coding assistant for Vim/Neovim
" Author: Fauzan Emmerling
" Version: 0.1.0
" License: MIT

if exists('g:loaded_vim_assistant')
    finish
endif
let g:loaded_vim_assistant = 1

" Plugin configuration
let g:vim_assistant#ollama_url = get(g:, 'vim_assistant#ollama_url', 'http://localhost:11434')
let g:vim_assistant#model = get(g:, 'vim_assistant#model', 'qwen3-coder')
let g:vim_assistant#buffer_width = get(g:, 'vim_assistant#buffer_width', 20)
let g:vim_assistant#max_context_files = get(g:, 'vim_assistant#max_context_files', 50)
let g:vim_assistant#chroma_persist_dir = get(g:, 'vim_assistant#chroma_persist_dir', '~/.vim-assistant-chroma')

" Commands
command! AI call vim_assistant#open()
command! AIClose call vim_assistant#close()
command! AIToggle call vim_assistant#toggle()
command! AIComplete call vim_assistant#complete()
command! AIGenerate call vim_assistant#generate()
command! AIUpdateIndex call vim_assistant#update_index()

" Key mappings
if !hasmapto('<Plug>VimAssistantOpen')
    map <unique> <Leader>ai <Plug>VimAssistantOpen
endif
noremap <unique> <script> <Plug>VimAssistantOpen :AI<CR>

if !hasmapto('<Plug>VimAssistantToggle')
    map <unique> <Leader>at <Plug>VimAssistantToggle
endif
noremap <unique> <script> <Plug>VimAssistantToggle :AIToggle<CR>

if !hasmapto('<Plug>VimAssistantComplete')
    map <unique> <Leader>ac <Plug>VimAssistantComplete
endif
noremap <unique> <script> <Plug>VimAssistantComplete :AIComplete<CR>

if !hasmapto('<Plug>VimAssistantGenerate')
    map <unique> <Leader>ag <Plug>VimAssistantGenerate
endif
noremap <unique> <script> <Plug>VimAssistantGenerate :AIGenerate<CR>
