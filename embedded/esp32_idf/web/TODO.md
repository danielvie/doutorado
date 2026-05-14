# TODO — StatusPanel Enhancements
- [x] Add "Clear" button to StatusPanel to clear the last status message
- [x] Implement clear action in bleStore (or use setLastStatusMessage(null))

# TODO — React Compiler Integration
- [ ] Install babel-plugin-react-compiler and eslint-plugin-react-compiler
- [ ] Configure babel plugin in vite.config.ts
- [ ] Configure eslint plugin in eslint.config.js
- [ ] Verify build succeeds (bun run build)
- [ ] Verify dev server runs (bun run dev)
- [x] Install babel-plugin-react-compiler and eslint-plugin-react-compiler
- [x] Configure babel plugin in vite.config.ts
- [x] Configure eslint plugin in eslint.config.js
- [x] Install react-compiler-runtime (runtime dependency)
- [x] Fix pre-existing TS errors (QuickActions unused imports, StatusPanel missing prop)
- [x] Verify build succeeds (bun run build)
- [x] Verify dev server runs (bun run dev)

# TODO — Dashboard reorder insertion
- [x] Migrate dashboard layout state from slot map to ordered array
- [x] Update drag targets to expose before/after insertion intent
- [x] Show insertion indicator during drag hover
- [x] Remove `grid-flow-dense` from dashboard grid
- [x] Verify reorder behavior with build
- [x] Replace clipped drop indicator with visible insertion marker
- [x] Switch insertion feedback from top/bottom to left/right
