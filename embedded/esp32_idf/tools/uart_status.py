#!/usr/bin/env python3
"""Request one ESP32 JSON line over UART.

Firmware protocol examples:
- status                 -> UART_STATUS { ...full status... }
- agent control-latency  -> AGENT_RESULT { ...task-specific fields... }
"""

from __future__ import annotations

import argparse
import json
import sys
import time

try:
    import serial
except ImportError as exc:
    raise SystemExit(
        "pyserial is required. Run this with the ESP-IDF Python environment "
        "or install pyserial."
    ) from exc


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Read one ESP32 UART JSON response")
    parser.add_argument("--port", default="COM3", help="Serial port, default: COM3")
    parser.add_argument("--baud", type=int, default=115200, help="Baud rate, default: 115200")
    parser.add_argument("--timeout", type=float, default=5.0, help="Timeout seconds, default: 5")
    parser.add_argument("--delay", type=float, default=0.5, help="Delay after opening serial, default: 0.5")
    parser.add_argument("--request", default="status", help="UART request line, default: status")
    parser.add_argument("--prefix", default=None, help="Expected response prefix")
    parser.add_argument("--warmup-request", default=None, help="Optional request sent before --request")
    parser.add_argument("--warmup-prefix", default=None, help="Expected warmup response prefix")
    parser.add_argument("--warmup-delay", type=float, default=1.0, help="Delay between warmup and request")
    parser.add_argument("--raw", action="store_true", help="Print raw prefixed line")
    return parser.parse_args()


def default_prefix(request: str) -> str:
    return "AGENT_RESULT" if request.strip().lower().startswith("agent ") else "UART_STATUS"


def read_prefixed_json(ser: serial.Serial, request: str, prefix: str, timeout: float) -> str | None:
    needle = f"{prefix} "
    deadline = time.monotonic() + timeout
    ser.reset_input_buffer()
    ser.write((request.rstrip() + "\n").encode("utf-8"))
    ser.flush()

    while time.monotonic() < deadline:
        line = ser.readline().decode("utf-8", errors="replace").strip()
        if line.startswith(needle):
            return line
    return None


def main() -> int:
    args = parse_args()
    prefix = args.prefix or default_prefix(args.request)

    with serial.Serial(args.port, args.baud, timeout=0.1) as ser:
        if args.delay > 0:
            time.sleep(args.delay)

        if args.warmup_request:
            warmup_prefix = args.warmup_prefix or default_prefix(args.warmup_request)
            warmup = read_prefixed_json(ser, args.warmup_request, warmup_prefix, args.timeout)
            if warmup is None:
                print(
                    f"Timed out waiting for {warmup_prefix} on {args.port} "
                    f"after warmup request {args.warmup_request!r}",
                    file=sys.stderr,
                )
                return 1
            if args.warmup_delay > 0:
                time.sleep(args.warmup_delay)

        line = read_prefixed_json(ser, args.request, prefix, args.timeout)
        if line is None:
            print(
                f"Timed out waiting for {prefix} on {args.port} after request {args.request!r}",
                file=sys.stderr,
            )
            return 1

        payload = line[len(prefix) + 1 :]
        if args.raw:
            print(line)
        else:
            print(json.dumps(json.loads(payload), indent=2, sort_keys=True))
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
