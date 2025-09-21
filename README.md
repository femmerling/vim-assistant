# Vim Assistant

An AI-powered coding assistant for Vim and Neovim that provides intelligent code completion and generation using local Ollama models with RAG (Retrieval-Augmented Generation) capabilities.

## Features

- 🤖 **AI Code Completion**: Get intelligent code suggestions as you type
- ✨ **Code Generation**: Generate complete functions, classes, or files
- 🧠 **Context-Aware**: Uses RAG with ChromaDB to understand your entire codebase
- 🔒 **Privacy-First**: Runs completely offline using local Ollama models
- 🎯 **Smart File Handling**: Creates new files directly, shows suggestions for existing files
- ⚡ **Fast & Responsive**: Optimized for MacVim and Neovim

## Requirements

- Vim 8.0+ or Neovim 0.5+
- Python 3.7+
- [Ollama](https://ollama.ai/) installed locally
- Qwen2.5-coder model (or any compatible model)

## Installation

### Using Vundle

Add to your `.vimrc`:

```vim
Plugin 'your-username/vim-assistant'
```

Then run `:PluginInstall`

### Manual Installation

```bash
cd ~/.vim/bundle
git clone https://github.com/your-username/vim-assistant.git
```

## Setup

1. **Install Ollama** (if not already installed):
   ```bash
   # macOS
   brew install ollama
   
   # Or download from https://ollama.ai/
   ```

2. **Pull the Qwen2.5-coder model**:
   ```bash
   ollama pull qwen2.5-coder
   ```

3. **Install Python dependencies**:
   ```bash
   cd ~/.vim/bundle/vim-assistant
   pip install -r requirements.txt
   ```

4. **Start Ollama** (if not running):
   ```bash
   ollama serve
   ```

## Configuration

Add to your `.vimrc` for customization:

```vim
" Basic configuration
let g:vim_assistant#ollama_url = 'http://localhost:11434'
let g:vim_assistant#model = 'qwen2.5-coder'
let g:vim_assistant#buffer_width = 20
let g:vim_assistant#max_context_files = 50
let g:vim_assistant#chroma_persist_dir = '~/.vim-assistant-chroma'

" Custom key mappings (optional)
nmap <Leader>ai :AI<CR>
nmap <Leader>ac :AIComplete<CR>
nmap <Leader>ag :AIGenerate<CR>
nmap <Leader>at :AIToggle<CR>
```

## Usage

### Commands

- `:AI` - Open the assistant buffer
- `:AIComplete` - Get code completion suggestions
- `:AIGenerate` - Generate new code
- `:AIUpdateIndex` - Update the codebase index for better context
- `:AIClose` - Close the assistant buffer
- `:AIToggle` - Toggle the assistant buffer

### Key Mappings

- `<Leader>ai` - Open/toggle assistant
- `<Leader>ac` - Complete code
- `<Leader>ag` - Generate code
- `<Leader>at` - Toggle assistant window

### Workflow

1. **First time setup**: Run `:AIUpdateIndex` to index your codebase
2. **Code completion**: Place cursor where you want completion and press `<Leader>ac`
3. **Code generation**: Select text or place cursor and press `<Leader>ag`
4. **New files**: The assistant will create new files directly
5. **Existing files**: Suggestions appear in the assistant buffer for review

## How It Works

### RAG Integration

The plugin uses ChromaDB for local vector storage and retrieval:

1. **Indexing**: Your codebase is indexed using ChromaDB for semantic search
2. **Context Retrieval**: When you request completion/generation, relevant code is retrieved
3. **Enhanced Prompts**: The AI receives your request plus relevant codebase context
4. **Smart Responses**: Responses are tailored to your specific codebase patterns

### File Handling

- **New Files**: Generated code is written directly to the file
- **Existing Files**: Suggestions appear in the assistant buffer for review
- **Context Awareness**: The assistant understands your project structure and coding patterns

## Troubleshooting

### Common Issues

1. **"Error communicating with Ollama"**
   - Ensure Ollama is running: `ollama serve`
   - Check if the model is installed: `ollama list`
   - Verify the URL in configuration

2. **"Error initializing Chroma"**
   - Check Python dependencies: `pip install -r requirements.txt`
   - Ensure write permissions to the chroma directory

3. **Slow responses**
   - Update the codebase index: `:AIUpdateIndex`
   - Reduce `max_context_files` in configuration
   - Use a smaller model for faster responses

### Debug Mode

Enable debug output by adding to your `.vimrc`:

```vim
let g:vim_assistant#debug = 1
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Acknowledgments

- [Ollama](https://ollama.ai/) for local AI model serving
- [ChromaDB](https://www.trychroma.com/) for vector storage
- [Qwen](https://github.com/QwenLM/Qwen) for the coding model

## Support

- Create an issue for bug reports
- Start a discussion for feature requests
- Check the troubleshooting section for common issues
