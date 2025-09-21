" vim_assistant.vim - Main functionality for vim-assistant
" Author: Your Name
" License: MIT

let s:assistant_buffer = -1
let s:assistant_window = -1
let s:python_bridge = ''

function! vim_assistant#open()
    if s:assistant_window != -1 && win_gotoid(s:assistant_window)
        return
    endif
    
    " Create or get the assistant buffer
    if s:assistant_buffer == -1
        let s:assistant_buffer = bufnr('__VimAssistant__', 1)
        call setbufvar(s:assistant_buffer, '&buftype', 'nofile')
        call setbufvar(s:assistant_buffer, '&bufhidden', 'hide')
        call setbufvar(s:assistant_buffer, '&swapfile', 0)
        call setbufvar(s:assistant_buffer, '&buflisted', 0)
    endif
    
    " Open the buffer in a vertical split
    let current_win = win_getid()
    execute 'vertical rightbelow split | buffer ' . s:assistant_buffer
    let s:assistant_window = win_getid()
    
    " Set window width
    execute 'vertical resize ' . g:vim_assistant#buffer_width
    
    " Set up buffer content
    call s:setup_assistant_buffer()
    
    " Return to original window
    call win_gotoid(current_win)
endfunction

function! vim_assistant#close()
    if s:assistant_window != -1 && win_gotoid(s:assistant_window)
        close
        let s:assistant_window = -1
    endif
endfunction

function! vim_assistant#toggle()
    if s:assistant_window != -1 && win_gotoid(s:assistant_window)
        call vim_assistant#close()
    else
        call vim_assistant#open()
    endif
endfunction

function! vim_assistant#complete()
    if s:assistant_window == -1
        call vim_assistant#open()
    endif
    
    let context = s:get_context()
    let prompt = s:build_completion_prompt(context)
    call s:send_to_assistant(prompt, 'completion')
endfunction

function! vim_assistant#generate()
    if s:assistant_window == -1
        call vim_assistant#open()
    endif
    
    let context = s:get_context()
    let prompt = s:build_generation_prompt(context)
    call s:send_to_assistant(prompt, 'generation')
endfunction

function! vim_assistant#update_index()
    call s:update_status('Updating codebase index...')
    let python_cmd = 'python3 ' . s:get_python_bridge_path() . ' --update-index --cwd "' . getcwd() . '"'
    let result = system(python_cmd)
    
    if v:shell_error
        call s:update_status('Error updating index: ' . result)
    else
        call s:update_status('Index updated successfully')
    endif
endfunction

function! s:setup_assistant_buffer()
    let lines = [
        \ 'Vim Assistant - AI Coding Helper',
        \ '================================',
        \ '',
        \ 'Commands:',
        \ '  :AIComplete  - Get completion suggestions',
        \ '  :AIGenerate  - Generate code',
        \ '  :AIUpdateIndex - Update codebase index',
        \ '  :AIClose     - Close this window',
        \ '',
        \ 'Key mappings:',
        \ '  <Leader>ac  - Complete',
        \ '  <Leader>ag  - Generate',
        \ '  <Leader>ai  - Open/Toggle',
        \ '',
        \ 'Status: Ready',
        \ '================================',
        \ ''
        \ ]
    call setline(1, lines)
    setlocal nomodifiable
endfunction

function! s:get_context()
    let context = {}
    let context.filetype = &filetype
    let context.filename = expand('%:t')
    let context.filepath = expand('%')
    let context.cwd = getcwd()
    
    " Get current file content
    if filereadable(expand('%'))
        let context.current_file = {
            \ 'content': join(getline(1, '$'), "\n"),
            \ 'filepath': expand('%:p'),
            \ 'filetype': &filetype,
            \ 'current_line': line('.'),
            \ 'current_col': col('.')
        }
    else
        let context.current_file = {
            \ 'content': '',
            \ 'filepath': expand('%:p'),
            \ 'filetype': &filetype,
            \ 'current_line': 1,
            \ 'current_col': 1
        }
    endif
    
    return context
endfunction

function! s:build_completion_prompt(context)
    let prompt = "Complete the following code. Provide only the completion, no explanations:\n\n"
    let prompt .= "File: " . a:context.filename . " (Filetype: " . a:context.filetype . ")\n\n"
    
    if !empty(a:context.current_file.content)
        let lines = split(a:context.current_file.content, "\n")
        let current_line = a:context.current_file.current_line
        let max_context = g:vim_assistant#max_context_lines
        
        let start_line = max([1, current_line - max_context/2])
        let end_line = min([len(lines), current_line + max_context/2])
        
        for i in range(start_line - 1, end_line - 1)
            let line_num = i + 1
            if line_num == current_line
                let prompt .= ">>> " . lines[i] . " <<< CURSOR HERE\n"
            else
                let prompt .= "    " . lines[i] . "\n"
            endif
        endfor
    else
        let prompt .= "New file - provide appropriate code for " . a:context.filetype . " filetype\n"
    endif
    
    return prompt
endfunction

function! s:build_generation_prompt(context)
    let prompt = "Generate code for the following context. Provide clean, well-commented code:\n\n"
    let prompt .= "File: " . a:context.filename . " (Filetype: " . a:context.filetype . ")\n\n"
    
    if !empty(a:context.current_file.content)
        let lines = split(a:context.current_file.content, "\n")
        let current_line = a:context.current_file.current_line
        let max_context = g:vim_assistant#max_context_lines
        
        let start_line = max([1, current_line - max_context/2])
        let end_line = min([len(lines), current_line + max_context/2])
        
        for i in range(start_line - 1, end_line - 1)
            let line_num = i + 1
            if line_num == current_line
                let prompt .= ">>> " . lines[i] . " <<< INSERT HERE\n"
            else
                let prompt .= "    " . lines[i] . "\n"
            endif
        endfor
    else
        let prompt .= "New file - generate appropriate code for " . a:context.filetype . " filetype\n"
    endif
    
    return prompt
endfunction

function! s:send_to_assistant(prompt, mode)
    " Update status
    call s:update_status('Sending request to Ollama...')
    
    " Use Python bridge to communicate with Ollama
    let python_cmd = 'python3 ' . s:get_python_bridge_path() . ' "' . escape(a:prompt, '"') . '" "' . a:mode . '" --cwd "' . getcwd() . '"'
    
    " Execute and get result
    let result = system(python_cmd)
    
    if v:shell_error
        call s:update_status('Error: ' . result)
    else
        call s:handle_response(result, a:mode)
        call s:update_status('Ready')
    endif
endfunction

function! s:handle_response(response, mode)
    if a:mode == 'completion'
        " For completion, show in assistant buffer
        call s:display_response(a:response, a:mode)
    else
        " For generation, check if it's a new file or existing file
        if empty(expand('%')) || !filereadable(expand('%'))
            " New file - create it directly
            call s:create_new_file(a:response)
        else
            " Existing file - show in assistant buffer for review
            call s:display_response(a:response, a:mode)
        endif
    endif
endfunction

function! s:create_new_file(content)
    " Create new file with generated content
    let lines = split(a:content, "\n")
    call setline(1, lines)
    write
    call s:update_status('New file created successfully')
endfunction

function! s:get_python_bridge_path()
    if s:python_bridge == ''
        let s:python_bridge = expand('<sfile>:p:h') . '/python/ollama_bridge.py'
    endif
    return s:python_bridge
endfunction

function! s:update_status(status)
    if s:assistant_window != -1 && win_gotoid(s:assistant_window)
        let status_line = 'Status: ' . a:status
        call setline(8, status_line)
    endif
endfunction

function! s:display_response(response, mode)
    if s:assistant_window != -1 && win_gotoid(s:assistant_window)
        " Clear previous response
        call setline(10, '')
        call setline(11, '')
        call setline(12, '')
        call setline(13, '')
        call setline(14, '')
        call setline(15, '')
        call setline(16, '')
        call setline(17, '')
        call setline(18, '')
        call setline(19, '')
        
        " Add new response
        let lines = split(a:response, '\n')
        let start_line = 10
        for i in range(min([len(lines), 10]))
            call setline(start_line + i, lines[i])
        endfor
        
        " Add mode indicator
        call setline(9, 'Mode: ' . a:mode)
        
        " Make buffer modifiable for viewing
        setlocal modifiable
        setlocal readonly
    endif
endfunction
