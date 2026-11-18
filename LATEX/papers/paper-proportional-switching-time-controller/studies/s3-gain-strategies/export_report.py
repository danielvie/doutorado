"""Build the comparison report from saved, independently validated evidence only."""

import hashlib
import json
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import numpy as np

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
RESULTS = HERE / "results"
FIGURES = HERE / "figures"
STRATEGIES = tuple(f"strategy-{i}" for i in range(1, 6))
CERTIFIED_METHODS = ("current-lqr", "saved-common-p", *STRATEGIES)
MARCOLINO = "strategy-marcolino"
COMPARISON_METHODS = (*CERTIFIED_METHODS, MARCOLINO)
COLORS = {"current-lqr": "#333333", "saved-common-p": "#7570b3", "strategy-1": "#1b9e77",
          "strategy-2": "#d95f02", "strategy-3": "#e7298a", "strategy-4": "#1f78b4",
          "strategy-5": "#a6761d", MARCOLINO: "#0097a7", "MPC-5": "#666666"}
LABELS = {"current-lqr": "Current LQR", "saved-common-p": "Saved common-P",
          MARCOLINO: "Marcolino"}
DESCRIPTIONS = {
    "strategy-1": "LQR weights are tuned, with a separate common-P check for every candidate.",
    "strategy-2": "The gain and a full-feedback quadratic cost bound are synthesized together. The shared certificate also covers the open endpoint. The cost bound itself does not cover conditioned nonlinear operation.",
    "strategy-3": "Separate contraction targets are imposed at the two endpoints. The objective penalizes timing effort and margin-normalized dwell demand instead of minimizing the common worst-case rate.",
    "strategy-4": "Timing corrections are redistributed with K=K0+NZ and BN=0. The original linearized matrix family and common-P certificate are preserved, while the actual conditioning factors can change.",
    "strategy-5": "All gain entries are tuned against the exact conditioned response, subject to the current fixed-P endpoint decrease requirements."}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def label(name):
    return LABELS.get(name, name)


def tex(text):
    replacements = {"\\": r"\textbackslash{}", "&": r"\&", "%": r"\%", "$": r"\$",
                    "#": r"\#", "_": r"\_", "{": r"\{", "}": r"\}"}
    return "".join(replacements.get(char, char) for char in str(text))


def table(headers, rows, compact=True):
    md = "| " + " | ".join(headers) + " |\n|" + "|".join("---" for _ in headers) + "|\n"
    md += "".join("| " + " | ".join(map(str, row)) + " |\n" for row in rows)
    latex = r"\begin{center}" + (r"\small" if compact else "")
    latex += r"\begin{tabular}{l" + "r" * (len(headers) - 1) + "}\n\\toprule\n"
    latex += " & ".join(map(tex, headers)) + r" \\" + "\n\\midrule\n"
    latex += "".join(" & ".join(map(tex, row)) + r" \\" + "\n" for row in rows)
    latex += "\\bottomrule\n\\end{tabular}\\end{center}\n"
    return md, latex


def figure(name, fig):
    fig.savefig(FIGURES / f"{name}.pdf", bbox_inches="tight")
    fig.savefig(FIGURES / f"{name}.png", dpi=180, bbox_inches="tight")
    plt.close(fig)


def require_comparison_contract(data):
    if tuple(item["name"] for item in data["methods"]) != COMPARISON_METHODS:
        raise ValueError("Eight-method comparison pending: regenerate and independently validate the Marcolino comparison")
    fields = {"clocked_times", "clocked_errors", "clocked_error_sum", "clocked_error_ratio_lqr",
              "clocked_sustained_time_ms", "anchor_sustained_time_ms", "cycle_times",
              "final_reference_error", "extended_cycles", "maximum_cycle_duration_us"}
    summary_fields = {"mean_clocked_error_ratio_lqr", "worst_clocked_error_ratio_lqr",
                      "mean_clocked_sustained_time_ms", "worst_clocked_sustained_time_ms",
                      "clocked_unsettled_cases"}
    if (any(not fields.issubset(response) for response in data["responses"]) or
            any(not summary_fields.issubset(summary) for summary in data["summaries"])):
        raise ValueError("Common-clock timing evidence pending: regenerate and independently validate the comparison")


def number(value, digits=3):
    return "--" if value is None else f"{value:.{digits}f}"


def comparison_sections(data, summaries, responses):
    """Keep variable-period tracking evidence separate from certified gain rankings."""
    horizon_ms = 1000 * responses["current-lqr", "article-1x"]["clocked_times"][-1]
    protocol = (
        "Marcolino uses the unchanged current LQR gain with sequential boundary delays and a 3 us minimum dwell. "
        "The next cycle starts at the realized terminal boundary, so its period can grow. "
        "There is no scalar beta, gain optimization or common-P certificate for this policy. "
        "The seven certified methods retain the fixed nominal period. "
        f"All eight are compared at the same 101 physical times j*T through {horizon_ms:.3f} ms. "
        "States at these times come from exact partial propagation, not interpolation. "
        "The tracking sum adds squared normalized errors at j=0,...,99 against the original periodic reference. "
        "It charges no input effort and is neither J100 nor a physical energy measure. It is a sampled comparison, not a continuous-time tracking bound. "
        "Ratios use current LQR in the same case. Fixed-clock threshold time is the first common-grid time "
        "after which error stays below 0.01 for the rest of the saved grid. A dash means no sustained crossing; "
        "a mean or maximum threshold time is then also unavailable.")
    marcolino = summaries[MARCOLINO, "withheld"]
    historical_misses = sum(responses[MARCOLINO, f"article-{scale}x"]["clocked_sustained_time_ms"] is None
                            for scale in (1, 2, 3))
    comparison_outcome = (
        f"Marcolino's mean withheld tracking-sum ratio is {marcolino['mean_clocked_error_ratio_lqr']:.4f}. "
        f"It has no sustained fixed-clock threshold crossing in {marcolino['clocked_unsettled_cases']} of 12 withheld cases "
        f"and {historical_misses} of the three historical cases. "
        "A smaller tracking sum and a sustained threshold crossing are different performance measures. "
        "Neither changes the fixed-period certified gain ranking.")
    clock_rows = []
    duration_rows = []
    for name in COMPARISON_METHODS:
        summary = summaries[name, "withheld"]
        clock_rows.append([label(name), number(summary["mean_clocked_error_ratio_lqr"], 4),
                           number(summary["worst_clocked_error_ratio_lqr"], 4),
                           number(summary["mean_clocked_sustained_time_ms"]),
                           number(summary["worst_clocked_sustained_time_ms"]),
                           str(summary["clocked_unsettled_cases"])])
        rs = [r for r in data["responses"] if r["method"] == name]
        duration_rows.append([label(name), number(max(r["cycle_times"][-1] for r in rs) * 1000),
                              number(max(r["maximum_cycle_duration_us"] for r in rs)),
                              str(sum(r["extended_cycles"] for r in rs)),
                              f"{max(r['final_reference_error'] for r in rs):.3g}"])
    clock_md, clock_tex = table(["Method", "Mean ratio", "Worst ratio", "Mean ms", "Max ms", "Misses"],
                                clock_rows, compact=False)
    duration_md, duration_tex = table(["Method", "Max ms", "Max cycle us", "Extended", "Max phase err"],
                                      duration_rows, compact=False)
    phase_note = (
        "The following duration and phase statistics cover all 20 cases per method. Max ms is the elapsed time "
        "of 100 actual cycles; Max cycle us is the longest realized cycle. Extended counts extended cycles "
        "across all 2,000 cycles per method. Max phase err is the largest final error against the original "
        "periodic reference evaluated at each method's actual final boundary. "
        "Anchor error instead compares a cycle-start state with the nominal anchor regardless of elapsed phase. "
        "A delayed policy can approach that anchor while remaining out of phase with the reference. "
        "Anchor threshold times therefore do not establish faster fixed-clock tracking.")
    mar3 = responses[MARCOLINO, "article-3x"]
    phase_note += (f" In the 3x case, Marcolino's final actual-boundary reference error is {mar3['final_reference_error']:.5f}, "
                   f"but its error at the shared nominal final time is {mar3['final_clocked_error']:.5f}. "
                   "The sample phases differ, which explains the different threshold outcomes.")
    plot_note = ("Historical 1x, 2x and 3x errors below use the common clock and the original periodic reference. "
                 "The horizontal axis is physical elapsed time, not each policy's cycle count. "
                 "MPC-5 is omitted because its imported record has no validated common-clock samples.")
    md = ("## Eight-method common-clock comparison\n\n" + protocol + "\n\n" + comparison_outcome +
          "\n\n### Twelve withheld cases\n\nMean and worst ratios refer to the tracking-only sum. "
          "Mean ms and Max ms refer to sustained fixed-clock threshold time; Misses counts cases without a crossing.\n\n" +
          clock_md + "\n![Historical common-clock tracking errors](figures/historical_clocked_errors.png)\n\n" +
          plot_note + "\n\n### Policy duration and reference phase\n\n" + phase_note + "\n\n" + duration_md)
    latex = ("\\section*{Eight-method common-clock comparison}\n" + tex(protocol) + "\n\n" + tex(comparison_outcome) +
             "\n\\subsection*{Twelve withheld cases}\n" +
             tex("Mean and worst ratios refer to the tracking-only sum. Mean ms and Max ms refer to sustained "
                 "fixed-clock threshold time; Misses counts cases without a crossing.") + "\n" + clock_tex +
             "\\clearpage\\section*{Historical common-clock tracking}\n" + tex(plot_note) +
             "\n\\begin{center}\\includegraphics[width=\\linewidth]{figures/historical_clocked_errors.pdf}\\end{center}\n" +
             "\\clearpage\\section*{Policy duration and reference phase}\n" + tex(phase_note) + "\n" + duration_tex)
    historical_note = (
        "These matched historical cases show the tracking sum and its LQR ratio, fixed-clock threshold time "
        "in ms, actual anchor threshold cycle / elapsed ms, and final phase-sensitive error at the actual "
        "100th-cycle boundary. Ext counts extended cycles in each trajectory. "
        "All crossings are sustained only over their saved sampling horizons. "
        "The 1x case was in training; 2x and 3x were stress tests, not optimization inputs.")
    md += "\n### Matched historical tracking and thresholds\n\n" + historical_note + "\n\n"
    latex += "\n\\clearpage\\section*{Matched historical tracking and thresholds}\n" + tex(historical_note) + "\n"
    for scale in (1, 2, 3):
        rows = []
        for name in COMPARISON_METHODS:
            r = responses[name, f"article-{scale}x"]
            anchor = "--" if r["sustained_cycle"] is None else f"{r['sustained_cycle']} / {number(r['anchor_sustained_time_ms'])}"
            rows.append([label(name), f"{r['clocked_error_sum']:.4f}", number(r["clocked_error_ratio_lqr"], 4),
                         number(r["clocked_sustained_time_ms"]), anchor, f"{r['final_reference_error']:.3g}",
                         str(r["extended_cycles"])])
        history_md, history_tex = table(["Method", "Sum", "Ratio", "Fixed ms", "Anchor n/ms", "Phase err", "Ext"],
                                        rows, compact=False)
        md += f"#### Historical {scale}x\n\n" + history_md + "\n"
        latex += f"\\subsubsection*{{Historical {scale}x}}\n" + history_tex
    anchor_note = (
        "Each cell below is anchor-sampled J100 / actual elapsed ms for 100 cycles. "
        "J100 includes the original weighted applied timing term. Marcolino's anchor J100 spans a different "
        "elapsed time and samples a different reference phase, so it is not a fair common-clock tracking cost. "
        "These values do not enter the certified optimization rankings or the fixed-period best-strategy conclusion.")
    rows = []
    for name in COMPARISON_METHODS:
        cells = [label(name)]
        for scale in (1, 2, 3):
            r = responses[name, f"article-{scale}x"]
            cells.append(f"{r['cost']:.4f} / {1000 * r['cycle_times'][-1]:.3f}")
        rows.append(cells)
    anchor_md, anchor_tex = table(["Method", "1x J100 / ms", "2x J100 / ms", "3x J100 / ms"], rows, compact=False)
    md += "\n### Anchor-sampled objective over different elapsed times\n\n" + anchor_note + "\n\n" + anchor_md
    latex += ("\n\\clearpage\\section*{Anchor-sampled objective over different elapsed times}\n" +
              tex(anchor_note) + "\n" + anchor_tex)
    return md, latex


def main():
    data = json.loads((RESULTS / "comparison.json").read_text())
    validation = json.loads((RESULTS / "validation.json").read_text())
    if validation["status"] != "passed":
        raise ValueError("Independent validation has not passed")
    current_digest = digest(RESULTS / "comparison.json")
    if (validation.get("comparison_sha256") != current_digest and
            current_digest not in validation.get("source_sha256", {}).values()):
        raise ValueError("Validation does not identify the current comparison")
    for relative, expected in data["source_sha256"].items():
        if digest(ROOT / relative) != expected:
            raise ValueError(f"Stale report input: {relative}")
    require_comparison_contract(data)
    FIGURES.mkdir(exist_ok=True)
    methods = CERTIFIED_METHODS
    method_data = {item["name"]: item for item in data["methods"]}
    responses = {(r["method"], r["case"]): r for r in data["responses"]}
    summaries = {(s["method"], s["split"]): s for s in data["summaries"]}
    strategy_results = {name: json.loads((RESULTS / f"{name}.json").read_text())
                        for name in STRATEGIES}
    plt.rcParams.update({"font.size": 9, "axes.labelsize": 9, "axes.titlesize": 10,
                         "legend.fontsize": 8, "xtick.labelsize": 8, "ytick.labelsize": 8,
                         "pdf.fonttype": 42, "savefig.facecolor": "white"})
    width = 160 / 25.4
    x = np.arange(len(methods))
    fig, axes = plt.subplots(2, 1, figsize=(width, 5.1), sharex=True, layout="constrained")
    for ax, split in zip(axes, ("training", "withheld")):
        avg = [summaries[name, split]["mean_cost_ratio_lqr"] for name in methods]
        worst = [summaries[name, split]["worst_cost_ratio_lqr"] for name in methods]
        ax.bar(x, avg, color=[COLORS[n] for n in methods], alpha=.85, label="Mean cost ratio")
        ax.plot(x, worst, "ko", ms=4, label="Worst case ratio")
        ax.axhline(1, color="black", linewidth=.8, linestyle="--")
        ax.set_ylabel("Cost / current LQR")
        ax.set_title(f"{split.capitalize()} cases")
        ax.grid(axis="y", alpha=.2)
        ax.set_axisbelow(True)
    axes[0].legend(ncol=2)
    axes[-1].set_xticks(x, [label(n) for n in methods], rotation=25, ha="right")
    figure("cost_ratios", fig)

    fig, axes = plt.subplots(3, 1, figsize=(width, 7), sharex=True, layout="constrained")
    for ax, case in zip(axes, ("article-1x", "article-2x", "article-3x")):
        for name in methods:
            r = responses[name, case]
            ax.semilogy(np.arange(21), np.asarray(r["errors"])[:21], color=COLORS[name],
                        label=label(name), linewidth=1.3)
        mpc = next(r for r in data["historical_mpc"] if r["case"] == case)
        ax.semilogy(np.arange(21), np.asarray(mpc["errors"])[:21], "k--", label="MPC-5", lw=1.3)
        ax.axhline(.01, color="gray", linestyle=":", linewidth=.8)
        ax.set_title(case.replace("article-", "Historical ") + " initial error")
        ax.set_ylabel("Normalized error")
        ax.set_ylim(1e-7, 5)
        ax.grid(alpha=.2)
    axes[0].legend(ncol=3, loc="lower left")
    axes[-1].set_xlabel("Completed cycles")
    figure("historical_errors", fig)

    fig, axes = plt.subplots(3, 1, figsize=(width, 7.4), sharex=True, layout="constrained")
    for ax, case in zip(axes, ("article-1x", "article-2x", "article-3x")):
        for name in COMPARISON_METHODS:
            r = responses[name, case]
            ax.semilogy(1000 * np.asarray(r["clocked_times"]), r["clocked_errors"],
                        color=COLORS[name], label=label(name), linewidth=1.3,
                        linestyle="--" if name == MARCOLINO else "-")
        ax.axhline(.01, color="gray", linestyle=":", linewidth=.8)
        ax.set_title(case.replace("article-", "Historical ") + " initial error")
        ax.set_ylabel("Normalized tracking error")
        ax.set_ylim(1e-12, 5)
        ax.grid(alpha=.2)
    axes[0].legend(ncol=3, loc="upper right")
    axes[-1].set_xlabel("Physical elapsed time [ms], common grid jT")
    figure("historical_clocked_errors", fig)

    withheld = [c["name"] for c in data["cases"] if c["split"] == "withheld"]
    ratios = np.array([[responses[n, c]["cost_ratio_lqr"] for c in withheld] for n in methods])
    fig, ax = plt.subplots(figsize=(width, 3.5), layout="constrained")
    bound = max(.05, float(np.max(abs(ratios - 1))))
    image = ax.imshow(ratios, cmap="RdBu_r", vmin=1-bound, vmax=1+bound, aspect="auto")
    ax.set_yticks(np.arange(len(methods)), [label(n) for n in methods])
    ax.set_xticks(np.arange(len(withheld)), [str(i+1) for i in range(len(withheld))])
    ax.set_xlabel("Withheld case")
    for i in range(len(methods)):
        for j in range(len(withheld)):
            ax.text(j, i, f"{ratios[i,j]:.2f}", ha="center", va="center", fontsize=7)
    fig.colorbar(image, ax=ax, label="Cost / current LQR")
    figure("withheld_costs", fig)

    fig, axes = plt.subplots(2, 1, figsize=(width, 4.4), sharex=True, layout="constrained")
    for ax, case in zip(axes, ("article-1x", "article-3x")):
        for name in methods:
            ax.step(np.arange(16), np.asarray(responses[name, case]["beta"])[:16], where="post",
                    color=COLORS[name], label=label(name), lw=1.3)
        ax.set_title(case.replace("article-", "Historical ") + " initial error")
        ax.set_ylabel("Applied fraction")
        ax.set_ylim(0, 1.05)
        ax.grid(alpha=.2)
    axes[0].legend(ncol=3, loc="lower right")
    axes[-1].set_xlabel("Cycle")
    figure("conditioning", fig)

    winner = min(strategy_results, key=lambda n: summaries[n, "withheld"]["mean_cost_ratio_lqr"])
    win = summaries[winner, "withheld"]
    baseline_common = summaries["saved-common-p", "withheld"]["mean_cost_ratio_lqr"]
    reduction = 100 * (1 - win["mean_cost_ratio_lqr"])
    conclusion = (f"{winner} has the lowest mean withheld cost among the five strategies. "
                  f"Its mean cost is {reduction:.2f}% lower than current LQR. "
                  f"It has {win['cost_regressions']} of 12 withheld cases with higher cost than LQR, "
                  f"and its worst case costs {win['worst_cost_ratio_lqr']:.3f} times LQR. "
                  f"The saved Common-P gain has mean withheld cost ratio {baseline_common:.3f}.")
    if reduction <= 0:
        conclusion += " This experiment does not justify replacing current LQR."
    elif win["cost_regressions"]:
        conclusion += " The mean improvement is a tradeoff, not uniform dominance."
    else:
        conclusion += " It is the strongest follow-up candidate in this finite test set, not a validated hardware controller."

    fast = min(strategy_results, key=lambda n: summaries[n, "withheld"]["mean_sustained_cycle"])
    fast_summary = summaries[fast, "withheld"]
    reference_cycles = summaries["current-lqr", "withheld"]["mean_sustained_cycle"]
    conclusion += (f" {fast} reaches the threshold in {fast_summary['mean_sustained_cycle']:.2f} cycles on average, "
                   f"versus {reference_cycles:.2f} for LQR, but its mean withheld cost ratio is "
                   f"{fast_summary['mean_cost_ratio_lqr']:.3f}.")
    recommendation = ("Keep current LQR as the general-purpose baseline for now. "
                      "Strategy-5's withheld cost improvement is small and includes regressions. "
                      "Strategy-4 is the more useful follow-up when faster settling or the original large-error direction is the priority, "
                      "but its larger cost in other directions must be accepted explicitly. "
                      "The certified fixed-period experiment does not establish a gain that dominates LQR across all tested performance measures.")
    rows = []
    for name in methods:
        a, b = summaries[name, "training"], summaries[name, "withheld"]
        rows.append([label(name), f"{a['mean_cost_ratio_lqr']:.4f}", f"{b['mean_cost_ratio_lqr']:.4f}",
                     f"{b['worst_cost_ratio_lqr']:.4f}", str(b["cost_regressions"]),
                     f"{b['mean_sustained_cycle']:.2f}", str(b["worst_sustained_cycle"])])
    aggregate_md, aggregate_tex = table(["Method", "Train J", "Test J", "Worst J", "Worse cases", "Mean cycles", "Max cycles"], rows)
    component_rows = []
    for name in methods:
        rs = [responses[name, case] for case in withheld]
        denominators = np.array([responses['current-lqr', case]['cost'] for case in withheld])
        state_costs = np.array([np.sum(np.asarray(r['errors'])[:-1] ** 2) for r in rs])
        total = np.array([r['cost'] for r in rs])
        component_rows.append([label(name), f"{np.mean(state_costs / denominators):.4f}",
                               f"{np.mean((total-state_costs) / denominators):.4f}",
                               f"{np.mean(total / denominators):.4f}"])
    component_md, component_tex = table(["Method", "Error part", "Timing part", "Total"], component_rows)
    historical_rows = []
    for name in methods:
        cells = [label(name)]
        for scale in (1, 2, 3):
            r = responses[name, f"article-{scale}x"]
            cells.append(f"{r['cost']:.4f} / {r['sustained_cycle']}")
        historical_rows.append(cells)
    historical_rows.append(["MPC-5"] + [f"{r['cost']:.4f} / {r['sustained_cycle']}"
                           for r in data["historical_mpc"]])
    historical_md, historical_tex = table(["Method", "1x cost / cycles", "2x cost / cycles", "3x cost / cycles"], historical_rows)
    cert_rows = []
    for name in methods:
        item = method_data[name]
        c = item["certificate"]
        cert_rows.append([label(name), f"{np.linalg.norm(item['K']):.2f}", f"{c['min_eigenvalue_P']:.3g}",
                          f"{c['endpoint_decreases'][0]:.3g}", f"{c['endpoint_decreases'][1]:.3g}",
                          f"{item['elapsed_seconds']:.2f}" if "elapsed_seconds" in item else "saved"])
    cert_md, cert_tex = table(["Method", "Gain norm", "min eig P", "Open margin", "Feedback margin", "Offline s"], cert_rows)
    details_md, details_tex = [], []
    for name, result in strategy_results.items():
        params = result.get("parameters", {})
        scalar_params = {k: v for k, v in params.items() if isinstance(v, (str, float, int, bool)) or v is None}
        selected = json.dumps(scalar_params, sort_keys=True) if scalar_params else "See full-precision result JSON."
        if name == 'strategy-1':
            selected = f"Selected (a,b,c)={params['selected_setting']}."
        elif name == 'strategy-2':
            selected = (f"Selected {result['selected_candidate']}. Best synthesized training ratio "
                        f"{result['best_synthesized_training_score']['mean_ratio']:.6f}; "
                        "the synthesized gain was not adopted. Optional Clarabel chordal decomposition was disabled "
                        "after nine development solves hit a pinned-dependency API error. No package versions changed.")
        elif name == 'strategy-3':
            selected = json.dumps({k: result['selected_synthesis']['variables'][k] for k in ('r0', 'r1', 'lambda')})
        elif name == 'strategy-4':
            selected = f"200 objective evaluations; 15 redistribution parameters; final step {result['final_step']}."
        elif name == 'strategy-5':
            selected = f"200 objective evaluations; fixed-P margin threshold {params['margin_threshold']:.6g}."
        counts = result.get('counts', result)
        evaluations = counts.get('objective_evaluations', 'not recorded')
        solves = counts.get('solver_calls', 'not recorded')
        rejects = counts.get('rejected_settings', counts.get('rejection_count', counts.get('certificate_rejections', 0)))
        final = (f"Training cost ratio {result['training_score']['mean_ratio']:.6f}; "
                 f"{evaluations} objective evaluations, {solves} solver calls, {rejects} numerical or feasibility rejections. "
                 f"Status: {result.get('status', 'see record').replace('_', ' ')}. "
                 f"Termination: {result.get('termination_reason', 'see record').replace('_', ' ').rstrip('.')}.")
        detail = DESCRIPTIONS[name] + " " + final
        details_md.append(f"### {name}\n\n{detail}\n\n{selected}\n\nFull record: [results/{name}.json](results/{name}.json).\n")
        details_tex.append("\\subsection*{" + tex(name) + "}\n" + tex(detail) + "\n\n" + tex(selected) + "\n")

    methodology = ("Six predeclared training cases selected each strategy's gain. Twelve different cases were withheld from optimization. "
                   "The historical 2x and 3x cases are separate stress tests and start with negative current. "
                   "The seven certified fixed-period methods use the same 100-cycle cost, with Q=I and applied timing weight 0.001. "
                   "They use constant gains and the same scalar dwell conditioner. "
                   "Marcolino is a separate variable-period conditioning reference with unchanged current LQR gain, no scalar beta and no gain optimization. "
                   "The five optimization records and gains remain frozen. "
                   "Optimization and exact-plant evaluation ran in Julia; Python independently checked the saved evidence. "
                   "The five strategy runs were parallel, so their elapsed times include compilation and resource contention and are not controlled algorithm benchmarks.")
    checked_cycles = validation['completed_exact_cycles']
    state_discrepancy = validation['maximum_absolute_errors']['exact one-cycle state']
    verification_outcome = (f"Independent Python checks passed for all {checked_cycles:,} saved exact cycles. "
                            f"The maximum absolute one-cycle state discrepancy was {state_discrepancy:.3g}. "
                            "The checks also cover source hashes, certificates, gain recovery, costs, thresholds and dwell arithmetic. ")
    limits = (verification_outcome + "The seven fixed-period methods pass full-precision common-P endpoint checks. "
              "Marcolino is not covered by that certificate; reusing the LQR gain does not transfer the guarantee to its variable-period policy. "
              "The qualitative stability guarantee is retained, but numerical decrease margins differ between gains. "
              "The endpoint theorem gives stability of the conditioned linearized family for arbitrary conditioning-factor sequences. "
              "These are floating-point checks, not interval proofs. Exact nonlinear trajectories remain simulations, not a global stability or attraction-region certificate. "
              "No physical state constraints, uncertainty, quantization, delay or hardware implementation are included. "
              "State minima use cycle-start samples only and are not continuous-time extrema. "
              "The searches have finite predeclared budgets and local searches can stop far from a global optimum. "
              "MPC-5 is imported only for its three identical historical cases; no new MPC solves or matched Julia/MATLAB timing comparison were performed.")
    comparison_md, comparison_tex = comparison_sections(data, summaries, responses)
    certificate_note = ("Marcolino is a separate variable-period reference and is not covered by common-P. "
                        "Its P, certificate and beta are absent; it is excluded from the endpoint table and scalar-beta plot. "
                        "Its gain is unchanged current LQR, not a sixth gain optimization.")
    md = ("# Five certified gain strategies and Marcolino reference\n\n" + conclusion +
          "\n\nThe best-strategy conclusion uses only the five certified, fixed-period gain optimizations. "
          "Marcolino is compared separately on the common physical clock below.\n\n## Comparison protocol\n\n" + methodology +
          "\n\n" + comparison_md + "\n\n## Certified fixed-period training and withheld performance\n\nAll cost ratios use current LQR as 1. Smaller is better. Regressions count withheld cases above LQR. Max cycles is the worst sustained threshold crossing.\n\n" +
          aggregate_md + "\n![Cost ratios](figures/cost_ratios.png)\n\n![Individual withheld costs](figures/withheld_costs.png)\n\n" +
          "### Why faster settling can cost more\n\nThe following withheld averages split J100 into tracking error and weighted applied timing effort. Each part is divided by the same current-LQR total cost, so the columns add to the mean cost ratio.\n\n" + component_md + "\n" +
          "## Matched historical cases\n\nEach cell gives J100 / sustained threshold cycle. The 1x case was in training; 2x and 3x were not.\n\n" + historical_md +
          "\n![Historical error histories](figures/historical_errors.png)\n\n## Strategies and selected settings\n\n" + "\n".join(details_md) +
          "\n## Certificates and offline work\n\nP is normalized to trace 3. Both endpoint margins must be positive. Offline times are observed parallel-run wall times.\n\n" + cert_md +
          "\n" + certificate_note + "\n\n![Conditioning for the seven certified fixed-period methods](figures/conditioning.png)\n\n## Recommendation\n\n" + recommendation + "\n\n## Validation and limits\n\n" + limits +
          "\n\nIndependent check record: [results/validation.json](results/validation.json). Full trajectories: [results/comparison.json](results/comparison.json). "
          "Per-case metrics: [results/metrics.csv](results/metrics.csv). Reproduction commands and source scope: [README.md](README.md).\n")
    (HERE / "report.md").write_text(md, encoding="utf-8")
    document = r"""\documentclass[11pt,a4paper]{article}
\usepackage[margin=20mm]{geometry}
\usepackage[T1]{fontenc}
\usepackage{lmodern,booktabs,graphicx,amsmath,microtype}
\usepackage[hidelinks]{hyperref}
\setlength{\parindent}{0pt}
\setlength{\parskip}{5pt}
\begin{document}
\begin{center}{\Large Five certified gain strategies\\and Marcolino reference}\end{center}
"""
    document += tex(conclusion) + "\n\n" + tex(recommendation)
    document += "\n\n" + tex("The best-strategy conclusion uses only the five certified, fixed-period gain optimizations. "
                               "Marcolino is compared separately on the common physical clock in the next section.")
    document += "\n\\section*{Comparison protocol}\n" + tex(methodology)
    document += "\n\\clearpage" + comparison_tex
    document += "\n\\clearpage\\section*{Certified fixed-period training and withheld performance}\nCost ratios use current LQR as 1. Regressions count withheld cases above LQR. Max cycles is the worst sustained threshold crossing.\n" + aggregate_tex
    document += "\\begin{center}\\includegraphics[width=\\linewidth]{figures/cost_ratios.pdf}\\end{center}\n"
    document += "\\clearpage\\section*{Individual withheld cases}\n\\begin{center}\\includegraphics[width=\\linewidth]{figures/withheld_costs.pdf}\\end{center}\n"
    document += tex("Starting-state definitions are fixed in SPEC.md and stored in comparison.json. Positive initial states do not establish a validated operating envelope.")
    document += "\n\\section*{Tracking error and timing effort}\nWithheld averages, divided by the same current-LQR total cost. The columns add to the mean cost ratio.\n" + component_tex
    document += "\n\\section*{Matched historical cases}\nEach cell gives J100 / sustained threshold cycle. The 1x case was in training; 2x and 3x were not.\n" + historical_tex
    document += "\\clearpage\\section*{Historical error histories}\n\\begin{center}\\includegraphics[width=\\linewidth]{figures/historical_errors.pdf}\\end{center}\n"
    document += "\\clearpage\\section*{Strategies and selected settings}\n" + "\n".join(details_tex)
    document += "\n\\clearpage\\section*{Certificates and offline work}\nP is normalized to trace 3. Both endpoint margins must be positive.\n" + cert_tex
    document += tex(certificate_note) + "\n"
    document += "\\section*{Fixed-period scalar conditioning}\n\\begin{center}\\includegraphics[width=\\linewidth]{figures/conditioning.pdf}\\end{center}\n"
    document += "\\clearpage\\section*{Validation and limits}\n" + tex(limits)
    document += "\n\nFull-precision gains, certificates, candidate logs, metrics and validation are saved under \\texttt{results/}. Reproduction commands are in \\texttt{README.md}.\n\\end{document}\n"
    (HERE / "report.tex").write_text(document, encoding="utf-8")
    (RESULTS / "report_inputs.json").write_text(json.dumps({"source_sha256": {
        str(path.relative_to(HERE)).replace("\\", "/"): digest(path)
        for path in (RESULTS / "comparison.json", RESULTS / "validation.json", Path(__file__).resolve())}}, indent=2) + "\n")
    print(f"Report exported; best mean withheld strategy: {winner}, cost ratio {win['mean_cost_ratio_lqr']:.6f}")


if __name__ == "__main__":
    main()
