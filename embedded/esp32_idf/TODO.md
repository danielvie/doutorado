# TODO

- [x] Analyze existing commands in `QuickActions.tsx` and `BleManager.ts` to identify the correct command for "signal time and mode"
- [x] Add the "SIGNAL" button to `QuickActions.tsx` (calling `debug.dataset_active`)
- [x] Update `BleManager.ts` to handle raw text notifications from BLE
- [x] Verify the button triggers the correct command and updates `StatusPanel`
- [x] Refactor CPU signal loop to use continuous absolute edge deadlines
- [x] Add timing fault, overrun, clamp, and maintenance-skip reporting
- [x] Verify firmware build/compile after timing-loop changes
- [x] Fix `debug.signal_timing` BLE encoding overflow
- [x] Remove remaining inter-cycle final-state stretch for short CPU-loop patterns
- [x] Verify firmware/web build after follow-up fixes
