import { IBleService } from "./BleService.interface";
import { WebBleService } from "./WebBleService";
import { useBleStore } from "../store/bleStore";
import { useDataStore } from "../store/dataStore";
import { decodeBlePacket } from "../proto/messaging";

class BleManager {
    private service: IBleService;
    private startTime: number;

    constructor() {
        this.service = new WebBleService();
        this.startTime = Date.now();
    }



    async connect() {
        const { isConnected } = useBleStore.getState();
        if (isConnected) return;

        try {
            await this.service.connect();
            // Auto-subscribe after connection
            await this.service.subscribe(this.handleData);
        } catch (error) {
            console.error("Connection failed", error);
        }
    }

    async disconnect() {
        await this.service.disconnect();
    }

    async send(command: string) {
        const { isConnected } = useBleStore.getState();
        if (!isConnected) {
            console.log("Not connected, trying to reconnect...");
            await this.connect();
        }
        await this.service.send(command);
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
                    // Handle binary status
                    const { state, alpha, cycle_count } = packet.status;
                    const statusStr = `STATUS: Binary (State:${state}, Alpha:${alpha?.toFixed(2)}, Cycles:${cycle_count})`;
                    useBleStore.getState().addLog(statusStr);
                    useBleStore.getState().setLastStatusMessage(statusStr);
                }
                return;
            } catch (err) {
                console.error("Failed to decode Protobuf packet:", err);
            }
        }

        // 2. Fallback to ASCII decoding
        const decoder = new TextDecoder();
        const data = decoder.decode(value);

        // Log raw message if it's a LOG or STATUS
        if (data.includes("LOG") || data.includes("STATUS")) {
            useBleStore.getState().addLog(data);
            if (data.includes("STATUS")) {
                const statusMsg = data.replace("STATUS:", "").replace(/\s+$/, ""); // Remove trailing spaces
                useBleStore.getState().setLastStatusMessage(statusMsg);
            }
            return;
        }

        // Parse sensor data: "an3:1.23 an5:4.56 an6:7.89"
        const regex = /(\w+):([\d.]+)/g;
        const parsed_data: Record<string, number> = {};
        let match;
        let has_match = false;

        while ((match = regex.exec(data)) !== null) {
            has_match = true;
            const key = match[1];
            const value = parseFloat(match[2]);
            parsed_data[key] = value;
        }

        if (has_match) {
            useDataStore.getState().addDataPoint({
                time: ((Date.now() - this.startTime) / 1000).toFixed(3), // Relative time 
                an3: parsed_data["an3"] || 0,
                an5: parsed_data["an5"] || 0,
                an6: parsed_data["an6"] || 0,
            });
        }
    };
}

export const bleManager = new BleManager();
