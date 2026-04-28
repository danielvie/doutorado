Edited messaging.proto
Ran command: `gs`
Viewed messaging.proto:48-61
Ran command: `g res`
Ran command: `gs`

Excellent. Lock-free is definitely the way to go for real-time performance.

One last detail for the Protobuf:
**Question 5: Message Structure**
Since we are calculating Min, Max, and Avg on the ESP32, how should we send it to the dashboard?
*   **A) Three separate fields**: `adc_min`, `adc_max`, `adc_avg`. (Clean, low bandwidth).
*   **B) A single field with the raw buffer**: Send all 128 values and let the browser do the math. (High bandwidth, but gives you a cool histogram/graph).

**My Recommendation: Option A (Three separate fields).** 
BLE bandwidth is precious. Sending 128 integers in every status heartbeat might trigger the "Congested" warning we just built. Three floats or integers is much lighter.

**Is Option A sufficient for your analysis, or do you want to see the distribution of the latency in the web UI?**