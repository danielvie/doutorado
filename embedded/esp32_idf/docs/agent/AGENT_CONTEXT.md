# ESP32 IDF Project — Agent Context

## Goal
Configure an ESP32 IDF project on Windows so that:
1. `task build`, `task flash`, `task monitor` etc. work from any shell.
2. Zed editor lints C/C++ files correctly via clangd.

---

## Environment

| Item | Path |
|---|---|
| ESP-IDF | `C:\Users\daniel\esp\v5.5.1\esp-idf` |
| ESP tools | `C:\Users\daniel\.espressif` |
| Python venv (correct one) | `C:\Users\daniel\.espressif\python_env\idf5.5_py3.13_env` |
| Toolchain | `C:\Users\daniel\.espressif\tools\xtensa-esp-elf\esp-14.2.0_20241119` |
| clangd (ESP fork) | `C:\Users\daniel\.espressif\tools\esp-clang\esp-19.1.2_20250312\esp-clang\bin\clangd.exe` |
| Target chip | `esp32` |
| Default serial port | `COM11` |

### Important: Python venv
There are three venvs. Only `idf5.5_py3.13_env` has the correct `esptool` version (`4.11.dev2`) required by IDF 5.5.1.  
`idf5.5_py3.11_env` has `4.10.0` and will be rejected.

---

## Project Structure

```
esp32_idf/
├── main/
│   ├── CMakeLists.txt
│   ├── main.cpp
│   ├── idf_component.yml
│   ├── Kconfig.projbuild
│   ├── include/
│   └── src/
│       ├── ble_controller.cpp
│       ├── helper_analog.cpp
│       ├── helper_common.cpp
│       ├── helper_datasetter.cpp
│       ├── helper_led.cpp
│       ├── helper_matrix.cpp
│       ├── helper_note.cpp
│       └── signal_controller.cpp
├── build/                  ← generated; contains compile_commands.json
├── .zed/
│   └── settings.json       ← Zed LSP config (clangd)
├── .clangd                 ← clangd project config
├── Taskfile.yml            ← task runner config
├── idf_run.ps1             ← PowerShell wrapper called by every task
├── CMakeLists.txt
├── sdkconfig
├── sdkconfig.defaults
└── sdkconfig.defaults.esp32
```

---