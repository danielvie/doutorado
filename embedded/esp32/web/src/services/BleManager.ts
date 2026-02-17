import { IBleService } from "./BleService.interface";
import { MockBleService } from "./MockBleService";
import { WebBleService } from "./WebBleService";
import { useBleStore } from "../store/bleStore";
import { useDataStore } from "../store/dataStore";

class BleManager {
    private service: IBleService;
    private isMock: boolean = false;
    private startTime: number;

    constructor() {
        this.service = new WebBleService();
        this.startTime = Date.now();
    }

    // Switch between real and mock services
    setMockMode(enable: boolean) {
        if (this.isMock === enable) return;

        // Disconnect current service if connected
        this.service.disconnect().catch(console.error);

        this.isMock = enable;
        this.service = enable ? new MockBleService() : new WebBleService();

        useBleStore.getState().setMockMode(enable);
        useBleStore.getState().addLog(`Switched to ${enable ? "Mock" : "Real"} BLE Mode`);
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
    private handleData = (data: string) => {
        // 1. Log raw message if it's a LOG or STATUS
        if (data.includes("LOG") || data.includes("STATUS")) {
            useBleStore.getState().addLog(data);
            if (data.includes("STATUS")) {
                const statusMsg = data.replace("STATUS:", "").replace(/\s+$/, ""); // Remove trailing spaces
                useBleStore.getState().setLastStatusMessage(statusMsg);
            }
            return;
        }

        // 2. Parse sensor data: "an3:1.23 an5:4.56 an6:7.89"
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
