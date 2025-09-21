#!/usr/bin/env python3
"""
Ollama Bridge for Vim Assistant
Handles communication with Ollama and Chroma for RAG functionality
"""

import json
import sys
import os
import requests
import argparse
from pathlib import Path
import chromadb
from chromadb.config import Settings
import hashlib
import time

class VimAssistant:
    def __init__(self, ollama_url="http://localhost:11434", model="qwen2.5-coder", chroma_dir="~/.vim-assistant-chroma"):
        self.ollama_url = ollama_url
        self.model = model
        self.chroma_dir = os.path.expanduser(chroma_dir)
        self.client = None
        self.collection = None
        self._init_chroma()
    
    def _init_chroma(self):
        """Initialize ChromaDB client and collection"""
        try:
            os.makedirs(self.chroma_dir, exist_ok=True)
            self.client = chromadb.PersistentClient(path=self.chroma_dir)
            self.collection = self.client.get_or_create_collection(
                name="vim_assistant_codebase",
                metadata={"description": "Codebase context for Vim Assistant"}
            )
        except Exception as e:
            print(f"Error initializing Chroma: {e}", file=sys.stderr)
            self.client = None
            self.collection = None
    
    def get_codebase_context(self, cwd, max_files=50):
        """Get relevant context from the codebase using RAG"""
        if not self.collection:
            return self._get_simple_context(cwd, max_files)
        
        try:
            # Get current file context
            current_file = self._get_current_file_context()
            if not current_file:
                return self._get_simple_context(cwd, max_files)
            
            # Query similar code chunks
            results = self.collection.query(
                query_texts=[current_file['content']],
                n_results=min(10, max_files)
            )
            
            context = {
                'current_file': current_file,
                'similar_files': [],
                'codebase_summary': self._get_codebase_summary(cwd)
            }
            
            if results['documents'] and results['documents'][0]:
                for i, doc in enumerate(results['documents'][0]):
                    metadata = results['metadatas'][0][i] if results['metadatas'] and results['metadatas'][0] else {}
                    context['similar_files'].append({
                        'content': doc,
                        'filepath': metadata.get('filepath', 'unknown'),
                        'filetype': metadata.get('filetype', 'unknown')
                    })
            
            return context
            
        except Exception as e:
            print(f"Error getting RAG context: {e}", file=sys.stderr)
            return self._get_simple_context(cwd, max_files)
    
    def _get_simple_context(self, cwd, max_files):
        """Fallback context without RAG"""
        context = {
            'current_file': self._get_current_file_context(),
            'similar_files': [],
            'codebase_summary': self._get_codebase_summary(cwd)
        }
        
        # Get recent files
        try:
            source_extensions = {'.py', '.js', '.ts', '.jsx', '.tsx', '.vim', '.lua', '.go', '.rs', '.cpp', '.c', '.h', '.java', '.php', '.rb', '.swift', '.kt', '.scala', '.sh', '.bash', '.zsh'}
            files = []
            for ext in source_extensions:
                files.extend(Path(cwd).rglob(f'*{ext}'))
            
            # Sort by modification time and limit
            files = sorted(files, key=lambda x: x.stat().st_mtime, reverse=True)[:max_files]
            
            for file_path in files[:10]:  # Limit to 10 files for context
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        context['similar_files'].append({
                            'content': content[:2000],  # Limit content size
                            'filepath': str(file_path.relative_to(cwd)),
                            'filetype': file_path.suffix
                        })
                except Exception:
                    continue
                    
        except Exception as e:
            print(f"Error getting simple context: {e}", file=sys.stderr)
        
        return context
    
    def _get_current_file_context(self):
        """Get context from the current file being edited"""
        # This would be passed from Vim, for now return empty
        return None
    
    def _get_codebase_summary(self, cwd):
        """Generate a summary of the codebase structure"""
        try:
            summary = {
                'project_type': 'unknown',
                'main_files': [],
                'directories': []
            }
            
            # Detect project type
            if (Path(cwd) / 'package.json').exists():
                summary['project_type'] = 'nodejs'
            elif (Path(cwd) / 'requirements.txt').exists() or (Path(cwd) / 'pyproject.toml').exists():
                summary['project_type'] = 'python'
            elif (Path(cwd) / 'Cargo.toml').exists():
                summary['project_type'] = 'rust'
            elif (Path(cwd) / 'go.mod').exists():
                summary['project_type'] = 'go'
            
            # Get main directories
            for item in Path(cwd).iterdir():
                if item.is_dir() and not item.name.startswith('.'):
                    summary['directories'].append(item.name)
            
            return summary
            
        except Exception:
            return {'project_type': 'unknown', 'main_files': [], 'directories': []}
    
    def update_index(self, cwd):
        """Update the Chroma index with current codebase"""
        if not self.collection:
            return False
        
        try:
            # Clear existing data
            self.collection.delete(where={})
            
            # Index all source files
            source_extensions = {'.py', '.js', '.ts', '.jsx', '.tsx', '.vim', '.lua', '.go', '.rs', '.cpp', '.c', '.h', '.java', '.php', '.rb', '.swift', '.kt', '.scala', '.sh', '.bash', '.zsh'}
            files = []
            for ext in source_extensions:
                files.extend(Path(cwd).rglob(f'*{ext}'))
            
            documents = []
            metadatas = []
            ids = []
            
            for file_path in files:
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        if len(content.strip()) > 0:  # Only index non-empty files
                            documents.append(content)
                            metadatas.append({
                                'filepath': str(file_path.relative_to(cwd)),
                                'filetype': file_path.suffix,
                                'size': len(content)
                            })
                            ids.append(str(file_path.relative_to(cwd)))
                except Exception:
                    continue
            
            if documents:
                self.collection.add(
                    documents=documents,
                    metadatas=metadatas,
                    ids=ids
                )
                return True
                
        except Exception as e:
            print(f"Error updating index: {e}", file=sys.stderr)
        
        return False
    
    def send_to_ollama(self, prompt, mode="completion"):
        """Send prompt to Ollama and get response"""
        try:
            url = f"{self.ollama_url}/api/generate"
            data = {
                "model": self.model,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.1 if mode == "completion" else 0.3,
                    "top_p": 0.9,
                    "max_tokens": 1000 if mode == "completion" else 2000
                }
            }
            
            response = requests.post(url, json=data, timeout=30)
            response.raise_for_status()
            
            result = response.json()
            return result.get('response', '')
            
        except Exception as e:
            return f"Error communicating with Ollama: {e}"

def main():
    parser = argparse.ArgumentParser(description='Vim Assistant Ollama Bridge')
    parser.add_argument('prompt', help='The prompt to send to Ollama')
    parser.add_argument('mode', choices=['completion', 'generation'], help='Mode: completion or generation')
    parser.add_argument('--cwd', default='.', help='Current working directory')
    parser.add_argument('--ollama-url', default='http://localhost:11434', help='Ollama URL')
    parser.add_argument('--model', default='qwen2.5-coder', help='Ollama model')
    parser.add_argument('--chroma-dir', default='~/.vim-assistant-chroma', help='Chroma persistence directory')
    parser.add_argument('--update-index', action='store_true', help='Update the codebase index')
    
    args = parser.parse_args()
    
    assistant = VimAssistant(
        ollama_url=args.ollama_url,
        model=args.model,
        chroma_dir=args.chroma_dir
    )
    
    if args.update_index:
        success = assistant.update_index(args.cwd)
        print("Index updated successfully" if success else "Failed to update index")
        return
    
    # Get context
    context = assistant.get_codebase_context(args.cwd)
    
    # Build enhanced prompt
    enhanced_prompt = build_enhanced_prompt(args.prompt, context, args.mode)
    
    # Send to Ollama
    response = assistant.send_to_ollama(enhanced_prompt, args.mode)
    print(response)

def build_enhanced_prompt(original_prompt, context, mode):
    """Build an enhanced prompt with codebase context"""
    prompt = f"""You are an AI coding assistant. You have access to the following codebase context:

Project Type: {context['codebase_summary']['project_type']}
Directories: {', '.join(context['codebase_summary']['directories'])}

"""
    
    if context['current_file']:
        prompt += f"Current File: {context['current_file']['filepath']}\n"
        prompt += f"File Type: {context['current_file']['filetype']}\n\n"
    
    if context['similar_files']:
        prompt += "Relevant Code Context:\n"
        for file_info in context['similar_files'][:5]:  # Limit to 5 most relevant files
            prompt += f"\n--- {file_info['filepath']} ({file_info['filetype']}) ---\n"
            prompt += file_info['content'][:1000] + "\n"  # Limit content
    
    prompt += f"\n--- User Request ---\n{original_prompt}\n\n"
    
    if mode == "completion":
        prompt += "Provide a concise code completion. Return only the code, no explanations."
    else:
        prompt += "Provide clean, well-commented code. If creating a new file, include the complete file content."
    
    return prompt

if __name__ == "__main__":
    main()
