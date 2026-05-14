# TODO History

- [x] Expand Analog Data Acquisition section in `project_architecture_guide.html`
  - [x] Document architecture changes from commit 697726a to HEAD
  - [x] Add before/after timeframe charts (old oneshot vs new DMA pipeline)
  - [x] Add data flow diagram for the new DMA acquisition path
  - [x] Document seqlock snapshot publication mechanism
  - [x] Document calibration LUT and per-channel queue parser
  - [x] Document control consumption via `analog_read_control_snapshot`
  - [x] Document fault gate system and miss policy
  - [x] Document new BLE commands and diagnostic infrastructure
  - [x] Reference the implementation plan milestones
