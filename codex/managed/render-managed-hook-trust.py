#!/usr/bin/env python3
import json
import os
import pathlib
import queue
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time


def managed_plugins(path):
    plugins = set()
    with open(path, encoding="utf-8") as manifest:
        for line in manifest:
            parts = line.strip().split("|")
            if parts[0] == "plugin" and len(parts) >= 2:
                plugins.add(parts[1])
    return plugins


def read_response(process, request_id, timeout=10):
    deadline = time.monotonic() + timeout
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise TimeoutError(f"Codex app server timed out before response {request_id}")
        result = queue.Queue(maxsize=1)

        def read_line():
            try:
                result.put(process.stdout.readline())
            except BaseException as error:
                result.put(error)

        threading.Thread(target=read_line, daemon=True).start()
        try:
            line = result.get(timeout=remaining)
        except queue.Empty as error:
            raise TimeoutError(
                f"Codex app server timed out before response {request_id}"
            ) from error
        if isinstance(line, BaseException):
            raise line
        if not line:
            break
        message = json.loads(line)
        if message.get("id") == request_id:
            return message
    raise RuntimeError(f"Codex app server closed before response {request_id}")


def discover_hooks(cwd):
    codex_home = pathlib.Path(os.environ.get("CODEX_HOME", pathlib.Path.home() / ".codex"))
    with tempfile.TemporaryDirectory(prefix="codex-hook-discovery-") as isolated_home:
        isolated_home = pathlib.Path(isolated_home)
        if (codex_home / "config.toml").is_file():
            shutil.copy2(codex_home / "config.toml", isolated_home / "config.toml")
        if (codex_home / "plugins").is_dir():
            (isolated_home / "plugins").symlink_to(codex_home / "plugins", target_is_directory=True)
        environment = os.environ.copy()
        environment["CODEX_HOME"] = str(isolated_home)
        process = subprocess.Popen(
            ["codex", "app-server", "--stdio", "-c", 'sandbox_mode="danger-full-access"'],
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            env=environment,
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
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


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
