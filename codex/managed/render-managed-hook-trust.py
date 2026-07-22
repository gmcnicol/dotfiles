#!/usr/bin/env python3
import json
import re
import subprocess
import sys


def managed_plugins(path):
    plugins = set()
    with open(path, encoding="utf-8") as manifest:
        for line in manifest:
            parts = line.strip().split("|")
            if parts[0] == "plugin" and len(parts) >= 2:
                plugins.add(parts[1])
    return plugins


def read_response(process, request_id):
    for line in process.stdout:
        message = json.loads(line)
        if message.get("id") == request_id:
            return message
    raise RuntimeError(f"Codex app server closed before response {request_id}")


def discover_hooks(cwd):
    process = subprocess.Popen(
        ["codex", "app-server", "--stdio", "-c", 'sandbox_mode="danger-full-access"'],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
    )
    try:
        requests = (
            {"id": 1, "method": "initialize", "params": {"clientInfo": {"name": "codex-sync", "title": "codex-sync", "version": "1"}, "capabilities": None}},
            {"method": "initialized"},
            {"id": 2, "method": "hooks/list", "params": {"cwds": [cwd]}},
        )
        process.stdin.write(json.dumps(requests[0]) + "\n")
        process.stdin.flush()
        read_response(process, 1)
        for request in requests[1:]:
            process.stdin.write(json.dumps(request) + "\n")
        process.stdin.flush()
        response = read_response(process, 2)
        return response["result"]["data"][0]["hooks"]
    finally:
        process.terminate()
        process.wait(timeout=5)


def main():
    plugins = managed_plugins(sys.argv[1])
    if len(sys.argv) == 4:
        with open(sys.argv[3], encoding="utf-8") as fixture:
            hooks = json.load(fixture)
    else:
        hooks = discover_hooks(sys.argv[2])
    trusted = []
    for hook in hooks:
        plugin = hook.get("pluginId")
        key = hook.get("key", "")
        digest = hook.get("currentHash", "")
        if plugin in plugins and key.startswith(plugin + ":") and re.fullmatch(r"sha256:[0-9a-f]{64}", digest):
            trusted.append((key, digest))

    if trusted:
        print("\n[hooks.state]")
        for key, digest in trusted:
            print(f"\n[hooks.state.{json.dumps(key)}]")
            print(f"trusted_hash = {json.dumps(digest)}")


if __name__ == "__main__":
    main()
