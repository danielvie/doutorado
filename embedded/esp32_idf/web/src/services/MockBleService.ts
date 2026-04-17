import { IBleService } from "./BleService.interface";
import { useBleStore } from "../store/bleStore";

export class MockBleService implements IBleService {
    private timer: NodeJS.Timeout | null = null;
    private isConnected = false;
    private startTime = Date.now();

    async connect(): Promise<void> {
        const { setSystemStatus, setIsConnected, addLog } = useBleStore.getState();

        setSystemStatus("Connecting to Mock Device...");
        addLog("Mock: Connecting...");

        // Simulate 1s connection delay
        await new Promise((resolve) => setTimeout(resolve, 1000));

        this.isConnected = true;
        setIsConnected(true);
        setSystemStatus("Connected (Mock)");
        addLog("Mock: Connected!");
    }

    async disconnect(): Promise<void> {
        const { setSystemStatus, setIsConnected, addLog } = useBleStore.getState();

        if (this.timer) clearInterval(this.timer);
        this.isConnected = false;

        setIsConnected(false);
        setSystemStatus("Disconnected (Mock)");
        addLog("Mock: Disconnected");
    }

    async send(command: string): Promise<void> {
        const { addLog } = useBleStore.getState();

        if (!this.isConnected) throw new Error("Mock Device not connected");

        addLog(`Mock Sent: ${command}`);
        // Simulate slight delay
        await new Promise((resolve) => setTimeout(resolve, 100));
    }

    async subscribe(callback: (data: string) => void): Promise<void> {
        const { addLog } = useBleStore.getState();
        addLog("Mock: Subscribing to notifications...");

        if (this.timer) clearInterval(this.timer);

        // Simulate data stream every 100ms
        this.timer = setInterval(() => {
            if (!this.isConnected) return;

            const t = (Date.now() - this.startTime) / 1000;

            // Generate sine waves with different frequencies
            const an3 = 2.5 + 2.0 * Math.sin(t * 1.0); // 0.5 to 4.5
            const an5 = 1.0 + 0.5 * Math.sin(t * 2.0); // 0.5 to 1.5
            const an6 = 3.0 + 1.0 * Math.sin(t * 0.5); // 2.0 to 4.0

            // Format like the real device: "an3:1.23 an5:4.56 an6:7.89"
            const message = `an3:${an3.toFixed(2)} an5:${an5.toFixed(2)} an6:${an6.toFixed(2)}`;

            callback(message);
        }, 100);
    }
}
