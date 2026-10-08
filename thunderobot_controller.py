#!/usr/bin/env python3
"""
Thunderobot RS Linux Control Suite - Main Entrypoint
"""
import sys
import os

# Add parent directory to sys.path so thunderobot_core is importable
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

from thunderobot_core.daemon.server import serve

if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1].isdigit() else 18888
    serve(port)
