Ran command: `t monitor`
Viewed BLE_COMMUNICATION_ANALYSIS.md:81-97

## Item 7: Unthrottled Telemetry Rate — Explained

**The current situation:**

```c
// main.cpp — analog_reading_task
for (;;) {
    if (ble_is_connected()) {
        // read ADC, build protobuf, send
        ble_send_protobuf(&packet);
    }
    vTaskDelay(pdMS_TO_TICKS(g_analog_monitor_period_ms));  // default 500ms
}
```

The user (from the web UI) can send `an_monitor_ms:10` and this changes `g_analog_monitor_period_ms` to **10 ms** — that's 100 telemetry packets/second.

**The problem:** There's no safety floor. Nothing stops someone from doing `an_monitor_ms:1` (1000 packets/sec). Even with all our fixes:
- Fix 6 (congestion) will **drop** the excess packets, so the link won't clog
- But the task still wakes up 1000×/sec, reads ADC, encodes protobuf, and calls `ble_send_protobuf` — all for packets that get thrown away

**The fix would be simple:** Clamp the minimum period so the system can't be configured into a wasteful state:

```c
// In ble_router where an_monitor_ms is parsed:
g_analog_monitor_period_ms = std::max(value, 50);  // floor at 50ms (20 Hz)
```

**Do you actually need this?** Now that fix 6 exists, the congestion flag already protects the BLE link. The remaining risk is just CPU waste from unnecessary ADC reads + protobuf encodes. If you're fine with the default 500ms and don't plan to let users set absurdly low values, this is low priority.

Want me to implement it, or close it out as "mitigated by fix 6"?