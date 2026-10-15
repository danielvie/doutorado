"""Reject unapproved changes to the manuscript's protected Introduction."""
import hashlib
from pathlib import Path

source = (Path(__file__).resolve().parents[1] / "latex" / "main.tex").read_bytes()
start = source.index(br"\section{Introduction}")
end = source.index(br"\section{Problem formulation and one-cycle model}", start)
expected = "00b49c6f8b5d992168c44272c0e194aa57f9d06f48313cff831dab582d9343f9"
# Git may normalize checkout line endings; no textual edits are permitted.
actual = hashlib.sha256(source[start:end].replace(b"\r\n", b"\n")).hexdigest()
if actual != expected:
    raise SystemExit("Introduction changed. Explicit author approval is required.")
print("Protected Introduction unchanged.")
