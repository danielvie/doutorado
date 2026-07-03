# Two coexisting signal engines: CPU busy-wait and I2S-parallel DMA

Status: accepted

The signal controller gains a second, runtime-selectable signal engine based on I2S parallel
(LCD) mode with DMA on the classic ESP32, alongside the existing CPU busy-wait engine. The CPU
engine achieves jitter-free timing only by disabling interrupts and the watchdog on Core 1, which
makes control computation and system health monitoring structurally unsafe. The DMA engine plays a
rendered bitstream at a fixed sample clock (10 MHz, one named constant) with zero CPU involvement,
so the control point becomes an ordinary watchdog-covered task and the one-cycle correction
contract (measure cycle N, commit before cycle N+1's correction commit deadline) is preserved —
keeping the existing gain matrices valid.

## Considered Options

- **MCPWM** — rejected: cannot express arbitrary ~100-segment switching-mode sequences.
- **RMT** — rejected: no DMA and no cross-channel synchronization on classic ESP32.
- **DMA engine only (replace CPU engine immediately)** — rejected: the CPU engine is the
  lab-characterized reference; it is retained until the DMA engine passes Lab Timing
  Characterization at all operating points, then retired.

## Consequences

- Temporary dual-maintenance burden. Mitigated by sharing the front-end:
  `signal_precompute_steps()` remains the single source of masks, dead time, and boundary
  classification; the DMA engine adds only a bitstream renderer on top (dead-time/shoot-through
  logic is never duplicated).
- Engine selection is a stopped-only, volatile command (`signal.engine`), defaulting to CPU —
  flashing the firmware changes nothing until an experiment opts in.
- The DMA engine starts with zero edge compensation: the CPU engine's cycle-based constants
  compensate software overhead that does not exist under DMA. Per-boundary trim fields (whole
  samples) are reserved and populated only from oscilloscope measurement.
- Safe state (all six terminals inactive) requires re-routing pins from the I2S matrix back to
  GPIO-low before DMA teardown; commanded stops finish the current cycle, fault stops detach
  immediately.
