// Copyright 2026 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.
//
// I2S1-parallel DMA signal engine.
//
// Plays a Rendered Bitstream of one signal cycle through the I2S1 peripheral
// in 8-bit LCD/parallel mode, so signal timing is produced by hardware with
// zero CPU involvement. The control point runs as a normal watchdog-covered
// task triggered by an EOF descriptor placed a fixed lead before the cycle
// boundary, preserving the one-cycle (N -> N+1) correction contract.
//
// See docs/adr/0001-dual-signal-engine-i2s-dma.md and CONTEXT.md.

#pragma once

#include "signal_controller.h"

#include <cstddef>
#include <cstdint>
#include <string>

/// Sample clock definition (D2): one named constant drives everything.
/// 2 samples per Duration Tick = 20 MHz (50 ns/sample). Bump to 4 (40 MHz)
/// only if Lab Timing Characterization demands finer edge trimming.
static constexpr uint32_t SIGNAL_DMA_SAMPLES_PER_TICK = 2;
static constexpr uint32_t SIGNAL_DMA_SAMPLE_RATE_HZ =
    SIGNAL_TIME_TICKS_PER_US * SIGNAL_DMA_SAMPLES_PER_TICK * 1000000U;

struct DmaRenderStats {
    uint32_t cycle_samples;     ///< Samples of ONE cycle copy (post-correction)
    uint32_t copies;            ///< Identical cycle copies rendered in the buffer
    uint32_t clamped_segments;  ///< Segments clamped to the minimum active hold
    uint32_t timing_faults;     ///< Faults raised during rendering (clamps/padding)
};

/**
 * @brief Expands SignalStep[] into a per-sample 6-bit parallel bitstream (D5).
 *
 * Dead-time/shoot-through logic stays single-sourced in
 * signal_precompute_steps(); this only maps steps to samples. Dead time uses
 * the commanded g_dead_time_tenths_us (the CPU engine's cycle compensation is
 * software-overhead specific and intentionally NOT applied here, D10).
 *
 * @param ds          Dataset with precomputed steps.
 * @param corrections Per-segment Signal-Duration Corrections in ticks (may be
 *                    nullptr for the nominal pattern).
 * @param copies      Identical cycle copies to render back-to-back.
 * @param buf         DMA-capable output buffer (bytes stored in I2S FIFO
 *                    transmit order, i.e. position ^ 2 within 32-bit words).
 * @param capacity    Buffer capacity in bytes.
 * @param stats       Optional render statistics.
 * @return Rendered length in bytes (multiple of 4), or 0 on failure.
 */
size_t signal_render_bitstream(const DataSet *ds, const int32_t *corrections,
                               uint32_t copies, uint8_t *buf, size_t capacity,
                               DmaRenderStats *stats);

/**
 * @brief Starts the DMA engine on the active dataset.
 * Sets SignalState::RUNNING on success. Fails (false) when the rendered
 * pattern exceeds the DMA buffer budget or allocation fails.
 */
bool signal_dma_engine_start();

/// True while the DMA engine task owns the outputs.
bool signal_dma_engine_is_active();

/// Engine-specific telemetry fields, e.g. "\"render\":12,..." (no braces).
std::string signal_dma_timing_fields_json(void);

/// Common-core telemetry values for the DMA engine.
void signal_dma_get_timing_core(uint32_t *passes, float *requested_cycle_us,
                                float *measured_cycle_us,
                                uint32_t *missed_control_updates,
                                uint32_t *timing_faults);
