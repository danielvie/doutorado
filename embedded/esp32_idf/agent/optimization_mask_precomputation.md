# Signal Mathematical Benchmarks: Why We Abandoned Mask Precomputation

## The Theoretical Optimization Goal
In typical low-level embedded architectures (like older 8-bit AVRs or 16-bit PICs), minimizing conditional branches `if ()` and bitwise bit-shifting inside a real-time loop leads to massive performance benefits. 

The goal of the **Precalculated GPIO Bitmasks** optimization was to strip out the dynamic history checks:
```cpp
bool change_6 = (d6 != last_d6);
if (change_6) clear_mask |= (MASK_U1_LOW | MASK_U1_HIGH);
```
And replace them with direct Zero-Latency memory reads or Lookup Tables (LUTs):
```cpp
uint32_t clear_mask = clear_mask_LUT[change];
```

## The Real World Result: Negligible Gains & High Risk

After successfully isolating other structural factors (like the math vectorization and loop delays), building and profiling this specific precomputation showed unstable edge-case behavior during dataset swaps with nearly **zero measurable performance improvement**.

Here is why this optimization was dangerous and fundamentally unnecessary:

### 1. Cycle Savings are Swallowed by `esp_rom_delay_us`
The ESP32 runs at 240MHz. A single CPU instruction executes in ~4.16 nanoseconds. 
By removing the `if/else` checks, the execution footprint shrank by roughly 10-15 instructions. That equals a saving of **~60 nanoseconds** per loop transition. 

However, your firmware's entire temporal baseline is strictly dictated by exact microsecond delays:
```cpp
esp_rom_delay_us(us);
```
If the CPU arrives at this delay line 60 nanoseconds faster because we streamlined the bitwise flags, the hardware simply **spins idly inside the delay block for those exact 60 nanoseconds**. It does not increase the frequency of your generated PWM/Signal!

### 2. The Compiler Branch Predictor
Modern 32-bit Xtensa cores (like the ESP32) have highly adept compiler pipelines. Because `dataset` profiles tend to hold consistent state transition rhythms (or hold `clear_mask == 0` completely during steady-state), the CPU's branch predictor preemptively caches the outcome of `change_6 = (d6 != last_d6)`. 
In reality, the dynamic `if/else` evaluations cost almost nothing compared to the time it takes the ESP32 to fetch RAM from outside the core.

### 3. Risk Profile
The logic to properly cache states seamlessly across `Dataset A` transferring cleanly to `Dataset B` without breaking the `is_rising` dead-time boundaries requires heavily convoluted structural changes (as we saw). The risk of dropping a dead-time frame and creating an accidental short-circuit far outweighs the theoretical 60-nanosecond CPU jitter reduction.

---

## Conclusion
The current execution format manually parsing states inside the loop is **the objectively safest, most accurate, and maintainable implementation.** 

The true heavy lifting was successfully accomplished by the other optimizations: 
- **Array Math Inlining**: Removed Floating-Point Unit stacking delays.
- **Loop Unswitching**: Cleaned identical output states and unified the `esp_rom_delay` exit block, giving the compiler the perfect structural boundary.
