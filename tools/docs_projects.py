"""Mount the documentation of the other ASTRA projects in this site.

Each project keeps its reference beside the code it describes, in the `docs/` folder of its own repository.
`zensical.toml` names the ones this site shows, under `[project.extra.projects]`: `<name>` gives a repository (`repo`)
and a tag of it (`ref`), and that tag's `docs/` becomes `docs/<name>/` here. Its pages are then pages of this site like
any other: `zensical.toml`'s nav lists them under a tab, the search finds them, and a page here links to one by its
path.

`just docs` runs this before it builds (`_docs-prep`). A tag is fetched once, into `tmp/docs-projects/`, so only a new
`ref` needs the network. Only a tag is fetched, never a branch: what a build shows is what `zensical.toml` says.

`<name>=<checkout>` as an argument mounts the `docs/` of a local checkout instead, to see pages that no tag holds yet:
`just docs_local=tools=../astra-tools docs-serve`.

A mounted page that the nav leaves out would be built and reached from nowhere, so it is an error: when a project adds
a page, the commit that moves `ref` adds it to the nav.
"""

import argparse
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Any

try:
    import tomllib
except ModuleNotFoundError:  # Python 3.10, where Zensical brings tomli
    import tomli as tomllib

CONFIG = Path("zensical.toml")
DOCS = Path("docs")
"""The site's pages, where each project is mounted, relative to the repository's working tree."""

FETCHED = Path("tmp/docs-projects")
"""Where each fetched tag is kept, in a folder `<name>@<ref>`."""


def fetch(name: str, repo: str, ref: str) -> Path:
    """A checkout of `repo` at its tag `ref`, fetched unless an earlier run did."""
    checkout = FETCHED / f"{name}@{ref}"
    if not checkout.exists():
        part = checkout.with_name(checkout.name + ".part")
        shutil.rmtree(part, ignore_errors=True)
        try:
            subprocess.run(["git", "init", "--quiet", part], check=True)
            for arguments in (
                ["fetch", "--quiet", "--depth", "1", repo, f"refs/tags/{ref}"],
                ["checkout", "--quiet", "FETCH_HEAD"],
            ):
                subprocess.run(["git", *arguments], cwd=part, check=True)
        except subprocess.CalledProcessError:
            shutil.rmtree(part, ignore_errors=True)
            sys.exit(f"Error: can't fetch the tag {ref} of {repo}")
        part.rename(checkout)
    return checkout


def mount(name: str, checkout: Path) -> list[str]:
    """Make the `docs/` of `checkout` the folder `docs/<name>/`, and give its pages as the nav names them."""
    target = DOCS / name
    shutil.rmtree(target, ignore_errors=True)
    shutil.copytree(checkout / "docs", target)
    return sorted(page.relative_to(DOCS).as_posix() for page in target.rglob("*.md"))


def listed(nav: Any) -> set[str]:
    """Every page that `nav` names: zensical.toml's nav, or a part of it."""
    if isinstance(nav, str):
        return {nav}
    return set().union(*map(listed, nav.values() if isinstance(nav, dict) else nav))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument(
        "local",
        nargs="*",
        metavar="NAME=CHECKOUT",
        help="mount the docs/ of a local checkout, not of the project's tag",
    )
    local = dict(item.split("=", 1) for item in parser.parse_args().local)

    project = tomllib.loads(CONFIG.read_text(encoding="utf-8"))["project"]
    projects = project["extra"]["projects"]
    if unknown := sorted(local.keys() - projects.keys()):
        parser.error(f"{CONFIG} names no project {', '.join(unknown)}")

    in_nav = listed(project["nav"])
    left_out = []
    for name, source in projects.items():
        checkout = (
            Path(local[name])
            if name in local
            else fetch(name, source["repo"], source["ref"])
        )
        left_out += [page for page in mount(name, checkout) if page not in in_nav]
        print(
            f"docs/{name}/: {local.get(name) or source['repo'] + ' at ' + source['ref']}",
            file=sys.stderr,
        )

    for page in left_out:
        print(f"Error: {CONFIG}'s nav leaves out {page}", file=sys.stderr)
    return 1 if left_out else 0


if __name__ == "__main__":
    sys.exit(main())
