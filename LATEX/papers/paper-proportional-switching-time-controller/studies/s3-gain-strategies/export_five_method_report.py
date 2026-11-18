"""Export the four-method comparison from frozen, validated evidence."""

import csv
import hashlib
import json
from pathlib import Path

import numpy as np
from export_report import plt, table, tex

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RESULTS = HERE / "results"
LABELS = {"current-lqr": "LQR + common-P", "saved-common-p": "Common-P + gain",
          "strategy-marcolino": "Marcolino", "mpc5": "MPC-5"}
COLORS = {"current-lqr": "#333333", "saved-common-p": "#7570b3",
          "strategy-marcolino": "#0097a7", "mpc5": "#d95f02"}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def number(value, digits=3):
    return "--" if value is None else f"{value:.{digits}f}"


def load_selected():
    data = json.loads((RESULTS / "comparison.json").read_text())
    validation = json.loads((RESULTS / "validation.json").read_text())
    if validation["status"] != "passed":
        raise ValueError("Independent saved-evidence validation must pass first")
    comparison_digest = digest(RESULTS / "comparison.json")
    if comparison_digest not in validation["source_sha256"].values():
        raise ValueError("Validation does not match the current comparison")
    for record in (data, validation):
        for relative, expected in record["source_sha256"].items():
            if digest(ROOT / relative) != expected:
                raise ValueError(f"Stale input: {relative}")
    selected = ("current-lqr", "saved-common-p", "strategy-marcolino", "mpc5")
    methods = {m["name"]: m for m in data["methods"]}
    for name in selected[:-1]:
        if name not in methods:
            raise ValueError(f"Missing selected method: {name}")
    responses = {(r["method"], r["case"]): r for r in data["responses"]}
    period = float(sum(data["model"]["nominal_dwell"]))
    old_history = ROOT / "studies/s2-kawa-synthesis/results/history.csv"
    with old_history.open(newline="", encoding="utf-8-sig") as handle:
        history = list(csv.DictReader(handle))
    # MPC's saved times establish that its errors already lie on the shared grid.
    for scale, saved in enumerate(data["historical_mpc"], 1):
        case = f"article-{scale}x"
        rows = [r for r in history if r["method"] == "mpc5" and int(r["error_scale"]) == scale]
        times = np.array([float(r["time_ms"]) / 1000 for r in rows])
        errors = np.asarray(saved["errors"])
        np.testing.assert_allclose(times, np.arange(101) * period, atol=1e-13, rtol=0)
        np.testing.assert_allclose(errors, [float(r["normalized_error"]) for r in rows], atol=1e-12, rtol=0)
        states = np.array([[float(r[key]) for r in rows] for key in ("vc1_v", "vc2_v", "il_a")])
        normalized = np.linalg.solve(np.array(data["model"]["S"]), states - np.array(data["model"]["anchor"])[:, None])
        np.testing.assert_allclose(errors, np.linalg.norm(normalized, axis=0), atol=1e-10, rtol=0)
        stage_cost = sum(float(r["stage_cost"]) for r in rows[:-1])
        np.testing.assert_allclose(saved["cost"], stage_cost, atol=1e-10, rtol=0)
        below = np.flatnonzero(errors < .01)
        bad = np.flatnonzero(errors >= .01)
        sustained = 0 if not bad.size else int(bad[-1] + 1) if bad[-1] < 100 else None
        if (int(below[0]) if below.size else None, sustained) != (saved["first_cycle"], saved["sustained_cycle"]):
            raise ValueError("MPC threshold evidence disagrees")
        responses["mpc5", case] = dict(saved, errors=errors, clocked_errors=errors,
            cycle_times=times, clocked_times=times,
            anchor_sustained_time_ms=None if sustained is None else times[sustained] * 1000,
            clocked_sustained_time_ms=None if sustained is None else times[sustained] * 1000,
            final_clocked_error=float(errors[-1]), clocked_error_sum=float(np.sum(errors[:-1] ** 2)))
    return selected, responses


def main():
    selected, responses = load_selected()
    labels = LABELS
    colors = COLORS
    definitions = [
        (labels["current-lqr"], "Current LQR gain, checked afterward with a common-P certificate. Uniform scaling preserves the period."),
        (labels["saved-common-p"], "The original saved gain and certificate designed jointly in the Common-P synthesis study. Uniform scaling preserves the period."),
        (labels["strategy-marcolino"], "Current LQR gain with sequential boundary delays. The cycle can extend; the existing common-P guarantee does not cover this rule."),
        (labels["mpc5"], "The unchanged five-cycle constrained switching-time MPC reference. Its native terminal ingredients are retained; it is not checked by the common-P test here.")]
    protocol = ("The comparison uses only the original 1x, 2x and 3x cases, where matching saved MPC-5 evidence exists. "
                "Each method uses the same converter and nominal schedule, with T=286 us and minimum applied dwell 3 us. "
                "State errors use the scale diag(10,20,1), and timing offsets use the 10 us scale. "
                "The 2x and 3x starts have negative current and are mathematical stress tests. No optimization or simulation was rerun for this document.")
    reading = ("Anchor n/ms gives the sustained anchor-threshold cycle and its actual elapsed time. "
               "Clock ms uses identical samples at j*T against the original clocked reference. The threshold is normalized error below 0.01, "
               "maintained through the rest of the saved horizon. A dash means it was not sustained. Final clock error is measured at 28.6 ms. "
               "Plots show the first 6 ms of the saved 100-cycle responses. Each curve keeps its recorded sampling times.")
    cost_note = ("J100 sums squared normalized anchor error and 0.001 times squared normalized applied interior timing offsets over 100 actual cycles. "
                 "It excludes MPC's terminal penalty and does not penalize Marcolino's extra terminal extension. "
                 "Because Marcolino samples different physical times and phases, its anchor J100 is not a fair common-clock tracking cost.")
    limits = ("The common-P guarantee covers the conditioned linearized families of the two uniformly scaled gains, not global nonlinear stability. "
              "Marcolino is outside that guarantee. MPC-5 is an unchanged reference, not a newly common-P-certified controller. "
              "All reported nonlinear responses are simulation evidence. No hardware deadline or state-safety claim is made.")
    md = ["# Four-method comparison", protocol, "## Methods"]
    md.extend(f"- **{name}.** {description}" for name, description in definitions)
    md += ["## Reading the comparison", reading, cost_note, limits]
    document = r"""\documentclass[11pt,a4paper]{article}
\usepackage[margin=20mm]{geometry}
\usepackage[T1]{fontenc}
\usepackage{lmodern,booktabs,graphicx,microtype}
\usepackage[hidelinks]{hyperref}
\setlength{\parindent}{0pt}
\setlength{\parskip}{5pt}
\begin{document}
\begin{center}{\Large Four-method comparison}\end{center}
"""
    document += tex(protocol) + "\n\\section*{Methods}\n\\begin{itemize}\n"
    document += "\n".join("\\item \\textbf{" + tex(name) + ".} " + tex(desc) for name, desc in definitions)
    document += "\n\\end{itemize}\n"
    document += "\n\\section*{Reading the comparison}\n" + tex(reading) + "\n\n" + tex(cost_note) + "\n\n" + tex(limits)
    plt.rcParams.update({"font.size": 9, "axes.labelsize": 9, "axes.titlesize": 10,
                         "legend.fontsize": 8, "xtick.labelsize": 8, "ytick.labelsize": 8,
                         "pdf.fonttype": 42})
    (HERE / "figures").mkdir(exist_ok=True)
    rows_for_csv = []
    for scale in (1, 2, 3):
        case = f"article-{scale}x"
        heading = f"{scale}x initial error"
        rows = []
        fig, axes = plt.subplots(2, 1, figsize=(160 / 25.4, 5.1), sharex=True, layout="constrained")
        for name in selected:
            r = responses[name, case]
            anchor = "--" if r["sustained_cycle"] is None else f"{r['sustained_cycle']} / {number(r['anchor_sustained_time_ms'])}"
            rows.append([labels[name], f"{r['cost']:.4f}", anchor,
                         number(r["clocked_sustained_time_ms"]), f"{r['final_clocked_error']:.3g}",
                         f"{r['minimum_dwell_us']:.3f}"])
            for ax, field, clock in ((axes[0], "clocked_errors", "clocked_times"),
                                     (axes[1], "errors", "cycle_times")):
                ax.semilogy(np.asarray(r[clock]) * 1000, r[field], color=colors[name],
                            label=labels[name], linewidth=1.4, marker="o", markersize=2)
            rows_for_csv.append(dict(method=name, case=case, anchor_cost=r["cost"],
                anchor_sustained_cycle=r["sustained_cycle"], anchor_sustained_time_ms=r["anchor_sustained_time_ms"],
                clocked_sustained_time_ms=r["clocked_sustained_time_ms"], final_clocked_error=r["final_clocked_error"],
                minimum_dwell_us=r["minimum_dwell_us"], clocked_error_sum=r["clocked_error_sum"]))
        for ax, title in zip(axes, ("Tracking the original clocked reference", "Cycle-anchor error at actual cycle starts")):
            ax.axhline(.01, color="gray", linewidth=.8, linestyle=":")
            ax.set_title(title)
            ax.set_ylabel("Normalized error")
            ax.set_xlim(0, 6)
            ax.set_ylim(1e-5, 5)
            ax.grid(alpha=.2)
        axes[0].legend(ncol=2, loc="upper right")
        axes[-1].set_xlabel("Actual elapsed time [ms]")
        stem = f"five-method-{scale}x"
        fig.savefig(HERE / "figures" / f"{stem}.pdf", bbox_inches="tight")
        fig.savefig(HERE / "figures" / f"{stem}.png", dpi=180, bbox_inches="tight")
        plt.close(fig)
        md_table, tex_table = table(["Method", "J100", "Anchor n/ms", "Clock ms", "Final clock err", "Min dwell us"], rows)
        md += [f"## {heading}", md_table, f"![{heading}](figures/{stem}.png)"]
        document += "\n\\clearpage\\section*{" + tex(heading) + "}\n"
        document += "\\textit{J100 is anchor-sampled; Marcolino's value is not a common-clock cost.}\n" + tex_table
        document += "\\begin{center}\\includegraphics[width=\\linewidth]{figures/" + stem + ".pdf}\\end{center}\n"
        if scale == 3:
            note = ("Marcolino's small error at its actual final cycle boundary is sampled at a different phase. "
                    "Its error on the shared nominal final clock remains above 0.01, as shown in the table.")
            md.append(note)
            document += tex(note) + "\n"
    md += ["## Source evidence", "Filtered from [the validated comparison](results/comparison.json) and its "
           "[independent validation](results/validation.json). MPC-5 times, errors and costs are additionally checked "
           "against its saved fixed-period history. The full report is unchanged."]
    document += "\n\\end{document}\n"
    (HERE / "five-method-comparison.md").write_text("\n\n".join(md) + "\n", encoding="utf-8")
    (HERE / "five-method-comparison.tex").write_text(document, encoding="utf-8")
    fields = list(rows_for_csv[0])
    with (RESULTS / "five-method-metrics.csv").open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        writer.writerows(rows_for_csv)
    inputs = [RESULTS / "comparison.json", RESULTS / "validation.json"]
    inputs += [Path(__file__).resolve(), HERE / "export_report.py", ROOT / "studies/s2-kawa-synthesis/results/history.csv"]
    (RESULTS / "five-method-inputs.json").write_text(json.dumps(dict(selected_methods=selected,
        source_sha256={p.relative_to(ROOT).as_posix(): digest(p) for p in inputs}), indent=2) + "\n")
    print("Four-method report exported; 12 matched method/case rows.")


if __name__ == "__main__":
    main()
