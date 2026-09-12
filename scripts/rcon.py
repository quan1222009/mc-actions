#!/usr/bin/env python3
"""Gửi 1 lệnh console tới server qua RCON.
Dùng: python3 rcon.py "save-all"
"""
import sys
import os

try:
    from mcrcon import MCRcon
except ImportError:
    print("mcrcon chưa được cài, chạy: pip install mcrcon --break-system-packages", file=sys.stderr)
    sys.exit(1)

def main():
    if len(sys.argv) < 2:
        print("Cần truyền lệnh, ví dụ: rcon.py 'save-all'", file=sys.stderr)
        sys.exit(1)

    command = " ".join(sys.argv[1:])
    password = os.environ.get("RCON_PASSWORD", "")
    host = os.environ.get("RCON_HOST", "127.0.0.1")
    port = int(os.environ.get("RCON_PORT", "25575"))

    try:
        with MCRcon(host, password, port=port) as mcr:
            response = mcr.command(command)
            print(response)
    except Exception as e:
        print(f"Lỗi RCON: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
