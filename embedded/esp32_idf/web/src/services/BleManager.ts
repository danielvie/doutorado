import { IBleService } from "./BleService.interface";
import type { BleConnectOptions } from "./BleService.interface";
import { WebBleService } from "./WebBleService";
import { useBleStore } from "../store/bleStore";
import { useDataStore } from "../store/dataStore";
import { 
    decodeBlePacket, 
    decodeBleSignalSet, 
    decodeBleSignalState, 
    decodeBleAnalogReadState, 
    decodeBleControlState,
    decodeBleLedMode,
    decodeOtaState,
    encodeUiCommand,
} from "../proto/messaging-helpers";

export type OtaStatusUpdate = {
    state: number;
    progress_percent: number;
    message: string;
    written_size: number;
    expected_seq: number;
};

class BleManager {
    private service: IBleService;
    private startTime: number;
    private requestId: number;
    private pendingCommands: Map<number, { name: string; payload: Record<string, unknown> }>;
    private connectPromise: Promise<void> | null;
    private otaStatusListeners: Set<(status: OtaStatusUpdate) => void>;

    constructor() {
        this.service = new WebBleService();
        this.startTime = Date.now();
        this.requestId = 1;
        this.pendingCommands = new Map();
        this.connectPromise = null;
        this.otaStatusListeners = new Set();
    }



    async connect(options: BleConnectOptions = {}) {
        const { isConnected } = useBleStore.getState();
        if (isConnected) return;
        if (this.connectPromise) return this.connectPromise;

        this.connectPromise = this.connectAndSubscribe(options);
        return this.connectPromise;
    }

    async disconnect() {
        await this.service.disconnect();
    }

    async reconnectAfterOta(rebootDelayMs = 4500) {
        const { addLog, setSystemStatus } = useBleStore.getState();

        setSystemStatus("Waiting for ESP32 reboot...");
        addLog("Waiting for ESP32 reboot before reconnecting...");
        await this.delay(rebootDelayMs);

        for (let attempt = 1; attempt <= 3; attempt++) {
            try {
                await this.connect({ preferRememberedDevice: true });
                return;
            } catch (error) {
                if (attempt === 3) throw error;

                setSystemStatus("Waiting for ESP32 BLE...");
                addLog(`Reconnect attempt ${attempt} failed; retrying...`);
                await this.delay(1500);
            }
        }
    }

    async sendBinary(data: Uint8Array, options: { withoutResponse?: boolean } = {}) {
        const { isConnected } = useBleStore.getState();
        if (!isConnected) await this.connect({ preferRememberedDevice: true });
        await this.service.send(data, options);
    }

    async sendCommand(name: string, payload: Record<string, unknown> = {}) {
        const request_id = this.requestId++;
        this.pendingCommands.set(request_id, { name, payload });
        const encoded = encodeUiCommand({
            name,
            json: JSON.stringify(payload),
            request_id,
        });
        const packet = new Uint8Array(encoded.length + 1);
        packet[0] = 0x03;
        packet.set(encoded, 1);

        await this.sendBinary(packet);
        return request_id;
    }

    onOtaStatus(listener: (status: OtaStatusUpdate) => void) {
        this.otaStatusListeners.add(listener);
        return () => this.otaStatusListeners.delete(listener);
    }

    // Handle incoming data from the service
    private handleData = (value: DataView) => {
        const uint8Array = new Uint8Array(value.buffer, value.byteOffset, value.byteLength);

        // 1. Check for binary prefix 0x01 (Protobuf)
        if (uint8Array[0] === 0x01) {
            try {
                // Skip the prefix byte
                const binary = uint8Array.slice(1);
                const packet = decodeBlePacket(binary);

                if (packet.telemetry) {
                    const t = packet.telemetry;
                    useDataStore.getState().addDataPoint({
                        time: ((Date.now() - this.startTime) / 1000).toFixed(3),
                        an3: t.an3 || 0,
                        an5: t.an5 || 0,
                        an6: t.an6 || 0,
                    });
                } else if (packet.status) {
                    const s = packet.status;
                    
                    // Helper to get string name from enum and clean it up
                    const formatEnum = (name: any) => {
                        if (!name || typeof name !== 'string') return "UNKNOWN";
                        return name.replace(/^BLE_(SIG_|READ_|CTRL_|SET_)?/, "");
                    };

                    const getVal = (val: any, decoder: any) => {
                        // In Proto3, 0 values are omitted and arrive as undefined.
                        // We must treat undefined as 0 (the default enum index).
                        const numericVal = (val === undefined || val === null) ? 0 : val;
                        if (typeof numericVal === 'string') return numericVal; 
                        return decoder[numericVal];
                    };

                    const active_set = formatEnum(getVal(s.active_set, decodeBleSignalSet)) || "NONE";
                    const signal_state = formatEnum(getVal(s.signal_state, decodeBleSignalState));
                    const ble_state = formatEnum(getVal(s.ble_read_state, decodeBleAnalogReadState));
                    const control_state = formatEnum(getVal(s.control_state, decodeBleControlState));
                    const led_state = formatEnum(getVal(s.led_mode, decodeBleLedMode));
                    const analog = s.analog;

                    const statusLines = [
                        "== status ==",
                        `Active         : ${active_set}`,
                        `Alpha          : ${s.has_alpha ? s.alpha?.toFixed(2) : "not set"}`,
                        `Matrix A       : ${s.matrix_a_valid ? "valid" : "not valid"}`,
                        `Matrix B       : ${s.matrix_b_valid ? "valid" : "not valid"}`,
                        `Signal state   : ${signal_state}`,
                        `BLE State      : ${ble_state}`,
                        `Control State  : ${control_state}`,
                        `Led State      : ${led_state}`,
                        `Cycles         : ${s.current_cycles} of ${s.total_cycles}`,
                        `g_an_monitor_ms: ${s.monitor_ms}`,
                        `Dead time      : ${s.dead_time_us} us`,
                        `Dead tail comp : ${s.dead_time_tail_overhead_cycles} cycles`,
                        `Congestion     : ${s.ble_congested ? "YES" : "NO"}`,
                        `ADC Latency avg: ${s.adc_avg} us`,
                        `ADC Latency min: ${s.adc_min} us`,
                        `ADC Latency max: ${s.adc_max} us`,
                    ];

                    if (analog) {
                        statusLines.push(
                            "== analog status ==",
                            `Seq            : ${analog.seq ?? 0}`,
                            `Valid          : ${analog.valid ? "YES" : "NO"}`,
                            `Age            : ${analog.age_us ?? 0} us`,
                            `Mode           : ${(analog.acquisition_mode ?? 0) === 1 ? "continuous" : "oneshot"}`,
                            `LUT ready      : ${analog.calibration_lut_ready ? "YES" : "NO"}`,
                            `Target triples : ${analog.target_triples_per_cycle ?? 0} per cycle`,
                            `Measured rate  : ${analog.measured_triples_per_second ?? 0} triples/s`,
                            `Raw AN3/AN5/AN6: ${analog.raw_an3 ?? 0} / ${analog.raw_an5 ?? 0} / ${analog.raw_an6 ?? 0}`,
                            `Cal AN3/AN5/AN6: ${(analog.calibrated_an3 ?? 0).toFixed(4)} / ${(analog.calibrated_an5 ?? 0).toFixed(4)} / ${(analog.calibrated_an6 ?? 0).toFixed(4)}`,
                            `Latency p95    : ${analog.latency_p95_us ?? 0} us`,
                            `Misses         : ${analog.miss_count ?? 0} total, ${analog.consecutive_misses ?? 0} consecutive`,
                            `Overflows      : ${analog.overflow_count ?? 0}`,
                            `DMA samples    : ${analog.samples_read ?? 0} read, ${analog.samples_rejected ?? 0} rejected`,
                            `DMA anomalies  : ${analog.channel_order_anomalies ?? 0} order, ${analog.partial_triples ?? 0} partial`,
                            `DMA drops/flush: ${analog.frame_drops ?? 0} / ${analog.pool_flushes ?? 0}`,
                            `Fault code     : ${analog.fault_code ?? 0}`,
                        );
                    }
                    
                    const statusStr = statusLines.join("\n");
                    useBleStore.getState().addLog(statusStr);
                    useBleStore.getState().setLastStatusMessage(statusStr);
                    useBleStore.getState().setLastStatusCommand({
                        name: "system.get_status",
                        payload: {},
                    });
                    useBleStore.getState().setIsCongested(!!s.ble_congested);
                } else if (packet.log) {
                    const l = packet.log;
                    useBleStore.getState().addLog(`${l.level || "INFO"}: ${l.text}`);
                } else if (packet.ota_status) {
                    const s = packet.ota_status;
                    const state = decodeOtaState[s.state] ?? s.state;
                    this.otaStatusListeners.forEach((listener) => listener(s));
                    if (state !== "OTA_DOWNLOADING" || s.message) {
                        useBleStore.getState().addLog(`OTA [${state}]: ${s.progress_percent}% - ${s.message || ""}`);
                    }
                    // You might want to update a dedicated OTA store here
                } else if (packet.analog_diagnostic_result) {
                    const t = packet.analog_diagnostic_result;
                    if (!t.valid && t.running) {
                        const message = t.message || "Analog diagnostic test running";
                        useBleStore.getState().addLog(message);
                        useBleStore.getState().setLastStatusMessage(message);
                        useBleStore.getState().setLastStatusCommand({
                            name: "debug.test.an.result",
                            payload: {},
                        });
                    } else if (!t.valid) {
                        const message = t.message || "No analog diagnostic test result is available";
                        useBleStore.getState().addLog(message);
                        useBleStore.getState().setLastStatusMessage(message);
                        useBleStore.getState().setLastStatusCommand({
                            name: "debug.test.an.result",
                            payload: {},
                        });
                    } else {
                        const testLines = [
                            "== analog diagnostic test ==",
                            `Running        : ${t.running ? "YES" : "NO"}`,
                            `Valid          : ${t.valid ? "YES" : "NO"}`,
                            `Duration       : ${t.duration_ms} ms`,
                            `Elapsed        : ${t.elapsed_us.toFixed(0)} us`,
                            `Seq delta      : ${t.seq_delta}`,
                            `Miss delta     : ${t.miss_delta}`,
                            `Overflow delta : ${t.overflow_delta}`,
                            `After seq      : ${t.seq}`,
                            `After age      : ${t.age_us} us`,
                            `After rate     : ${t.rate_tps} triples/s`,
                            `Raw AN3/AN5/AN6: ${t.raw_an3} / ${t.raw_an5} / ${t.raw_an6}`,
                            `Cal AN3/AN5/AN6: ${t.cal_an3.toFixed(4)} / ${t.cal_an5.toFixed(4)} / ${t.cal_an6.toFixed(4)}`,
                            `Latency avg    : ${t.latency_avg_us} us`,
                            `Latency p95    : ${t.latency_p95_us} us`,
                            `Fault          : ${t.fault_code}`,
                            `Timing samples : ${t.timing_samples}`,
                            `Playback avg   : ${t.playback_avg_us.toFixed(2)} us`,
                            `Loop           : ${t.loop_us.toFixed(2)} us`,
                            `Overruns       : ${t.overruns}`,
                            `Timing faults  : ${t.timing_faults}`,
                        ];
                        if (t.message) {
                            testLines.push(`Message        : ${t.message}`);
                        }
                        const statusStr = testLines.join("\n");
                        useBleStore.getState().addLog(statusStr);
                        useBleStore.getState().setLastStatusMessage(statusStr);
                        useBleStore.getState().setLastStatusCommand({
                            name: "debug.test.an.result",
                            payload: {},
                        });
                    }
                } else if (packet.analog_config_test_result) {
                    const t = packet.analog_config_test_result;
                    if (!t.valid) {
                        const message = t.message || "No analog config sweep result is available";
                        useBleStore.getState().addLog(message);
                        useBleStore.getState().setLastStatusMessage(message);
                        useBleStore.getState().setLastStatusCommand({
                            name: "debug.test.an.config_result",
                            payload: {},
                        });
                    } else {
                        const lines = [
                            "== analog config sweep ==",
                            `Running        : ${t.running ? "YES" : "NO"}`,
                            `Valid          : ${t.valid ? "YES" : "NO"}`,
                            `Cases          : ${t.case_count}`,
                        ];
                        for (const item of t.cases ?? []) {
                            lines.push(
                                `-- ${item.sample_hz} samples/s --`,
                                `Duration       : ${item.duration_ms} ms`,
                                `Elapsed        : ${item.elapsed_us.toFixed(0)} us`,
                                `Seq delta      : ${item.seq_delta}`,
                                `Rate           : ${item.rate_tps} triples/s`,
                                `DMA samples    : ${item.dma_samples_delta}`,
                                `DMA anomalies  : ${item.dma_anomalies_delta}`,
                                `Age            : ${item.age_us} us`,
                                `Miss/Overflow  : ${item.miss_delta} / ${item.overflow_delta}`,
                                `Latency avg/p95: ${item.latency_avg_us} / ${item.latency_p95_us} us`,
                                `Playback/Loop  : ${item.playback_avg_us.toFixed(2)} / ${item.loop_us.toFixed(2)} us`,
                                `Overrun/Fault  : ${item.overruns_delta} / ${item.timing_faults_delta}`,
                                `Fault code     : ${item.fault_code}`,
                            );
                        }
                        if (t.message) {
                            lines.push(`Message        : ${t.message}`);
                        }
                        const statusStr = lines.join("\n");
                        useBleStore.getState().addLog(statusStr);
                        useBleStore.getState().setLastStatusMessage(statusStr);
                        useBleStore.getState().setLastStatusCommand({
                            name: "debug.test.an.config_result",
                            payload: {},
                        });
                    }
                } else if (packet.command_result) {
                    const r = packet.command_result;
                    const sourceCommand = this.pendingCommands.get(r.request_id);
                    this.pendingCommands.delete(r.request_id);
                    const status = r.ok ? "OK" : "ERROR";
                    const suffix = r.json ? `\n${r.json}` : "";
                    if (r.name === "debug.signal_timing" && r.json) {
                        try {
                            const t = JSON.parse(r.json);
                            const metric = (longKey: string, shortKey: string) =>
                                Number(t[longKey] ?? t[shortKey] ?? 0);
                            const value = (longKey: string, shortKey: string) =>
                                t[longKey] ?? t[shortKey] ?? 0;
                            const timingLines = [
                                "== signal timing ==",
                                `Samples          : ${value("samples", "s")}`,
                                `Playback         : ${metric("playback_us", "pb").toFixed(2)} us`,
                                `Playback min     : ${metric("playback_min_us", "pmin").toFixed(2)} us`,
                                `Playback max     : ${metric("playback_max_us", "pmax").toFixed(2)} us`,
                                `Playback avg     : ${metric("playback_avg_us", "pavg").toFixed(2)} us`,
                                `Loop             : ${metric("loop_us", "loop").toFixed(2)} us`,
                                `Expected         : ${metric("expected_us", "exp").toFixed(2)} us`,
                                `Requested period : ${metric("requested_period_us", "req").toFixed(2)} us`,
                                `Scheduled period : ${metric("scheduled_period_us", "sch").toFixed(2)} us`,
                                `Measured period  : ${metric("measured_period_us", "meas").toFixed(2)} us`,
                                `Overhead         : ${metric("overhead_us", "oh").toFixed(2)} us`,
                                `Dead time        : ${metric("dead_time_us", "dt").toFixed(2)} us`,
                                `Overruns         : ${value("overrun_count", "ov")}`,
                                `Timing faults    : ${value("timing_fault_count", "tf")}`,
                                `Clamped segments : ${value("clamped_segment_count", "cl")}`,
                                `Skipped maint.   : ${value("maintenance_skipped_count", "ms")}`,
                                `Correction sum   : ${value("correction_sum_us", "corr")} us`,
                                `Steps            : ${value("steps", "steps")}`,
                            ];
                            useBleStore.getState().setLastStatusMessage(timingLines.join("\n"));
                            useBleStore.getState().setLastStatusCommand(
                                sourceCommand ?? { name: r.name, payload: {} },
                            );
                        } catch {
                            useBleStore.getState().setLastStatusMessage(r.json);
                            useBleStore.getState().setLastStatusCommand(
                                sourceCommand ?? { name: r.name, payload: {} },
                            );
                        }
                    }
                    useBleStore.getState().addLog(
                        `CMD ${status} [${r.name || "unknown"}] ${r.message || r.code || ""}${suffix}`,
                    );
                }
                return;
            } catch (err) {
                console.error("Failed to decode Protobuf packet:", err);
            }
        } else {
            // Handle raw text notifications
            const text = new TextDecoder().decode(uint8Array);
            if (text.trim()) {
                useBleStore.getState().addLog(text);
                useBleStore.getState().setLastStatusMessage(text);
            }
        }
    };

    private async connectAndSubscribe(options: BleConnectOptions) {
        try {
            await this.service.connect({ preferRememberedDevice: true, ...options });
            await this.service.subscribe(this.handleData);
        } catch (error) {
            console.error("Connection failed", error);
            throw error;
        } finally {
            this.connectPromise = null;
        }
    }

    private delay(ms: number): Promise<void> {
        return new Promise((resolve) => window.setTimeout(resolve, ms));
    }
}

export const bleManager = new BleManager();
