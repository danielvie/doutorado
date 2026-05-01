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
    encodeUiCommand,
} from "../proto/messaging-helpers";

class BleManager {
    private service: IBleService;
    private startTime: number;
    private requestId: number;
    private connectPromise: Promise<void> | null;

    constructor() {
        this.service = new WebBleService();
        this.startTime = Date.now();
        this.requestId = 1;
        this.connectPromise = null;
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

    async reconnectAfterOta(rebootDelayMs = 2500) {
        const { addLog, setSystemStatus } = useBleStore.getState();

        await this.disconnect();
        setSystemStatus("Waiting for ESP32 reboot...");
        addLog("Waiting for ESP32 reboot before reconnecting...");
        await this.delay(rebootDelayMs);
        await this.connect({ preferRememberedDevice: true });
    }

    async sendBinary(data: Uint8Array, options: { withoutResponse?: boolean } = {}) {
        const { isConnected } = useBleStore.getState();
        if (!isConnected) await this.connect({ preferRememberedDevice: true });
        await this.service.send(data, options);
    }

    async sendCommand(name: string, payload: Record<string, unknown> = {}) {
        const request_id = this.requestId++;
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
                        `us cycles UP   : ${s.us_cycles_up}`,
                        `us cycles DOWN : ${s.us_cycles_down}`,
                        `Congestion     : ${s.ble_congested ? "YES" : "NO"}`,
                        `ADC Latency avg: ${s.adc_avg} us`,
                        `ADC Latency min: ${s.adc_min} us`,
                        `ADC Latency max: ${s.adc_max} us`,
                    ];
                    
                    const statusStr = statusLines.join("\n");
                    useBleStore.getState().addLog(statusStr);
                    useBleStore.getState().setLastStatusMessage(statusStr);
                    useBleStore.getState().setIsCongested(!!s.ble_congested);
                } else if (packet.log) {
                    const l = packet.log;
                    useBleStore.getState().addLog(`${l.level || "INFO"}: ${l.text}`);
                } else if (packet.ota_status) {
                    const s = packet.ota_status;
                    useBleStore.getState().addLog(`OTA [${s.state}]: ${s.progress_percent}% - ${s.message || ""}`);
                    // You might want to update a dedicated OTA store here
                } else if (packet.command_result) {
                    const r = packet.command_result;
                    const status = r.ok ? "OK" : "ERROR";
                    const suffix = r.json ? `\n${r.json}` : "";
                    useBleStore.getState().addLog(
                        `CMD ${status} [${r.name || "unknown"}] ${r.message || r.code || ""}${suffix}`,
                    );
                }
                return;
            } catch (err) {
                console.error("Failed to decode Protobuf packet:", err);
            }
        }

        console.warn("Unrecognized binary data from BLE:", uint8Array);
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
