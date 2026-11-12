"""Physical trajectory comparisons rendered only from saved dense and cycle states."""

from pathlib import Path

import matplotlib.pyplot as plt
from matplotlib.lines import Line2D
from matplotlib.ticker import MaxNLocator
import numpy as np

FIELDS = ("vc1_v", "vc2_v", "il_a")
LABELS = (r"$v_{C_1}$ (V)", r"$v_{C_2}$ (V)", r"$i_L$ (A)")
PERIOD_MS = 0.286
CYCLES = 12
REFERENCE = dict(color="0.3", linestyle="-", linewidth=1.7, label="Reference")


def _states(rows):
    states = np.array([[row[field] for field in FIELDS] for row in rows])
    if not len(states) or not np.isfinite(states).all():
        raise ValueError("Plotted physical states must be present and finite")
    return states


def _scenario(trajectories, history, methods, scale):
    """Keep each own-grid path and verify cycle markers against saved endpoints."""
    paths, starts = {}, {}
    for method in ("reference", *methods):
        rows = [row for row in trajectories
                if row["method"] == method and row["error_scale"] == scale]
        times = np.array([row["time_ms"] for row in rows])
        if not np.isfinite(times).all() or np.any(np.diff(times) < 0):
            raise ValueError("Dense sample times must be finite and ordered")
        stop = PERIOD_MS if method == "reference" else CYCLES * PERIOD_MS
        keep = (times >= 0) & (times <= stop + 1e-10)
        paths[method] = _states([row for row, valid in zip(rows, keep) if valid])
        if method == "reference":
            continue
        cycle_rows = sorted(
            [row for row in history if row["method"] == method
             and row["error_scale"] == scale and 0 <= row["cycle"] <= CYCLES],
            key=lambda row: row["cycle"])
        if [row["cycle"] for row in cycle_rows] != list(range(CYCLES + 1)):
            raise ValueError("Cycle-start markers require saved cycles 0 through 12")
        starts[method] = _states(cycle_rows)
        cycle_times = np.array([row["time_ms"] for row in cycle_rows])
        dense_times = times[keep]
        nearest = np.abs(dense_times[:, None] - cycle_times).argmin(axis=0)
        if (not np.isfinite(cycle_times).all()
                or not np.allclose(dense_times[nearest], cycle_times, rtol=0, atol=1e-10)
                or not np.allclose(paths[method][nearest], starts[method],
                                   rtol=0, atol=1e-8)):
            raise ValueError("Saved cycle starts disagree with dense trajectory samples")
    initial = starts[methods[0]][0]
    if any(not np.allclose(states[0], initial, rtol=0, atol=1e-10)
           for states in starts.values()):
        raise ValueError("Controllers must share the same initial state")
    combined = np.vstack(list(paths.values()) + list(starts.values()))
    low, high = combined.min(axis=0), combined.max(axis=0)
    padding = 0.06 * np.maximum(high - low, 0.1)
    bounds = np.column_stack((low - padding, high + padding))
    return paths, starts, initial, paths["reference"][0], bounds


def _markers(ax, initial, anchor, coordinates):
    ax.plot(*initial[list(coordinates)], marker="o", color="black", markersize=6,
            linestyle="none", zorder=8)
    ax.plot(*anchor[list(coordinates)], marker="*", color="black", markersize=10,
            linestyle="none", zorder=9)


def _legend(fig, methods, style, cycle_markers=False):
    handles = [Line2D([], [], **REFERENCE)]
    handles += [Line2D([], [], **dict(style(method), linewidth=2.0)) for method in methods]
    handles += [Line2D([], [], color="black", marker=marker, linestyle="none",
                       markersize=size, label=label)
                for marker, size, label in (("o", 6, "Initial state"),
                                            ("*", 10, "Cycle anchor"))]
    if cycle_markers:
        handles.append(Line2D([], [], color="0.35", marker="o", markerfacecolor="none",
                              markersize=4.5, linestyle="none", label=r"Cycle starts $k=0\ldots12$"))
    fig.legend(handles=handles, loc="upper center", ncol=2, frameon=False,
               fontsize=11, handlelength=2.5, columnspacing=1.5,
               handletextpad=0.6, labelspacing=0.4, bbox_to_anchor=(0.5, 0.96))


def _save(fig, output_dir, name):
    # Fix the page size even when the exporter sets savefig.bbox to tight.
    with plt.rc_context({"savefig.bbox": None}):
        fig.savefig(output_dir / f"{name}.pdf", metadata={"Creator": "plot_trajectories.py"})
        fig.savefig(output_dir / f"{name}.png", dpi=180)
    plt.close(fig)


def plot_trajectory_comparison(trajectories, history, output_dir, methods, style):
    """Write one state-space and one projection PDF/PNG pair per 1x/2x/3x case.

    Each full figure uses its own case's physical-coordinate bounds. The cycle-marker
    consistency checks provide a focused saved-data regression check whenever these
    figures are rendered. Unused history fields may contain NaN.
    """
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    scenarios = [_scenario(trajectories, history, methods, scale) for scale in (1, 2, 3)]
    with plt.rc_context({"font.size": 11, "axes.labelsize": 12, "axes.titlesize": 13,
                         "xtick.labelsize": 11, "ytick.labelsize": 11, "pdf.fonttype": 42}):
        for scale, (paths, starts, initial, anchor, bounds) in zip((1, 2, 3), scenarios):
            fig = plt.figure(figsize=(6.7, 7.1))
            fig.suptitle(f"{scale}x initial displacement", y=0.995, fontsize=13)
            ax = fig.add_subplot(1, 1, 1, projection="3d", computed_zorder=False)
            for method in methods:
                ax.plot(*paths[method].T, **dict(style(method), linewidth=2.0))
            ax.plot(*paths["reference"].T, **REFERENCE, zorder=6)
            _markers(ax, initial, anchor, (0, 1, 2))
            ax.view_init(elev=24, azim=-58)
            ax.set_box_aspect((1, 1, 0.9), zoom=1.08)
            for axis, label in zip((ax.xaxis, ax.yaxis, ax.zaxis), LABELS):
                axis.set_label_text(label if axis is not ax.zaxis else "")
                axis.labelpad = 10
                axis.set_major_locator(MaxNLocator(nbins=4, min_n_ticks=3))
                axis.set_pane_color((1, 1, 1, 1))
                axis._axinfo["grid"].update(color="0.88", linewidth=0.6)
            ax.text2D(0.99, 0.85, LABELS[2], transform=ax.transAxes,
                      ha="right", va="bottom", fontsize=12)
            ax.set(xlim=bounds[0], ylim=bounds[1], zlim=bounds[2])
            ax.tick_params(pad=3, labelsize=11)
            _legend(fig, methods, style)
            fig.subplots_adjust(left=0.0, right=0.98, bottom=0.08, top=0.84)
            _save(fig, output_dir, f"state_space_{scale}x")

            fig, axes = plt.subplots(3, 1, figsize=(6.7, 8.2))
            fig.suptitle(f"{scale}x initial displacement", y=0.995, fontsize=13)
            for ax, (x, y) in zip(axes, ((0, 1), (0, 2), (1, 2))):
                for method in methods:
                    ax.plot(paths[method][:, x], paths[method][:, y],
                            **dict(style(method), linewidth=2.0))
                    ax.plot(starts[method][:, x], starts[method][:, y], linestyle="none",
                            marker="o", markersize=4.5, markerfacecolor="none",
                            markeredgewidth=0.9, color=style(method)["color"], zorder=5)
                ax.plot(paths["reference"][:, x], paths["reference"][:, y],
                        **REFERENCE, zorder=6)
                _markers(ax, initial, anchor, (x, y))
                ax.set(xlim=bounds[x], ylim=bounds[y], xlabel=LABELS[x], ylabel=LABELS[y])
                ax.xaxis.set_major_locator(MaxNLocator(nbins=5, min_n_ticks=3))
                ax.yaxis.set_major_locator(MaxNLocator(nbins=4, min_n_ticks=3))
                ax.tick_params(length=3.5, pad=3)
                ax.grid(True, color="0.88", linewidth=0.6)
                ax.spines[["top", "right"]].set_visible(False)
            _legend(fig, methods, style, cycle_markers=True)
            fig.subplots_adjust(left=0.13, right=0.98, bottom=0.075, top=0.79,
                                hspace=0.58)
            _save(fig, output_dir, f"trajectory_projections_{scale}x")
