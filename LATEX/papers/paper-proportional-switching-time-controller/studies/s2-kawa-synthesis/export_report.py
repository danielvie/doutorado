"""Render saved simulation evidence without solving or propagating the plant."""

import csv
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.ticker import MaxNLocator
import numpy as np
from scipy.io import loadmat

from plot_trajectories import plot_trajectory_comparison

HERE = Path(__file__).resolve().parent
RESULTS = HERE / "results"
FIGURES = HERE / "figures"
METHODS = ("current", "mpc5", "kawa_decay")
LABELS = dict(zip(METHODS, ("Current LQR", "MPC-5", "Common-P gain synthesis")))
COLORS = dict(zip(METHODS, ("#2867a8", "#d55e00", "#aa3377")))
STYLES = dict(zip(METHODS, ("-", "--", ":")))


def read_rows(name):
    with (RESULTS / name).open(newline="", encoding="utf-8-sig") as handle:
        return [{key: value if key in ("method", "source_method") else float(value)
                 for key, value in row.items()} for row in csv.DictReader(handle)
                if "method" not in row or row["method"] in (*METHODS, "reference")]


def select(rows, method, scale):
    return [row for row in rows if row["method"] == method and row["error_scale"] == scale]


def values(rows, key):
    return np.array([row[key] for row in rows])


def style(method):
    return dict(color=COLORS[method], linestyle=STYLES[method], linewidth=2.0,
                label=LABELS[method])


def finish(figure, name, axes, legend=True):
    for ax in np.array(axes).flat:
        ax.grid(True, alpha=0.22, linewidth=0.6)
        ax.spines[["top", "right"]].set_visible(False)
    if legend:
        handles, labels = np.array(axes).flat[0].get_legend_handles_labels()
        figure.legend(handles, labels, ncol=2, loc="upper center", frameon=False,
                      bbox_to_anchor=(0.5, 1.0))
    figure.subplots_adjust(top=0.90, bottom=0.09,
                           left=0.14, right=0.97, hspace=0.40)
    figure.savefig(FIGURES / f"{name}.pdf", metadata={"Creator": "kawa-synthesis/export_report.py"})
    figure.savefig(FIGURES / f"{name}.png", dpi=160)
    plt.close(figure)


def plot_speed(history, summary):
    fig, axes = plt.subplots(3, 1, figsize=(6.7, 7.4))
    for ax, scale in zip(axes, (1, 2, 3)):
        cases = [select(summary, method, scale)[0] for method in METHODS]
        cycles = [row["sustained_cycle_below_001"] for row in cases]
        fastest = min(value for value in cycles if np.isfinite(value))
        for y, (method, cycle) in enumerate(zip(METHODS, cycles)):
            sample = next(row for row in select(history, method, scale) if row["cycle"] == cycle)
            winner = cycle == fastest
            ax.barh(y, cycle, height=0.60, color=COLORS[method],
                    alpha=1 if winner else 0.7, edgecolor="black" if winner else "none")
            ax.text(cycle + 0.12, y, f"{int(cycle)} cycles / {sample['time_ms']:.3f} ms",
                    va="center", fontsize=11, fontweight="bold" if winner else "normal")
        ax.set_yticks(range(len(METHODS)), [LABELS[method] for method in METHODS])
        ax.invert_yaxis()
        ax.set_xlim(0, max(cycles) * 1.52)
        ax.xaxis.set_major_locator(MaxNLocator(integer=True, nbins=6))
        ax.set_title(f"Initial error {scale}x", loc="left", fontweight="bold")
        ax.spines[["top", "right", "left"]].set_visible(False)
        ax.tick_params(axis="y", length=0)
        ax.grid(axis="x", alpha=0.2)
        ax.set_axisbelow(True)
    axes[-1].set_xlabel(r"Completed cycles to sustained $E_k<0.01$")
    fig.subplots_adjust(left=0.21, right=0.98, top=0.96, bottom=0.08, hspace=0.55)
    for extension in ("pdf", "png"):
        fig.savefig(FIGURES / f"convergence_speed.{extension}", dpi=160)
    plt.close(fig)


def plot_error_cost(history, summary):
    fig_error, axes_error = plt.subplots(3, 1, figsize=(6.7, 8.0), sharex=True)
    fig_cost, axes_cost = plt.subplots(3, 1, figsize=(6.7, 7.3), sharex=True)
    for row, scale in enumerate((1, 2, 3)):
        for method in METHODS:
            rows = select(history, method, scale)
            k, error = values(rows, "cycle"), values(rows, "normalized_error")
            valid = error > 1e-12
            axes_error[row].semilogy(k[valid], error[valid], **style(method))
            axes_cost[row].plot(k, values(rows, "cumulative_cost"), **style(method))
            metric = select(summary, method, scale)[0]
            crossing = metric["sustained_cycle_below_001"]
            if np.isfinite(crossing) and crossing <= 16:
                axes_error[row].plot(crossing, error[int(crossing)], "o", markersize=6,
                                     color=COLORS[method])
        axes_error[row].axhline(0.01, color="0.3", linestyle="--", linewidth=1)
        axes_error[row].set(xlim=(0, 16), ylim=(1e-4, 4), ylabel="Normalized error")
        axes_cost[row].set(xlim=(0, 25), ylabel="Applied cost")
        for ax in (axes_error[row], axes_cost[row]):
            ax.set_title(f"Initial error {scale}x", loc="left", fontweight="bold")
    axes_error[-1].set_xlabel("Completed cycles")
    axes_cost[-1].set_xlabel("Completed cycles")
    finish(fig_error, "convergence_errors", axes_error)
    finish(fig_cost, "cost", axes_cost)


def plot_conditioning(history):
    fig_beta, axes_beta = plt.subplots(3, 1, figsize=(6.7, 8.0), sharex=True)
    fig_dwell, axes_dwell = plt.subplots(3, 1, figsize=(6.7, 8.0), sharex=True)
    for row, scale in enumerate((1, 2, 3)):
        for method in METHODS:
            rows = select(history, method, scale)[:20]
            k = values(rows, "cycle")
            if method != "mpc5":
                axes_beta[row].step(k, values(rows, "beta"), where="post", **style(method))
            axes_dwell[row].step(k, values(rows, "minimum_dwell_us"), where="post", **style(method))
        axes_beta[row].set(ylim=(-0.03, 1.06), ylabel=r"Applied fraction $\beta$")
        axes_dwell[row].axhspan(0, 3, color="0.9")
        axes_dwell[row].axhline(3, color="0.4", linestyle="--", linewidth=1)
        axes_dwell[row].set(ylim=(0, 24), ylabel=r"Minimum dwell ($\mu$s)")
        for ax in (axes_beta[row], axes_dwell[row]):
            ax.set_xlim(0, 19)
            ax.set_title(f"Initial error {scale}x", loc="left", fontweight="bold")
    axes_beta[-1].set_xlabel("Cycle-start index")
    axes_dwell[-1].set_xlabel("Cycle-start index")
    finish(fig_beta, "conditioning", axes_beta)
    finish(fig_dwell, "dwells", axes_dwell)


def plot_physical(trajectories):
    fields = ("vc1_v", "vc2_v", "il_a")
    labels = (r"$v_{C_1}$ (V)", r"$v_{C_2}$ (V)", r"$i_L$ (A)")
    for scale in (1, 2, 3):
        fig, axes = plt.subplots(3, 1, figsize=(6.7, 8.0), sharex=True)
        for method in ("reference", *METHODS):
            rows = select(trajectories, method, scale)
            line_style = dict(color="0.4", linestyle="--", linewidth=1.3, label="Reference")
            if method != "reference":
                line_style = style(method)
            for ax, field in zip(axes, fields):
                ax.plot(values(rows, "time_ms"), values(rows, field), **line_style)
                ax.set_xlim(0, 12 * 0.286)
        for ax, label in zip(axes, labels):
            ax.set_ylabel(label)
        axes[-1].set_xlabel("Time (ms)")
        finish(fig, f"physical_states_{scale}x", axes)


def plot_timing(timing):
    fig, ax = plt.subplots(figsize=(6.7, 3.4))
    positions = np.arange(len(METHODS))[::-1]
    for index, (method, y) in enumerate(zip(METHODS, positions)):
        row = next(row for row in timing if row["method"] == method)
        median, p95 = row["median_us"], row["p95_us"]
        ax.plot([median, p95], [y, y], color=COLORS[method], linewidth=2)
        ax.scatter(median, y, color=COLORS[method], s=26,
                   label="Median" if index == 0 else None, zorder=3)
        ax.scatter(p95, y, color=COLORS[method], s=26, marker="D",
                   label="p95" if index == 0 else None, zorder=3)
        ax.text(1.03, y, f"{median:.1f} / {p95:.1f}", va="center",
                transform=ax.get_yaxis_transform(), fontsize=11)
    ax.set_yticks(positions, [LABELS[method] for method in METHODS])
    ax.set_ylim(-0.55, len(METHODS) - 0.45)
    ax.set_xscale("log")
    ax.set_xlabel(r"Host controller time ($\mu$s), logarithmic scale")
    ax.spines[["top", "right", "left"]].set_visible(False)
    ax.grid(axis="x", alpha=0.22)
    ax.tick_params(axis="y", length=0)
    ax.text(1.03, 1.06, r"Median / p95 ($\mu$s)", transform=ax.transAxes, fontsize=11)
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, 1.42), ncol=2, frameon=False)
    fig.subplots_adjust(left=0.18, right=0.79, top=0.77, bottom=0.24)
    for extension in ("pdf", "png"):
        fig.savefig(FIGURES / f"computation.{extension}", dpi=160)
    plt.close(fig)


def number(value, digits=5):
    return "--" if not np.isfinite(value) else f"{value:.{digits}g}"


def integer(value):
    return "--" if not np.isfinite(value) else str(int(value))


def table(name, columns, header, rows):
    content = [rf"\begin{{tabular}}{{{columns}}}", r"\toprule", header + r" \\", r"\midrule"]
    content += [" & ".join(row) + r" \\" for row in rows]
    content += [r"\bottomrule", r"\end{tabular}"]
    (RESULTS / name).write_text("\n".join(content) + "\n", encoding="utf-8")


def write_tables(synthesis, summary, timing):
    candidates = (("current", synthesis["current"]),
                  ("kawa_decay", synthesis["candidates"]["decay"]))
    rows = [[LABELS[method], number(c["raw_radius"], 7), number(c["gain_frobenius"]),
             number(c["min_eigenvalue_P"]), *[number(q) for q in c["endpoint_decreases"]]]
            for method, c in candidates]
    table("synthesis_table.tex", "lrrrrr",
          r"Method & $\operatorname{spr}(A_c)$ & $\|K\|_F$ & $\lambda_{\min}(P)$ & $\lambda_{\min}(Q_0)$ & $\lambda_{\min}(Q_1)$", rows)
    rows = []
    for scale in (1, 2, 3):
        for method in METHODS:
            row = select(summary, method, scale)[0]
            rows.append([f"{scale}x", LABELS[method], number(row["evaluation_cost"], 6),
                         integer(row["first_cycle_below_001"]), integer(row["sustained_cycle_below_001"]),
                         number(row["minimum_dwell_us"], 4), number(row["minimum_beta"], 4),
                         integer(row["conditioned_cycles"]) if method != "mpc5" else "--"])
    table("performance_table.tex", "llrrrrrr",
          r"Scale & Method & $J_{100}$ & First & Sustained & Min. dwell ($\mu$s) & Min. $\beta$ & Scaled cycles", rows)
    rows = []
    for method in METHODS:
        cases = [select(summary, method, scale)[0] for scale in (1, 2, 3)]
        rows.append([LABELS[method], *[number(row["evaluation_cost"], 6) for row in cases],
                     *[integer(row["sustained_cycle_below_001"]) for row in cases]])
    table("visual_summary.tex", "lrrrrrr",
          r"Method & \multicolumn{3}{c}{$J_{100}$} & \multicolumn{3}{c}{Threshold cycle} \\"
          "\n" + r" & 1x & 2x & 3x & 1x & 2x & 3x", rows)
    cost_rows = [[LABELS[method], *[number(select(summary, method, scale)[0]["evaluation_cost"], 6)
                                  for scale in (1, 2, 3)]] for method in METHODS]
    table("cost_summary.tex", "lrrr", r"Method & $J_{100}$, 1x & $J_{100}$, 2x & $J_{100}$, 3x", cost_rows)
    rows = [[LABELS[row["method"]], integer(row["samples"]), f"{row['median_us']:.2f}",
             f"{row['p95_us']:.2f}", f"{row['cold_us']:.2f}"] for row in timing]
    table("timing_table.tex", "lrrrr",
          r"Method & Calls & Median ($\mu$s) & p95 ($\mu$s) & First observation ($\mu$s)", rows)


def write_macros(synthesis, timing, metadata):
    decay = synthesis["candidates"]["decay"]
    counts = timing[0]
    macros = dict(
        KawaRateLower=f"{decay['bisection_lower']:.12f}",
        KawaRateUpper=f"{decay['bisection_upper']:.12f}",
        KawaOpenRadius=f"{decay['analytical_rate_floor']:.12f}",
        KawaTimingStates=str(len(read_rows("timing_states.csv"))),
        KawaTimingCalls=integer(counts["samples"]),
        KawaTimingWarmups=integer(counts["warmup_calls"]),
        KawaMatlabRelease=str(metadata["matlab_release"]),
    )
    (RESULTS / "macros.tex").write_text(
        "% Generated from full-precision saved evidence.\n" +
        "".join(rf"\newcommand{{\{key}}}{{{value}}}" + "\n" for key, value in macros.items()),
        encoding="utf-8")


def write_convergence_notes(history, summary):
    comments = []
    for scale in (1, 2, 3):
        cases = [select(summary, method, scale)[0] for method in METHODS]
        best = min(cases, key=lambda row: row["sustained_cycle_below_001"])
        cycle = best["sustained_cycle_below_001"]
        sample = next(row for row in select(history, best["method"], scale) if row["cycle"] == cycle)
        comments.append(f"{scale}x: {LABELS[best['method']]}, "
                        f"{int(cycle)} cycles / {sample['time_ms']:.3f} ms")
    content = "\\panelnote{\\textbf{Fastest observed:} " + "; ".join(comments) + ".}\n"
    (RESULTS / "convergence_notes.tex").write_text(content, encoding="utf-8")


def write_interpretation(summary):
    winners = [min((select(summary, method, scale)[0] for method in METHODS),
                   key=lambda row: row["evaluation_cost"])["method"] for scale in (1, 2, 3)]
    comments = []
    if len(set(winners)) == 1:
        comments.append(f"{LABELS[winners[0]]} has the lowest $J_{{100}}$ in all three cases.")
    for method in ("kawa_decay",):
        changes = [100 * (1 - select(summary, method, scale)[0]["evaluation_cost"] /
                         select(summary, "current", scale)[0]["evaluation_cost"])
                   for scale in (1, 2, 3)]
        one = select(summary, method, 1)[0]
        changes_text = ", ".join(f"{change:.1f}\\%" for change in changes)
        comments.append(f"{LABELS[method]} cost reductions against current LQR are "
                        f"{changes_text} at 1x/2x/3x. "
                        f"Its 1x threshold is cycle {integer(one['sustained_cycle_below_001'])}.")
    content = "\\begin{itemize}\n" + "".join("\\item " + comment + "\n" for comment in comments) + "\\end{itemize}\n"
    (RESULTS / "interpretation.tex").write_text(content, encoding="utf-8")


def main():
    synthesis = json.loads((RESULTS / "synthesis.json").read_text(encoding="utf-8"))
    summary, history, timing, trajectories = [read_rows(name) for name in
        ("summary.csv", "history.csv", "timing.csv", "trajectories.csv")]
    saved = loadmat(RESULTS / "comparison.mat", simplify_cells=True)
    metadata = saved["metadata"]
    FIGURES.mkdir(exist_ok=True)
    plt.rcParams.update({"font.size": 11, "axes.labelsize": 12, "axes.titlesize": 12,
                         "legend.fontsize": 11, "xtick.labelsize": 11, "ytick.labelsize": 11,
                         "pdf.fonttype": 42, "savefig.bbox": "tight"})
    plot_speed(history, summary)
    plot_error_cost(history, summary)
    plot_conditioning(history)
    plot_physical(trajectories)
    plot_trajectory_comparison(trajectories, history, FIGURES, METHODS, style)
    plot_timing(timing)
    write_tables(synthesis, summary, timing)
    write_macros(synthesis, timing, metadata)
    write_convergence_notes(history, summary)
    write_interpretation(summary)
    print(f"Exported enlarged per-case figures and convergence-speed comparisons under {HERE}")


if __name__ == "__main__":
    main()
