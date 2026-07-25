#!/usr/bin/env python3
"""List installed GitHub skills whose upstream files no longer exist."""

import json
import pathlib
import subprocess
import sys
import tempfile


def checkout(
    url: str, ref: str | None, target: pathlib.Path, *, history: bool = False
) -> None:
    if ref:
        subprocess.run(["git", "init", "--quiet", str(target)], check=True)
        subprocess.run(["git", "-C", str(target), "remote", "add", "origin", url], check=True)
        depth = [] if history else ["--depth", "1"]
        subprocess.run(
            ["git", "-C", str(target), "fetch", "--quiet", *depth, "origin", ref],
            check=True,
        )
        subprocess.run(
            ["git", "-C", str(target), "checkout", "--quiet", "--detach", "FETCH_HEAD"],
            check=True,
        )
    else:
        depth = [] if history else ["--depth", "1"]
        subprocess.run(
            ["git", "clone", "--quiet", *depth, url, str(target)],
            check=True,
        )


def main() -> None:
    if len(sys.argv) < 3:
        raise SystemExit(
            "usage: find-deleted-skills.py LOCK INSTALLED_JSON [MANAGED_SOURCE ...]"
        )

    lock_path = pathlib.Path(sys.argv[1])
    lock = json.loads(lock_path.read_text()) if lock_path.is_file() else {"skills": {}}
    installed = json.loads(pathlib.Path(sys.argv[2]).read_text())
    locked_names = set(lock.get("skills", {}))
    orphan_names = {
        item["name"] for item in installed if item.get("name") not in locked_names
    }
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

    deleted: set[str] = set()
    with tempfile.TemporaryDirectory(prefix="codex-skill-sources-") as temporary:
        root = pathlib.Path(temporary)
        ordered_sources = sorted(
            sources.items(), key=lambda item: (item[0][0], item[0][1] or "")
        )
        for index, ((url, ref), skills) in enumerate(ordered_sources):
            source = root / str(index)
            checkout(url, ref, source)
            deleted.update(name for name, path in skills if not (source / path).is_file())

        if orphan_names:
            current_names: set[str] = set()
            historical_names: set[str] = set()
            for index, url in enumerate(sorted(set(sys.argv[3:])), start=len(sources)):
                source = root / str(index)
                checkout(url, None, source, history=True)
                current_names.update(
                    path.parent.name for path in source.rglob("SKILL.md")
                )
                history = subprocess.run(
                    [
                        "git",
                        "-C",
                        str(source),
                        "log",
                        "--all",
                        "--format=",
                        "--name-only",
                        "--",
                        "**/SKILL.md",
                    ],
                    check=True,
                    capture_output=True,
                    text=True,
                ).stdout
                historical_names.update(
                    pathlib.PurePosixPath(line).parent.name
                    for line in history.splitlines()
                    if line
                )
            deleted.update(orphan_names & historical_names - current_names)

    print("\n".join(sorted(deleted)))


if __name__ == "__main__":
    main()
