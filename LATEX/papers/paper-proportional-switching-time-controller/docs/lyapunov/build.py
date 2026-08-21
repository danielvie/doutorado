import json, re
frag = json.load(open("frag.json"))
frag["PHASE_BOX_X"] = "60"; frag["PHASE_BOX_Y"] = "30"
frag["BOWL_RINGS"] = "".join(
    '<ellipse cx="120" cy="70" rx="%d" ry="%d" fill="none" stroke="var(--acc3)" '
    'stroke-width="1.3" opacity="%.2f"/>' % (r, int(r*0.66), 0.85 - k*0.13)
    for k, r in enumerate((16, 34, 54, 78)))

html = "".join(open(f).read() for f in ("p1.html", "p2.html", "p3.html", "p4.html"))
html = html.replace("--ink3:#8b8video;", "--ink3:#8b867f;")
missing = set(re.findall(r"\{\{(\w+)\}\}", html)) - set(frag)
if missing: raise SystemExit("MISSING: %s" % sorted(missing))
for k, v in frag.items():
    html = html.replace("{{%s}}" % k, str(v))
html = html.replace('<c><r>1.75</r><r>0.25</r></c><c><r>0.25</r><r>0.5</r></c></mat>. Same stability',
    '<c><r>19/12</r><r>1/4</r></c><c><r>1/4</r><r>5/12</r></c></mat> ≈ '
    '<mat style="font-size:.9em"><c><r>1.583</r><r>0.250</r></c><c><r>0.250</r><r>0.417</r></c></mat>. Same stability')
html = html.replace('dipping below its starting value near <b>t ≈ 0.2</b>',
                    'dipping below its starting value near <b>t ≈ 0.22</b>')
assert "19/12" in html and "t ≈ 0.22" in html
open("lyapunov.html", "w").write(html)
print("built lyapunov.html:", len(html), "bytes; unresolved:", re.findall(r"\{\{\w+\}\}", html))
