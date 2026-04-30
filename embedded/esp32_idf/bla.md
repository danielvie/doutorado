Add structured UI command router with protobuf schema

- Introduce UiCommand/UiCommandResult protobuf messages for namespaced
  commands with JSON payloads (e.g., "signal.start")
- Add ui_command_router module with handler registry and input validation
  (reject cycles:0, period_ms:0, invalid JSON)
- Migrate web client from text commands to sendCommand() with typed payloads
- Add CODE_DESIGN_ANALYSIS_REPORT.md documenting architecture risks
- Add explicit component REQUIRES in CMakeLists.txt