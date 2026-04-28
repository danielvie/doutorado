Ran command: `zz antigra`

Yes, but indirectly.

**1c (2M PHY) helps with throughput, not with the root cause of your delay.** Here's the distinction:

| Fix | What it does | Helps with transport delay? |
|---|---|---|
| **Fix 6 (congestion)** ✅ | Drops stale packets when queue is full | **Directly** — prevents backlog from forming |
| **Fix 1a (conn interval)** ✅ | Drains the queue faster (7.5ms vs 50ms) | **Indirectly** — backlog drains 6.5× faster |
| **Fix 1c (2M PHY)** | Each packet takes half the airtime | **Indirectly** — same effect as 1a, more room per interval |

2M PHY doubles the raw bit rate, so each connection interval can carry more data. This raises the ceiling before congestion kicks in. If your telemetry rate is *just barely* overwhelming the link at 1M PHY, switching to 2M could keep you below the congestion threshold entirely.

**But** — if your send rate truly exceeds what the link can handle (even at 2M), you'll still get the backlog. Fix 6 is the one that actually *prevents* the delay by dropping stale data.

So: 1c is a nice-to-have that raises headroom. Fix 6 is the one that solves your symptom. They're complementary.

One caveat: 2M PHY only works if the **client** also supports BLE 5.0 (most modern phones/laptops do, but older ones or some embedded clients don't).