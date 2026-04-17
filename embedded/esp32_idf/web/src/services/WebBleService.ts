import { IBleService } from "./BleService.interface";
import { useBleStore } from "../store/bleStore";

const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

export class WebBleService implements IBleService {
    private device: BluetoothDevice | null = null;
    private gattServer: BluetoothRemoteGATTServer | null = null;
    private characteristic: BluetoothRemoteGATTCharacteristic | null = null;

    async connect(): Promise<void> {
        const { setSystemStatus, setIsConnected, addLog, setError, setDevice } =
            useBleStore.getState();

        try {
            if (this.device) {
                if (this.device.gatt?.connected) {
                    addLog("Already connected");
                    setIsConnected(true);
                    setSystemStatus("Connected");
                    return;
                }
                setSystemStatus("Reconnecting to Device...");
                addLog("Reconnecting using stored reference...");
            } else {
                setSystemStatus("Requesting Device...");
                if (!navigator.bluetooth) {
                    throw new Error("Web Bluetooth API is not available. Ensure you are using a supported browser (Chrome/Edge) and accessing via HTTPS or localhost.");
                }
                // @ts-ignore - Navigator.bluetooth types might be missing in some environments
                const device = await navigator.bluetooth.requestDevice({
                    filters: [{ services: [SERVICE_UUID] }],
                });

                this.device = device;
                setDevice(device);

                device.addEventListener("gattserverdisconnected", this.handleDisconnect);
            }

            if (!this.device || !this.device.gatt) {
                 throw new Error("Device or GATT not available");
            }

            setSystemStatus("Connecting to GATT Server...");
            this.gattServer = (await this.device.gatt.connect()) || null;

            if (!this.gattServer) throw new Error("GATT Server not found");

            const service = await this.gattServer.getPrimaryService(SERVICE_UUID);
            this.characteristic = await service.getCharacteristic(
                CHARACTERISTIC_UUID,
            );

            setIsConnected(true);
            setSystemStatus("Connected");
            addLog("Connected to ESP32");
        } catch (error: any) {
            setError(error.message);
            setSystemStatus("Connection Failed");
            addLog(`Error: ${error.message}`);
            // If we fail to connect with stored device, maybe we should not clear it 
            // so user can try again, OR user might want to scan again. 
            // For now, adhere to keeping reference.
            throw error;
        }
    }

    private handleDisconnect = () => {
        const { setIsConnected, setSystemStatus, addLog } = useBleStore.getState();
        setIsConnected(false);
        setSystemStatus("Disconnected");
        addLog("Device Disconnected");
    };

    async disconnect(): Promise<void> {
        if (this.device && this.device.gatt?.connected) {
            this.device.gatt.disconnect();
        }
    }

    async send(command: string): Promise<void> {
        const { addLog } = useBleStore.getState();
        if (!this.characteristic) throw new Error("No characteristic");

        const encoder = new TextEncoder();
        await this.characteristic.writeValue(encoder.encode(command));
        addLog(`Sent: ${command}`);
    }

    async subscribe(callback: (data: string) => void): Promise<void> {
        if (!this.characteristic) throw new Error("No characteristic");

        await this.characteristic.startNotifications();

        this.characteristic.addEventListener(
            "characteristicvaluechanged",
            (event: any) => {
                const value = event.target.value;
                const decoder = new TextDecoder();
                const message = decoder.decode(value);
                callback(message);
            },
        );
        const { addLog } = useBleStore.getState();
        addLog("Started Notifications");
    }
}
