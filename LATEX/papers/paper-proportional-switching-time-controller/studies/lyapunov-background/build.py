#!/usr/bin/env python3
"""Assemble lyapunov-convex-optimization.html from parts/*.html.

    python build.py

Reads study_data.json (written by export_study_data.m) and latex/metrics.tex,
substitutes every {{path.to.value|format}} placeholder in the parts, injects the
data object into the script, and writes the finished document.

Standard library only. Run it after export_study_data.m so that the prose and the
figures always quote the same numbers.
"""

import json
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
PARTS = os.path.join(HERE, "parts")
OUT = os.path.join(HERE, "lyapunov-convex-optimization.html")

PART_ORDER = [
    "00-head.html",
    "10-intro.html",
    "20-theory.html",
    "30-generic.html",
    "40-matlab.html",
    "50-paper.html",
    "60-close.html",
    "90-script.html",
]


# --------------------------------------------------------------------------
# data


def load_data():
    with open(os.path.join(HERE, "study_data.json"), "r", encoding="utf-8") as fh:
        return json.load(fh)


def load_metrics():
    """latex/metrics.tex holds the numbers the manuscript itself quotes."""
    path = os.path.join(ROOT, "latex", "metrics.tex")
    macros = {}
    pattern = re.compile(r"\\newcommand\{\\(\w+)\}\{([^}]*)\}")
    with open(path, "r", encoding="utf-8") as fh:
        for line in fh:
            match = pattern.search(line)
            if match:
                macros[match.group(1)] = match.group(2)
    return macros


def derived(data):
    """Values the prose quotes that are cheaper to compute here than to export."""
    g = data["generic"]
    q = max(g["q"])
    g["qsq"] = q * q

    # Peak transient amplification of the Euclidean norm under the greedy
    # adversary, over the initial direction that maximises it. Mirrors the
    # policy used by Laboratory 2.
    A = [g["A1"], g["A2"]]

    def mv(M, x):
        return [M[0][0] * x[0] + M[0][1] * x[1], M[1][0] * x[0] + M[1][1] * x[1]]

    def nrm(x):
        return math.hypot(x[0], x[1])

    best = 0.0
    for i in range(721):
        a = math.pi * i / 720
        x = [math.cos(a), math.sin(a)]
        peak = 1.0
        for _ in range(30):
            cand = [mv(M, x) for M in A]
            x = cand[0] if nrm(cand[0]) >= nrm(cand[1]) else cand[1]
            peak = max(peak, nrm(x))
        best = max(best, peak)
    g["peak"] = best

    data["paper"]["condsqrt"] = math.sqrt(data["paper"]["condP"])
    return data


# --------------------------------------------------------------------------
# placeholders

PLACEHOLDER = re.compile(r"\{\{([A-Za-z0-9_.]+)(?:\|([^}]+))?\}\}")


def resolve(root, path):
    node = root
    for key in path.split("."):
        if isinstance(node, list):
            node = node[int(key)]
        else:
            node = node[key]
    return node


def substitute(text, data, metrics):
    def repl(match):
        path, spec = match.group(1), match.group(2)
        if path.startswith("metrics."):
            value = metrics[path.split(".", 1)[1]]
            return value if spec is None else format(float(value), spec)
        value = resolve(data, path)
        if spec is None:
            return str(value)
        if spec == "d":
            return format(int(round(value)), "d")
        return format(float(value), spec)

    return PLACEHOLDER.sub(repl, text)


# --------------------------------------------------------------------------
# the one figure that is easier to generate than to hand-place


def schedule_group(data):
    """Nine mode intervals drawn to scale, for the diagram in section 5.1."""
    bounds = data["schedule"]["boundaries_us"]
    modes = data["schedule"]["modes"]
    total = bounds[-1]
    width = 340.0
    out = []
    for i in range(len(bounds) - 1):
        x0 = bounds[i] / total * width
        x1 = bounds[i + 1] / total * width
        out.append(
            '<rect x="%.2f" y="42" width="%.2f" height="54" rx="2" '
            'class="%s" opacity="%.2f"/>'
            % (x0, x1 - x0, "fill-blue" if i % 2 else "fill-teal", 0.55 if i % 2 else 0.4)
        )
        out.append(
            '<text class="lbl sm" x="%.2f" y="74" text-anchor="middle">%d</text>'
            % ((x0 + x1) / 2, modes[i])
        )
    for i, t in enumerate(bounds):
        x = t / total * width
        pinned = i in (0, len(bounds) - 1)
        out.append(
            '<line x1="%.2f" y1="34" x2="%.2f" y2="104" stroke="%s" '
            'stroke-width="%s"%s/>'
            % (x, x, "var(--ink-3)" if pinned else "var(--crimson)",
               "2.5" if pinned else "2",
               "" if pinned else ' stroke-dasharray="3 2"')
        )
    return "\n".join(out)


# --------------------------------------------------------------------------


def main():
    data = derived(load_data())
    metrics = load_metrics()

    chunks = []
    for name in PART_ORDER:
        path = os.path.join(PARTS, name)
        with open(path, "r", encoding="utf-8") as fh:
            chunks.append(fh.read())
    html = "\n".join(chunks)

    html = html.replace('<g id="sched-static"></g>',
                        '<g id="sched-static">%s</g>' % schedule_group(data))
    html = substitute(html, data, metrics)
    html = html.replace("/*__STUDY_DATA__*/",
                        json.dumps(data, separators=(",", ":")))

    leftover = PLACEHOLDER.findall(html)
    if leftover:
        print("unresolved placeholders: %s" % sorted({p for p, _ in leftover}),
              file=sys.stderr)
        return 1

    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(html)
    print("wrote %s (%.1f kB)" % (os.path.relpath(OUT, ROOT), len(html) / 1024))
    return 0


if __name__ == "__main__":
    sys.exit(main())
