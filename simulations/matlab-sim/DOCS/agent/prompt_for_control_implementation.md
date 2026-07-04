# Prompt: Export Control Law as C++ for ESP32 Embedded Implementation

## Objective

I need you to export the control law from this MATLAB simulation as **C++ code** that I can integrate into my ESP32 firmware. The code will run on an ESP32 at 240 MHz using ESP-IDF (FreeRTOS), with **interrupts disabled** on the core that executes the signal generation + control loop.

Please generate C++ code that implements the **closed-loop control action** based on the simulation, respecting the constraints and data structures described below.

---

## Target Platform Constraints

- **MCU:** ESP32 (Xtensa LX6 dual-core, 240 MHz)
- **Compiler:** GCC (xtensa-esp32-elf), C++17
- **RTOS:** FreeRTOS (ESP-IDF v5.5.1)
- **Control loop core:** Core 1, priority 10, **interrupts disabled** (`portDISABLE_INTERRUPTS()`)
- **No dynamic allocation** in the control loop (no `new`, `malloc`, `std::string`, `std::vector`)
- **No FreeRTOS API calls** in the control loop (no `xSemaphoreGive`, `vTaskDelay`, etc. — interrupts are off)
- **No floating-point unit** on ESP32 (software float — minimize float operations if possible, but float is acceptable)
- **Available timing:** `esp_rom_delay_us(us)` for microsecond delays, `esp_cpu_get_cycle_count()` for cycle-accurate timing

---

## Existing Data Structures

### DataSet (signal pattern + control parameters)
```cpp
#define MAX_SIGNAL_SIZE 100

struct DataSet {
    uint32_t time_durations[MAX_SIGNAL_SIZE];  // Duration of each segment (µs)
    uint32_t modes_d4[MAX_SIGNAL_SIZE];        // Pin d4 state per segment (0 or 1)
    uint32_t modes_d5[MAX_SIGNAL_SIZE];        // Pin d5 state per segment (0 or 1)
    uint32_t modes_d6[MAX_SIGNAL_SIZE];        // Pin d6 state per segment (0 or 1)
    uint32_t size;                              // Number of active segments
    int32_t  time_us_diff[MAX_SIGNAL_SIZE];    // Time corrections (reserved for control)
    float    target[3];                         // Control target vector [3×1]
    MatrixData gain_k;                          // Gain matrix K (typically 5×3)
};
```

### MatrixData
```cpp
#define MAX_MATRIX_ELEMENTS 100

struct MatrixData {
    float values[MAX_MATRIX_ELEMENTS];  // Matrix elements (row-major order)
    uint16_t size;                       // Total elements (rows × cols)
    uint16_t rows, cols;                 // Dimensions
    bool is_valid;                       // Validation flag
};
```

### Available matrix operation
```cpp
// Multiplies matrix M (rows×3) by vector [x1, x2, x3], stores in result[rows]
bool matrix_multiply_vector3(MatrixData& M, float x1, float x2, float x3, float* result);
```

### LogDuration (for performance profiling)
```cpp
struct LogDuration {
    int64_t read_and_send_analog_us;
    int64_t matrix_multiply_us;
    int64_t dtk_condition;
    int64_t update_signal_with_dtk;
};
extern LogDuration g_log_duration;
```

---

## Hardware I/O

### Analog inputs (ADC1, 12-bit, 3.3V reference, calibrated)
```cpp
float analog_read_port(AnalogPort port);  // Returns voltage in Volts [0.0 ~ 3.3]

// Available ports used for control feedback:
// AnalogPort::AN3 → GPIO 32 (ADC1_CH4)
// AnalogPort::AN5 → GPIO 34 (ADC1_CH6)
// AnalogPort::AN6 → GPIO 36 (ADC1_CH0)
```

### Digital outputs (3 complementary pairs with dead time)
```
PIN_OUT_6  (GPIO 23) / PIN_OUT_6_ (GPIO 22)  → controlled by modes_d6[]
PIN_OUT_5  (GPIO 21) / PIN_OUT_5_ (GPIO 19)  → controlled by modes_d5[]
PIN_OUT_4  (GPIO 18) / PIN_OUT_4_ (GPIO 17)  → controlled by modes_d4[]
```

Each pair is **complementary**: when d6=1, GPIO23=HIGH and GPIO22=LOW (and vice versa).
Dead time is inserted on transitions (configurable via `g_dead_time_cycles_up/down`, default 215 CPU cycles ≈ 0.9 µs).

---

## Current Signal Loop (where control must be integrated)

The signal generation loop runs on **Core 1** with interrupts disabled. It cycles through the `DataSet` segments continuously. Here is the current loop (simplified):

```cpp
static void signal_loop_task(void* arg) {
    DataSet* dataset = &g_dataset_a;
    
    portDISABLE_INTERRUPTS();

    while (g_system_state.signal_state == SignalState::RUNNING) {
        
        // --- Double buffer swap check ---
        if (g_ds_update_pending) {
            // swap dataset pointer between g_dataset_a and g_dataset_b
            g_ds_update_pending = false;
        }

        // --- Execute one full cycle of the signal pattern ---
        for (int i = 0; i < dataset->size; i++) {
            uint32_t us = dataset->time_durations[i];
            
            // Apply pin states (d4, d5, d6) with dead time on transitions
            // ... (GPIO register writes + delay) ...
            
            // --- CONTROL ACTION SHOULD GO HERE ---
            // At specific point(s) in the cycle, read ADC, compute control,
            // and modify the dataset (e.g., time_durations or time_us_diff)
            // for the NEXT cycle.
            
            // Current trigger mechanism (every g_cycle_nrun cycles):
            if (i == 0) {
                g_cycle_count = (g_cycle_count + 1) % g_cycle_nrun;
                if (g_cycle_count == 0) {
                    // TODO: implement control action here
                }
            }
        }
    }

    portENABLE_INTERRUPTS();
}
```

---

## Example: Pre-calculated dataset for alpha=0.10

Each alpha value defines a complete signal pattern + control parameters:

```cpp
// alpha = 0.10 → 6 segments, period = 6×(28+65) = 558 µs
dataset->size = 6;

// Time durations (µs): [28, 65, 28, 65, 28, 65]
// modes_d4: [0, 0, 0, 0, 1, 0]  → one pulse per period
// modes_d5: [0, 0, 1, 0, 0, 0]  → one pulse per period  
// modes_d6: [1, 0, 0, 0, 0, 0]  → one pulse per period

// Control target vector:
dataset->target[0] = 1.666804;  // target for AN3
dataset->target[1] = 3.333469;  // target for AN5
dataset->target[2] = 0.006804;  // target for AN6

// Gain matrix K (5×3, row-major):
// K = [-0.0465  -0.0237   0.0598
//      -0.0119   0.0116  -0.0285
//       0.0111  -0.0113   0.0291
//      -0.0116  -0.0232  -0.0278
//       0.0108   0.0221   0.0286]
dataset->gain_k.rows = 5;
dataset->gain_k.cols = 3;
dataset->gain_k.size = 15;
```

---

## What I Need You to Generate

1. **A C++ function** that implements the control action, something like:
   ```cpp
   void control_action(DataSet* dataset, float an3, float an5, float an6);
   ```
   This function should:
   - Compute the error: `e = measured - target`
   - Multiply: `u = K * e` (using `matrix_multiply_vector3` or inline)
   - Apply the control output `u` to modify the signal (e.g., adjusting `time_durations[]` or `time_us_diff[]`)

2. **Explain clearly** how the control output `u` (5×1 vector from K(5×3) × e(3×1)) maps to the signal modifications. Specifically:
   - What does each element of `u` control?
   - How should `u` modify `time_durations[]`?
   - Are there saturation/clamping limits?

3. **Integration guidance**: where exactly in the signal loop should the control function be called, and at what frequency relative to the signal period.

### Code requirements:
- Pure C/C++ (no MATLAB-specific constructs)
- No dynamic memory allocation
- No FreeRTOS calls  
- All arrays must be fixed-size (stack or within DataSet)
- Minimize floating-point operations where possible
- Include comments explaining the control theory behind each step
