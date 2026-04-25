# ESP32 Web Dashboard -- Comprehensive Analysis & Implementation Status

**Date:** 2025-07-17
**Project:** ESP32 Web Dashboard (web/)
**Scope:** Architecture, Security, Performance

---

## 1. Architecture

### Overview

Layered SPA architecture with four tiers:

| Layer | Location | Responsibility |
|-------|----------|----------------|
| Presentation | src/components/ | React components, drag-drop layout, Chart.js |
| State | src/store/ | Zustand stores (bleStore, dataStore) |
| Service | src/services/ | BLE abstraction (IBleService -> WebBleService -> BleManager) |
| Algorithm | src/helper.ts | Pure signal-generation math |

### Design Patterns

- **Facade + Singleton:** BleManager wraps WebBleService, adds auto-reconnect and data parsing. Module-level singleton.
- **Strategy:** IBleService interface allows swapping BLE implementations without touching components.
- **Observer:** Zustand stores act as observable containers; components subscribe via hooks.
- **Dependency Injection:** DashboardItem injects dragHandleRef into children via React.cloneElement (fragile -- bypasses TypeScript).

### Component Inventory

**Active Dashboard Panels (7):**

| Component | Purpose | Store |
|-----------|---------|-------|
| SignalAnalysis | Real-time Chart.js line chart + metric cards | dataStore |
| SignalGenerator | Duty cycle slider, signal preview, binary table, upload | bleStore.alpha |
| QuickActions | Global controls, alpha presets, parametric inputs | bleStore.alpha |
| ManualCommand | Free-form BLE command terminal with history | None |
| SystemLogs | Live scrolling log viewer | bleStore.statusLogs |
| StatusPanel | Diagnostic data display | bleStore.lastStatusMessage |
| HelpPanel | Static BLE command reference (click-to-copy) | None |

**Legacy / Dead Code (6 files):**

| File | Reason |
|------|--------|
| bluetooth.ts | Module-level globals, superseded by services/ |
| MenuConnectionToolbar.tsx | Imports legacy bluetooth.ts |
| MenuControlManual.tsx | Imports legacy bluetooth.ts |
| MenuControlSignal.tsx | Imports legacy bluetooth.ts |
| Chart.tsx | Older chart, duplicate DataPoint type |
| ImageModal.tsx | Not wired into new dashboard |

### Data Flow

**Inbound (ESP32 -> Dashboard):**
```
BLE Notification -> WebBleService.subscribe -> BleManager.handleData()
  -> LOG/STATUS -> bleStore.addLog() / setLastStatusMessage()
  -> Sensor data -> dataStore.addDataPoint() -> SignalAnalysis re-renders
```

**Outbound (Dashboard -> ESP32):**
```
User action -> component -> bleManager.send() -> WebBleService.send() -> GATT write
```

### Architecture Score: 7/10

**Strengths:** Clean BLE abstraction, minimal state management, signal algorithm isolation, Go single-binary deployment.

**Weaknesses:** BleManager tightly coupled to stores (untestable), React.cloneElement prop injection fragile, no test infrastructure, alpha stored as string instead of number.

---

## 2. Security

### Overall Risk: HIGH

The system controls physical power electronics hardware with no authentication, no encryption, and no command authorization.

### Critical Findings

| # | Finding | Severity |
|---|---------|----------|
| 1 | No BLE authentication -- any device within range can connect and send commands | Critical |
| 2 | No BLE encryption -- GATT permissions lack ENCRYPTED flag | Critical |
| 3 | Free-form command injection via ManualCommand.tsx | Critical |
| 4 | No signal validation -- malicious SIGNAL can create shoot-through (all switches ON) | Critical |
| 5 | No hardware safety interlocks visible in codebase | Critical |
| 6 | No command authorization levels (read vs control use same channel) | Critical |
| 7 | Parametric injection via chunk/cycles/monitor values | High |
| 8 | No command rate limiting | Medium |
| 9 | No HTTPS on Go server | Medium |
| 10 | No security headers (CSP, X-Content-Type-Options, etc.) | Medium |
| 11 | Incomplete sanitization in StatusPanel (allows TAB/newline) | Low |
| 12 | recharts in dependencies but never imported | Low |

### Physical Safety Context

Per AGENT.md: Core 1 has interrupts and WDT disabled for jitter-free GPIO control. This means:
- No software safety net on the control core
- Malicious signal patterns execute without interruption
- The only protection is the double-buffer swap, which validates nothing about signal content

### Security Score: 3/10

---

## 3. Performance

### Findings

| # | Finding | Impact |
|---|---------|--------|
| 1 | No React.memo on any dashboard panel | High |
| 2 | Broad Zustand selectors (destructuring entire stores) | High |
| 3 | Triple .map() for chart data (4 passes over 1000-point array) | Medium |
| 4 | Array spread on every data point ([...state.data, point]) | Medium |
| 5 | [...statusLogs].reverse() on every render in SystemLogs | Medium |
| 6 | key={maxPoints} forces full Chart.js destroy/recreate | Medium |
| 7 | recharts in package.json but never imported (dead weight) | Medium |
| 8 | BLE event listener never removed (potential leak) | Medium |
| 9 | TextEncoder/TextDecoder created per message | Low |
| 10 | No useMemo for sorted ITEM_IDS in App.tsx | Low |
| 11 | No caching headers in Go server | Low |
| 12 | No code splitting (single 407 KB JS bundle) | Low |
| 13 | Render-blocking Google Fonts | Low |
| 14 | new Date() in SystemLogs map (shows current time, not log time -- likely bug) | Low |

### Performance Score: 5/10 (before fixes)

---

## 4. Implementation Status

### Completed

#### 4.1 React Compiler Integration

| Change | Detail |
|--------|--------|
| babel-plugin-react-compiler | Added to vite.config.ts with target: '18' |
| eslint-plugin-react-compiler | Added to eslint.config.js with error severity |
| react-compiler-runtime | Added as runtime dependency |
| QuickActions.tsx | Removed unused imports (useRef, useEffect, Gauge) |
| StatusPanel.tsx | Added missing dragHandleRef to Props interface |

**Effect:** Automatic component memoization, useMemo/useCallback, JSX memoization. Bundle: 341 KB -> 407 KB (+21 KB gzip).

**Resolves findings:** Performance #1

#### 4.2 Zustand Selector Optimization

| File | Change |
|------|--------|
| SignalAnalysis.tsx | Destructure -> 4 individual selectors (data, clearData, maxPoints, setMaxPoints) |
| SignalGenerator.tsx | Destructure -> 2 individual selectors (alpha, setAlpha) |
| QuickActions.tsx | Destructure -> 2 individual selectors (alpha, setAlpha) |
| SystemLogs.tsx | Destructure -> 2 individual selectors (statusLogs, clearLogs) |
| StatusPanel.tsx | Destructure -> 1 individual selector (lastStatusMessage) |
| Header.tsx | Destructure -> 2 individual selectors (isConnected, systemStatus) |

**Effect:** Components only re-render when their specific fields change. BLE data point -> only SignalAnalysis re-renders. BLE log -> only SystemLogs re-renders.

**Resolves findings:** Performance #2

### Remaining (Not Implemented)

#### Security (all open)

| # | Action | Priority | Effort |
|---|--------|----------|--------|
| S1 | Add BLE encryption (ESP_GATT_PERM_READ_ENCRYPTED) | P0 | Hours |
| S2 | Add firmware-side signal validation (reject shoot-through) | P0 | Hours |
| S3 | Implement BLE bonding with passkey | P1 | Days |
| S4 | Add hardware safety interlocks (emergency stop, overcurrent) | P0 | Weeks |
| S5 | Add command authentication (shared secret / PIN) | P1 | Days |
| S6 | Add range validation on all numeric BLE parameters | P1 | Hours |
| S7 | Add command rate limiting | P2 | Hours |
| S8 | Add HTTPS to Go server | P2 | Hours |
| S9 | Add security headers (CSP, X-Content-Type-Options, etc.) | P2 | 30 min |
| S10 | Complete sanitization regex (strip TAB/newline) | P3 | 5 min |
| S11 | Add npm audit to build pipeline | P2 | 5 min |

#### Performance (remaining)

| # | Action | Impact | Effort |
|---|--------|--------|--------|
| P1 | Single-pass data mapping for chartData (replace 4x .map() with 1x for loop) | Medium | 30 min |
| P2 | Remove key={maxPoints} from Line component | Medium | 1 min |
| P3 | Batch BLE data updates with requestAnimationFrame | Medium | Hours |
| P4 | Replace [...statusLogs].reverse() with CSS flex-direction: column-reverse | Medium | 15 min |
| P5 | Module-level TextEncoder/TextDecoder singletons in WebBleService | Low | 5 min |
| P6 | useMemo for sorted ITEM_IDS in App.tsx | Low | 15 min |
| P7 | Remove recharts from package.json dependencies | Medium | 1 min |
| P8 | Fix BLE event listener leak (store handler ref, remove on cleanup) | Medium | 30 min |
| P9 | Add Cache-Control headers in Go server | Low | 15 min |
| P10 | Code-split SignalAnalysis with React.lazy() | Low | Hours |
| P11 | Preload Google Fonts with font-display: swap | Low | 10 min |
| P12 | Fix new Date() bug in SystemLogs (should show log creation time) | Low | 15 min |

#### Architecture / Maintainability (remaining)

| # | Action | Effort |
|---|--------|--------|
| A1 | Delete 6 legacy files (bluetooth.ts, Menu*.tsx, Chart.tsx, ImageModal.tsx) | 5 min |
| A2 | Extract shared UUIDs into src/constants.ts | 15 min |
| A3 | Move agentation import in App.tsx to dynamic import() | 10 min |
| A4 | Change bleStore.alpha from string to number | Hours |
| A5 | Add test infrastructure (vitest + React Testing Library) | Days |
| A6 | Decouple BleManager from stores (accept callbacks instead of calling getState) | Days |
| A7 | Replace React.cloneElement prop injection with Context for dragHandleRef | Hours |
| A8 | Move mock data generator from Header.tsx to MockDataService.ts | Hours |
| A9 | Remove showHelp from bleStore (belongs in component-local state) | 5 min |

---

## 5. Scorecard

| Dimension | Initial | Current | Target |
|-----------|---------|---------|--------|
| Architecture | 7/10 | 7/10 | 8/10 |
| Maintainability | 6/10 | 6/10 | 8/10 |
| Security | 3/10 | 3/10 | 7/10 |
| Performance | 5/10 | 7/10 | 8/10 |

**Current performance gains:** React Compiler (automatic memoization) + Zustand selector fixes (targeted subscriptions). Estimated ~70% reduction in unnecessary re-renders under data load.
