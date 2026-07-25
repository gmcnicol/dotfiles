#!/usr/bin/env python3
"""List globally locked GitHub skills whose upstream files no longer exist."""

import json
import pathlib
import subprocess
import sys
import tempfile


def checkout(url: str, ref: str | None, target: pathlib.Path) -> None:
    if ref:
        subprocess.run(["git", "init", "--quiet", str(target)], check=True)
        subprocess.run(["git", "-C", str(target), "remote", "add", "origin", url], check=True)
        subprocess.run(
            ["git", "-C", str(target), "fetch", "--quiet", "--depth", "1", "origin", ref],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(target), "checkout", "--quiet", "--detach", "FETCH_HEAD"],
            check=True,
        )
    else:
        subprocess.run(
            ["git", "clone", "--quiet", "--depth", "1", url, str(target)],
            check=True,
        )


def main() -> None:
    if len(sys.argv) != 2:
        raise SystemExit("usage: find-deleted-skills.py LOCK")

    lock = json.loads(pathlib.Path(sys.argv[1]).read_text())
    sources: dict[tuple[str, str | None], list[tuple[str, pathlib.PurePosixPath]]] = {}
    for name, metadata in lock.get("skills", {}).items():
        path = pathlib.PurePosixPath(metadata.get("skillPath", ""))
        url = metadata.get("sourceUrl")
        if (
            metadata.get("sourceType") != "github"
            or not url
            or not path.parts
            or path.is_absolute()
            or ".." in path.parts
        ):
            continue
        sources.setdefault((url, metadata.get("ref")), []).append((name, path))

    deleted: list[str] = []
    with tempfile.TemporaryDirectory(prefix="codex-skill-sources-") as temporary:
        root = pathlib.Path(temporary)
        ordered_sources = sorted(
            sources.items(), key=lambda item: (item[0][0], item[0][1] or "")
        )
        for index, ((url, ref), skills) in enumerate(ordered_sources):
            source = root / str(index)
            checkout(url, ref, source)
            deleted.extend(name for name, path in skills if not (source / path).is_file())

    print("\n".join(sorted(deleted)))


if __name__ == "__main__":
    main()
