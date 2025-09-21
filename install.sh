#!/bin/bash

# Vim Assistant Installation Script

echo "Installing Vim Assistant..."

# Check if Python 3 is available
if ! command -v python3 &> /dev/null; then
    echo "Error: Python 3 is required but not installed."
    exit 1
fi

# Check if pip is available
if ! command -v pip3 &> /dev/null; then
    echo "Error: pip3 is required but not installed."
    exit 1
fi

# Install Python dependencies
echo "Installing Python dependencies..."
pip3 install -r requirements.txt

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "Warning: Ollama is not installed. Please install it from https://ollama.ai/"
    echo "After installing Ollama, run: ollama pull freehuntx/qwen3-coder"
else
    echo "Checking for qwen3-coder model..."
    if ! ollama list | grep -q "qwen3-coder"; then
        echo "Pulling qwen3-coder model..."
        ollama pull freehuntx/qwen3-coder:14b
    else
        echo "qwen3-coder model is already installed."
    fi
fi

# Make Python script executable
chmod +x python/ollama_bridge.py

echo "Installation complete!"
echo ""
echo "To use Vim Assistant:"
echo "1. Start Ollama: ollama serve"
echo "2. Open Vim and run: :AI"
echo "3. Update codebase index: :AIUpdateIndex"
echo ""
echo "For more information, see README.md"
