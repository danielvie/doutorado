# Zustand Selector Optimization

**Date:** 2025-07-17
**Project:** ESP32 Web Dashboard (web/)
**Depends on:** React Compiler Integration

## Context

After integrating React Compiler, the remaining performance bottleneck was Zustand subscription granularity. Components were destructuring entire stores, subscribing to all fields even when only 1-2 were needed. React Compiler can memoize output but cannot prevent Zustand from invoking the render function when unrelated fields change.

## Problem Pattern

Destructuring the entire store subscribes to all fields:

```ts
// BAD: re-renders on ANY bleStore change (logs, connection status, alpha, errors...)
const { alpha, setAlpha } = useBleStore();

// BAD: re-renders on ANY dataStore change (maxPoints, data...)
const { data, clearData, maxPoints, setMaxPoints } = useDataStore();
```

## Solution

Individual selectors with shallow comparison. Zustand uses strict equality (===) by default to determine if the selected value changed:

```ts
// GOOD: only re-renders when alpha changes
const alpha = useBleStore((s) => s.alpha);
const setAlpha = useBleStore((s) => s.setAlpha);  // setter is stable, never triggers re-render

// GOOD: only re-renders when data changes
const data = useDataStore((s) => s.data);
const clearData = useDataStore((s) => s.clearData);
```

## Changes Per File

### SignalAnalysis.tsx (High Impact)

Hottest component -- re-renders on every BLE data point. Subscribes to dataStore.

| Before | After |
|--------|-------|
| `const { data, clearData, maxPoints, setMaxPoints } = useDataStore()` | 4 individual selectors: `data`, `clearData`, `maxPoints`, `setMaxPoints` |

**Effect:** No longer re-renders when `maxPoints` changes (only when `data` array changes).

### SignalGenerator.tsx (Medium Impact)

Subscribes to bleStore for alpha control.

| Before | After |
|--------|-------|
| `const { alpha, setAlpha } = useBleStore()` | 2 individual selectors: `alpha`, `setAlpha` |

**Effect:** No longer re-renders on BLE log entries, connection state changes, or errors.

### QuickActions.tsx (Medium Impact)

Same pattern as SignalGenerator.

| Before | After |
|--------|-------|
| `const { alpha, setAlpha } = useBleStore()` | 2 individual selectors: `alpha`, `setAlpha` |

**Effect:** No longer re-renders on BLE log entries, connection state changes, or errors.

### SystemLogs.tsx (Medium Impact)

Subscribes to bleStore for log display.

| Before | After |
|--------|-------|
| `const { statusLogs, clearLogs } = useBleStore()` | 2 individual selectors: `statusLogs`, `clearLogs` |

**Effect:** No longer re-renders on connection state changes, alpha changes, or errors.

### StatusPanel.tsx (Low Impact)

Subscribes to bleStore for diagnostic display.

| Before | After |
|--------|-------|
| `const { lastStatusMessage } = useBleStore()` | 1 individual selector: `lastStatusMessage` |

**Effect:** No longer re-renders on log entries, connection state changes, or alpha changes.

### Header.tsx (Low Impact)

Subscribes to bleStore for connection UI. Already had correct selector for dataStore.

| Before | After |
|--------|-------|
| `const { isConnected, systemStatus } = useBleStore()` | 2 individual selectors: `isConnected`, `systemStatus` |

**Effect:** No longer re-renders on log entries, alpha changes, or errors.

## Files NOT Changed

### BleManager.ts + WebBleService.ts (Correct)

These use `useBleStore.getState()` and `useDataStore.getState()` -- the non-reactive getter. This is correct: services should read/write stores without subscribing to them. No change needed.

## Verification

- TypeScript compilation: passes (`tsc -b`)
- Vite build: succeeds (2.70s)
- Bundle size: unchanged from React Compiler baseline (407 KB / 133 KB gzip)

## Combined Effect (React Compiler + Zustand Selectors)

| Scenario | Before | After |
|----------|--------|-------|
| BLE data point arrives | All 7 panels re-render | Only SignalAnalysis re-renders |
| BLE log entry arrives | All 7 panels re-render | Only SystemLogs re-renders |
| Connection state changes | All 7 panels re-render | Only Header re-renders |
| Alpha slider moves | All 7 panels re-render | Only SignalGenerator + QuickActions re-render |
| maxPoints config changes | SignalAnalysis chart remounts | SignalAnalysis re-renders (no remount) |
