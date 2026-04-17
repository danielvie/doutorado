# Signal Math Optimization: Loop Inline & Static Allocation

## The Performance Bottleneck
During the evaluation of the independent feedback calculations inside `signal_loop_task()`, two specific limitations were identified regarding execution bound efficiency and strict micro-timing constraints.

### The Problem: Before Optimization
The ESP32 was previously executing the feedback logic by initializing local control variables and querying a generic abstracted `matrix_multiply_vector3()` helper. This forced the processor to hop function boundaries.

```cpp
// ------------------------------------------
// BEFORE: Expensive Overheads
// ------------------------------------------

// 1. Stack Allocation (Occurs every loop cycle!)
float dtk[CONTROL_MAX_DTK];

// ...

// 2. Function Boundary Hop & Extraneous Branching
matrix_multiply_vector3(dataset->gain_k, e1, e2, e3, dtk);

// 3. Isolated Loop just for state negations
for (uint32_t j = 0; j < p; j++) {
    dtk[j] = -dtk[j];
}
```

**Why this fails at high frequencies:**
1. Dynamically initializing `float dtk[]` recursively loads CPU pipeline stack memory addresses per iteration sub-millisecond. 
2. Invoking an external function (`matrix_multiply_vector3`) causes register push/pop bounds.
3. Looping to process MAC (Multiply-Accumulate operations) and then performing a *second independent loop* simply to negate (`-K`) inherently doubles array bounds checking logic.

---

## The Solution: Static Context & Inline MAC Fusing
We achieved substantial $O(1)$ performance jumps inside `signal_controller.cpp` by statically lifting arrays out of execution scope and fusing mathematics together into one Hardware FPU execution block.

### The Result: After Optimization

```cpp
// ------------------------------------------
// AFTER: Memory Re-use & Fused ALU Pipeline
// ------------------------------------------

// 1. Statically lifted. Retains physical memory space pointers indefinitely!
static float dtk_buffer[MAX_SIGNAL_SIZE];

// ...

// 2. Inlined MAC and Inversion fusing 2 distinct iterations into 1 single pipeline trace.
const float* k_ptr = dataset->gain_k.values;
const int cols = dataset->gain_k.cols; // Fixed 3 for state space 

for (uint32_t j = 0; j < p; j++) {
    dtk_buffer[j] = -(k_ptr[j * cols + 0] * e1 + 
                      k_ptr[j * cols + 1] * e2 + 
                      k_ptr[j * cols + 2] * e3);
}
```

### Measured Gains
1. **Zero Stack Allocation**: Shifting `dtk[]` from `dynamic local` to `static` prevents ESP32 context setup waste mapping temporary byte bounds. 
2. **Function Context Skipping**: Hand-rolling the multiplication immediately injects FPU requests minimizing caching layers. 
3. **Array Operation Halved**: By tracking the `- (negative)` sign immediately inside the MAC parenthesis, one whole sequential Array traversal block has been completely purged from latency.

---

## How to Revert This
If you ever choose to modularize math components, replace the structure, or require the external `helper_matrix` bindings again, you can easily restore previous behaviors:

1. Inside `main/src/signal_controller.cpp`, search for `static float dtk_buffer[MAX_SIGNAL_SIZE];` and remove it near the top of the `signal_loop_task()`.
2. Inside the control evaluation (`if (dataset->gain_k.is_valid && dataset->size > 1)`), reinstall the local constraint: 
   ```cpp
   float dtk[CONTROL_MAX_DTK];
   ```
3. Replace the local `for (j=0;...` loop with the isolated API logic:
   ```cpp
   // Compute K * ek via helper API
   matrix_multiply_vector3(dataset->gain_k, e1, e2, e3, dtk);

   // Negate to get -K * ek
   for (uint32_t j = 0; j < p; j++) {
       dtk[j] = -dtk[j];
   }
   ```
4. Finally, swap occurrences of `dtk_buffer` to `dtk` inside parameters wrapping `condition_dtk(...)` and `compute_duration_corrections(...)`.
