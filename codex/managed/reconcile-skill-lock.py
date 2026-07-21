#!/usr/bin/env python3
"""List installed skills owned by a source but absent from its selected set."""

import json
import pathlib
import sys


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit("usage: reconcile-skill-lock.py LOCK SOURCE [SELECTED ...]")

    lock_path = pathlib.Path(sys.argv[1])
    source = sys.argv[2]
    selected = set(sys.argv[3:])
    lock = json.loads(lock_path.read_text())

    for name, metadata in sorted(lock.get("skills", {}).items()):
        if metadata.get("source") == source and name not in selected:
            print(name)


if __name__ == "__main__":
    main()
