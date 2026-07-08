# Handoff — Sampling vs. switching instants: deterministic sampling next step

**Date:** 2026-07-07
**Repo root:** `C:\Users\daniel\Documents\DOUTORADO\embedded\esp32_idf`
**Branch:** `main` · **Remote:** `origin https://github.com/danielvie/doutorado`
**Board:** ESP32 on COM3, flashed with the current committed tree.

## One-line status

The analog reading pipeline is now fast, fresh, and deterministic (control-latency
`pass: true`). The next body of work is a **measurement-quality** problem, not a latency one:
readings taken near a converter switching edge are corrupted by transients. A study has
already decided the approach — **deterministic sampling (place the read at a fixed, quiet
phase)** — and this handoff carries that plan forward.

## Read these first (do not re-derive)

- **The study that sets the goal:** `docs/adc_sampling_vs_switching.html` (Mado). Sources
  under `.mado-html/work/adc-sampling/`. Read it before touching code.
- Supporting context: `docs/control_latency_inline_drain.html` (the Core-1 inline-drain
  architecture this builds on) and `docs/reading_pipeline_optimization.html` (stage probes +
  optimizations; the probe harness is reused here).
- Landed work is commit `401195c` ("Read ADC inline on Core 1 and optimize the reading
  pipeline"). Inspect with `git show 401195c --stat`.

## The problem (why this matters)

The DMA engine switches the converter GPIOs while the ADC free-runs. A conversion landing in
the ~few-µs disturbance window after a switching edge measures ringing/bounce, not the plant.
Worse than random: the ADC cadence (12 µs/triple) is near-commensurate with the 60 µs
switching cycle, so the sampling phase **walks slowly** and dwells inside a bad phase for
many consecutive cycles → bursts of corrupted readings, not isolated ones.

## The verdict already reached (the projected goal)

Two scenarios were analysed in the study. **Conclusions are final; do not re-litigate:**

- **Scenario A — validate-and-reject (measure each sample's distance to nearest edge):
  NOT reachable.** Read-time stamping gives ±~24 µs uncertainty on a 60 µs cycle with a
  ~5 µs guard requirement → the guard test is undecidable. Restoring honest per-frame
  timestamps means killing `flush_pool`, which reintroduces the staleness problem the
  inline-drain work solved. Circular.
- **Scenario B — deterministic placement: REACHABLE, and recommended.** Every primitive
  already exists in firmware:
  1. The DMA trigger ISR already captures `s_trigger_cycles = esp_cpu_get_cycle_count()` at a
     fixed waveform position (`signal_engine_dma.cpp`, ISR ~L481) → sub-µs phase anchor.
  2. `wait_until_cycle()` busy-wait primitive exists (`signal_controller.cpp` ~L570).
  3. `adc_oneshot_read_isr()` gives lock-free conversions at the target instant.
  Expected placement jitter **~±1–2 µs vs a 5 µs guard.** Bonus: B makes A's validity check
  finally decidable (re-read the cycle counter after the conversion train; invalidate if an
  ISR preempted it into a guard band).

**The counter-intuitive headline: the ideal scenario (B) is the feasible one; the fallback
(A) is the one physics rules out.**

## Hard prerequisites before any implementation

1. **Fix the sense inputs.** AN3/AN5/AN6 still read `raw 0 → 0.1000` (`raw_zero: true`).
   Until real voltages arrive, *no disturbance is observable* and this whole task is timing
   plumbing with nothing to measure. Debug channel mapping / attenuation / wiring /
   energisation. This is the true blocker.
2. **Measure the real guard band.** Scope the AN inputs around switching edges on the actual
   converter; replace the study's assumed 5 µs settling time with the measured value. Every
   downstream design number depends on it.

## Projected plan (from the study's "phased plan" — see doc for detail)

1. Sense inputs (prereq 1) → 2. Measure guard band (prereq 2) →
3. **Instrument phase first (cheap, do before changing behavior):** record
   `(read_cycles − s_trigger_cycles)` per consumed triple, expose min/max/histogram over the
   UART agent — captures today's free-running phase distribution as "before" evidence. →
4. **Implement Scenario B:** oneshot owned by Core 1 while the DMA engine runs (reuse the
   existing reader-token hand-off from the inline drain), sample at a dataset-derived offset
   (midpoint of the longest quiet step, auto-computed at render time), overrun self-check
   invalidates preempted triples. Reject datasets whose longest quiet window < ~18 µs
   (2×guard + conversion train) as an explicit error. Add `sample_window_us` /
   `placement_jitter_max` metrics (mirror the existing `drain_max_us` / probe pattern). →
5. **Validate on the harness:** placement jitter ≤ 2 µs, overrun invalidations ≈ 0,
   `age_used_max_us` unchanged/better, `pass` stays green.

Fallback ladder if B fails on hardware (best-effort, in order): median-of-drained-triples →
value-domain rate-limit gate → accept + flag bad phases advisory-only. See study §5.

## Key facts / constraints

- Switching cycle 60 µs (repeats 4× per DMA pass); ADC continuous 250 kS/s → triple/12 µs,
  frame(4 triples)/48 µs. ADC & signal clocks independent (free-running).
- DMA control task runs **interrupts-on** (hardware DMA drives pins) → calling ADC APIs at
  its control point is legal. This is *only* true for the DMA engine; the CPU bit-bang engine
  is interrupt-disabled during generation — keep it out of scope (it still uses the old
  seqlock producer).
- Scenario B flips ADC to oneshot-owned-by-Core-1 while running → the 250 kS/s continuous
  stream disappears during a run (already discarded to the newest triple anyway); `rate_tps`
  meaning changes accordingly.
- Test loop: `task flash` then `task uart:control-latency` (COM3 exclusive; no parallel
  runs). Probe/latency JSON fields documented in `docs/reading_pipeline_optimization.html`.

## Uncommitted / not mine

- `main/src/helper_common.cpp` — line-ending-only dirt (leave out, per prior handoffs).
- `web/src/components/ImageModal.tsx` — user's own React-portal change, unrelated; do not
  fold into firmware commits.

## Suggested skills

- **grill-me** (or **anthropic-skills:grill-with-docs**) — before writing Scenario B, stress
  the offset-selection and overrun-invalidation design against the measured guard band; the
  wrong quiet-window choice is costly to flash/test.
- **mado-html** — extend `docs/adc_sampling_vs_switching.html` with the "before" phase
  histogram (step 3) and the final validation results, rather than starting a new doc.
- **code-review** — over any Core-1 sampling change before committing (real-time path).
