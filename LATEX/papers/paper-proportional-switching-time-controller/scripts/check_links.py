"""Check local file targets in maintained Markdown and HTML, without network access.

Historical archives, agent transcripts, build output, and study handoffs retain
old paths intentionally. Fragment identifiers and prose/code path mentions are
not checked. Run from any directory: python /path/to/scripts/check_links.py.
"""

from html.parser import HTMLParser
from pathlib import Path
import re
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
SKIP = {"archive", "build", ".pi", ".mado-html", "handoff", "__pycache__"}


class Links(HTMLParser):
    def __init__(self) -> None:
        super().__init__()
        self.targets: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        for name, value in attrs:
            if name in {"href", "src"} and value:
                self.targets.append(value)


def main() -> int:
    failures = []
    count = 0
    for source in sorted(ROOT.rglob("*")):
        relative = source.relative_to(ROOT)
        if set(relative.parts) & SKIP or source.suffix not in {".md", ".html"}:
            continue
        text = source.read_text(encoding="utf-8")
        if source.suffix == ".html":
            parser = Links()
            parser.feed(text)
            targets = parser.targets
        else:
            # Ignore code fences. Paths written as examples are not hyperlinks.
            text = re.sub(r"```.*?```", "", text, flags=re.S)
            targets = re.findall(r"\[[^\]]*\]\(([^)]+)\)", text)
            targets = [target.strip().split(' "', 1)[0].strip("<>") for target in targets]
        for target in targets:
            url = urlsplit(target)
            if url.scheme or url.netloc or not url.path:
                continue
            count += 1
            resolved = (source.parent / unquote(url.path)).resolve()
            if not resolved.exists():
                failures.append(f"{relative.as_posix()}: {target}")
    if failures:
        print("Missing local link targets:\n" + "\n".join(failures))
        return 1
    print(f"PASS: {count} local file links in maintained Markdown and HTML.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
