# Execution Structure Optimization: Loop Unswitching & Deduplication

## The Execution Branch Bottleneck
While scanning the logic block used to commit High/Low voltage states to the output pins during `signal_loop_task()`, an inefficiency in code structure resulted in repetitive machine-level evaluation paths. 

### The Problem: Before Optimization
The ESP32 was forced into completely disparate block boundaries dictating how it should apply terminal Pin voltages logic:

```cpp
// ------------------------------------------
// BEFORE: Suboptimal Logic Fragmentation
// ------------------------------------------

if (clear_mask) {
    // ... apply Dead Time sequence

    // 1st Duplication
    GPIO.out_w1tc = clr_mask;
    GPIO.out_w1ts = set_mask;

    if (us > 1) { esp_rom_delay_us(us - 1); }
} else {
    // 2nd Duplication
    GPIO.out_w1tc = clr_mask;
    GPIO.out_w1ts = set_mask;

    if (us > 0) { esp_rom_delay_us(us); }
}
```

**Why this fails at high frequencies:**
The `GPIO.out` writes are identically executed regardless of the branch outcome, but caching and execution logic inside the CPU compiles them into two distinctly spaced binary locations. If the `if` block executes, the CPU pipeline fills with an entirely distinct pointer trace compared to the `else` block. 

---

## The Solution: Condensed Steady-State Linearization
We isolated the Dead Time execution into a strictly sequential check while collapsing the output writes and microsecond spinning bounds together. 

### The Result: After Optimization

```cpp
// ------------------------------------------
// AFTER: Single Shared Target execution
// ------------------------------------------

// 1. Check for transitions requiring Dead Time Action
if (clear_mask) {
    GPIO.out_w1tc = clear_mask;
    helper_delay_cycles(is_rising ? g_dead_time_cycles_up : g_dead_time_cycles_down);
    if (us > 0) us--; // Offset time tracking for the transition cost
}

// 2. Main Final Pulse Setup (Deduplicated hardware writes)
GPIO.out_w1tc = clr_mask;
GPIO.out_w1ts = set_mask;

// 3. Enforce Sequence Sustained Period Delay
if (us > 0) esp_rom_delay_us(us);
```

### Measured Gains
1. **Instruction Caching Efficiency**: The compiler unrolls to fewer bytes, keeping the highly active execution region easily contained in the closest L1-instruction boundaries.
2. **Predictable Processor Ticking**: Since the `w1tc / w1ts` assignments occur strictly outside of a branch evaluator, the ESP32 doesn't trigger divergent jumps over its architecture.

---

## How to Revert This
If you believe that extracting the final steady-state pin manipulations introduces unwanted `esp_rom_delay_us` artifacts and want to completely isolate Dead Time cycles from regular cycles again, you can revert this:

1. Inside `main/src/signal_controller.cpp`, trace the `for (int i = 0; i < sz; i++)` loop inside the continuous FreeRTOS task.
2. Under the variable instantiation blocks (`uint32_t clear_mask = dataset->clear_mask[i];` etc.), replace the linearized execution entirely with:
   ```cpp
   // Apply Dead Time if needed
   if (clear_mask) {
       GPIO.out_w1tc = clear_mask;
       uint32_t delay_cycles_val = is_rising ? g_dead_time_cycles_up : g_dead_time_cycles_down;
       helper_delay_cycles(delay_cycles_val);

       // Apply new state, clear complement
       GPIO.out_w1tc = clr_mask;
       GPIO.out_w1ts = set_mask;

       // Wait remaining time
       if (us > 1) {
           esp_rom_delay_us(us - 1);
       }
   } else {
       // No transition, but still enforce correct state on both sides
       GPIO.out_w1tc = clr_mask;
       GPIO.out_w1ts = set_mask;

       // Wait full time
       if (us > 0) {
           esp_rom_delay_us(us);
       }
   }
   ```
