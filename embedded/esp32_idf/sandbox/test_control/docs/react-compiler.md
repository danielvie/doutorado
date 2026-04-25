# React Compiler Integration

**Date:** 2025-07-17
**Project:** ESP32 Web Dashboard (web/)

## Context

The web dashboard had no component memoization, causing cascading re-renders across all 7 dashboard panels on every BLE data point or store update. React Compiler (formerly React Forget) was integrated to automatically memoize components, callbacks, and JSX without manual React.memo/useMemo/useCallback annotations.

## Changes

### Dependencies

| Package | Version | Type | Purpose |
|---------|---------|------|---------|
| babel-plugin-react-compiler | 1.0.0 | devDependency | Babel plugin that performs compilation |
| eslint-plugin-react-compiler | 19.1.0-rc.2 | devDependency | Lint rules for compiler violations |
| react-compiler-runtime | 1.0.0 | dependency | Runtime support for compiled output |

### vite.config.ts

Added babel plugin to @vitejs/plugin-react configuration:

```ts
react({
  babel: {
    plugins: [['babel-plugin-react-compiler', { target: '18' }]],
  },
}),
```

Target set to '18' to match React 18.3.1 used in the project.

### eslint.config.js

Added react-compiler plugin with error severity:

```js
import reactCompiler from 'eslint-plugin-react-compiler'

plugins: {
  'react-compiler': reactCompiler,
},
rules: {
  'react-compiler/react-compiler': 'error',
}
```

### Pre-existing TS Errors Fixed

- QuickActions.tsx: Removed unused imports (useRef, useEffect, Gauge)
- StatusPanel.tsx: Added missing dragHandleRef to Props interface

## Build Comparison

| Metric | Before | After | Delta |
|--------|--------|-------|-------|
| JS (raw) | 341 KB | 407 KB | +66 KB |
| JS (gzip) | 112 KB | 133 KB | +21 KB |
| CSS (raw) | 35 KB | 45 KB | +10 KB |
| CSS (gzip) | 6.5 KB | 7.9 KB | +1.4 KB |

The bundle increase is from react-compiler-runtime and memoization cache code. Acceptable trade-off for automatic memoization.

## What the Compiler Handles Automatically

- Component memoization (equivalent to React.memo on every component)
- useMemo/useCallback for all computed values and event handlers
- JSX memoization within components

## What Still Needs Manual Attention

The compiler cannot fix broad Zustand subscriptions. Components that destructure entire stores still re-render on any field change:

```ts
// SignalAnalysis.tsx - subscribes to ALL dataStore fields
const { data, clearData, maxPoints, setMaxPoints } = useDataStore();

// Should be individual selectors:
const data = useDataStore(s => s.data);
const clearData = useDataStore(s => s.clearData);
```

## Verification

- Build: bun run build succeeds (2.67s)
- Dev server: bun run dev starts successfully (251ms)
- Lint: eslint-plugin-react-compiler enforces compiler rules at error level
