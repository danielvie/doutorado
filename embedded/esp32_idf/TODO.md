# TODO

- [x] Reorganize `project_architecture_guide.html` into requested sections
- [x] Review code created in this thread for comment gaps
- [x] Add concise "why" comments to the DMA/control/test code
- [x] Fix web build unused variable in `HelpPanel.tsx`
- [x] Verify firmware and web builds after documentation/comment edits

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
