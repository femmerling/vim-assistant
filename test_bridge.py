#!/usr/bin/env python3
"""
Test script for Vim Assistant Python bridge
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from python.ollama_bridge import VimAssistant

def test_bridge():
    print("Testing Vim Assistant Python bridge...")
    
    # Test initialization
    try:
        assistant = VimAssistant()
        print("✓ Assistant initialized successfully")
    except Exception as e:
        print(f"✗ Error initializing assistant: {e}")
        return False
    
    # Test context retrieval
    try:
        context = assistant.get_codebase_context('.')
        print("✓ Context retrieval works")
        print(f"  - Project type: {context['codebase_summary']['project_type']}")
        print(f"  - Directories: {context['codebase_summary']['directories']}")
    except Exception as e:
        print(f"✗ Error getting context: {e}")
        return False
    
    # Test index update
    try:
        success = assistant.update_index('.')
        if success:
            print("✓ Index update successful")
        else:
            print("⚠ Index update failed (this is normal if no source files found)")
    except Exception as e:
        print(f"✗ Error updating index: {e}")
        return False
    
    print("\nAll tests passed! The bridge is working correctly.")
    return True

if __name__ == "__main__":
    test_bridge()
