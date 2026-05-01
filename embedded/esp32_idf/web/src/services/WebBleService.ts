import type { BleConnectOptions } from "./BleService.interface";
import { IBleService } from "./BleService.interface";
import { useBleStore } from "../store/bleStore";

const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";
const RECONNECT_DELAYS_MS = [250, 750, 1500];

export class WebBleService implements IBleService {
    private device: BluetoothDevice | null = null;
    private gattServer: BluetoothRemoteGATTServer | null = null;
    private characteristic: BluetoothRemoteGATTCharacteristic | null = null;
    private notificationCharacteristic: BluetoothRemoteGATTCharacteristic | null = null;
    private notificationHandler: ((event: Event) => void) | null = null;

    async connect(options: BleConnectOptions = {}): Promise<void> {
        const { setSystemStatus, setIsConnected, setIsConnecting, addLog, setError, setDevice } =
            useBleStore.getState();
        let usingExistingDevice = false;

        try {
            setIsConnecting(true);
            setError(null);

            if (!navigator.bluetooth) {
                throw new Error("Web Bluetooth API is not available. Ensure you are using a supported browser (Chrome/Edge) and accessing via HTTPS or localhost.");
            }

            if (options.forceNewDevice) {
                this.forgetDeviceReference();
            }

            if (!this.device && options.preferRememberedDevice) {
                this.device = await this.getRememberedDevice();
                if (this.device) {
                    setDevice(this.device);
                    this.device.addEventListener("gattserverdisconnected", this.handleDisconnect);
                    addLog(`Using remembered device${this.device.name ? `: ${this.device.name}` : ""}`);
                }
            }

            if (this.device) {
                if (this.device.gatt?.connected) {
                    addLog("Already connected");
                    setIsConnected(true);
                    setSystemStatus("Connected");
                    return;
                }
                setSystemStatus("Reconnecting to Device...");
                addLog("Reconnecting using stored reference...");
                usingExistingDevice = true;
            } else {
                setSystemStatus("Requesting Device...");
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
            this.gattServer = await this.connectGattWithRetry(this.device);
            const service = await this.gattServer.getPrimaryService(SERVICE_UUID);
            this.characteristic = await service.getCharacteristic(CHARACTERISTIC_UUID);
            addLog(
                `BLE characteristic: write=${this.characteristic.properties.write}, writeWithoutResponse=${this.characteristic.properties.writeWithoutResponse}, notify=${this.characteristic.properties.notify}`,
            );

            setIsConnected(true);
            setSystemStatus("Connected");
            addLog("Connected to ESP32");
        } catch (error: any) {
            if (usingExistingDevice) {
                this.forgetDeviceReference();
                addLog("Stored BLE device reference cleared; retry will request device again.");
            }
            setError(error.message);
            setSystemStatus("Connection Failed");
            addLog(`Error: ${error.message}`);
            throw error;
        } finally {
            setIsConnecting(false);
        }
    }

    private handleDisconnect = () => {
        const { setIsConnected, setSystemStatus, addLog } = useBleStore.getState();
        this.gattServer = null;
        this.characteristic = null;
        this.notificationCharacteristic = null;
        setIsConnected(false);
        setSystemStatus("Disconnected");
        addLog("Device Disconnected");
    };

    private forgetDeviceReference() {
        if (this.device) {
            this.device.removeEventListener("gattserverdisconnected", this.handleDisconnect);
        }

        this.device = null;
        this.gattServer = null;
        this.characteristic = null;
        this.notificationCharacteristic = null;
        useBleStore.getState().setDevice(null);
    }

    async disconnect(): Promise<void> {
        if (this.device && this.device.gatt?.connected) {
            this.device.gatt.disconnect();
        } else {
            useBleStore.getState().setIsConnected(false);
        }
    }

    async send(data: Uint8Array, options: { withoutResponse?: boolean } = {}): Promise<void> {
        if (!this.characteristic || !this.device?.gatt?.connected) {
            throw new Error("BLE characteristic is not connected");
        }

        if (options.withoutResponse) {
            if (!this.characteristic.properties.writeWithoutResponse) {
                throw new Error("BLE characteristic does not support write without response");
            }

            await this.characteristic.writeValueWithoutResponse(data);
            return;
        }

        await this.characteristic.writeValueWithResponse(data);
    }

    async subscribe(callback: (data: any) => void): Promise<void> {
        if (!this.characteristic) throw new Error("No characteristic");

        await this.characteristic.startNotifications();

        if (this.notificationHandler && this.notificationCharacteristic) {
            this.notificationCharacteristic.removeEventListener(
                "characteristicvaluechanged",
                this.notificationHandler,
            );
        }

        this.notificationHandler = (event: Event) => {
            const value = (event.target as BluetoothRemoteGATTCharacteristic).value;
            if (value) callback(value);
        };

        this.characteristic.addEventListener(
            "characteristicvaluechanged",
            this.notificationHandler,
        );
        this.notificationCharacteristic = this.characteristic;
        const { addLog } = useBleStore.getState();
        addLog("Started Notifications");
    }

    private async getRememberedDevice(): Promise<BluetoothDevice | null> {
        const bluetooth = navigator.bluetooth as Bluetooth & {
            getDevices?: () => Promise<BluetoothDevice[]>;
        };

        if (!bluetooth.getDevices) return null;

        const devices = await bluetooth.getDevices();
        return devices.find((device) => !!device.gatt) ?? null;
    }

    private async connectGattWithRetry(
        device: BluetoothDevice,
    ): Promise<BluetoothRemoteGATTServer> {
        let lastError: unknown;

        for (let attempt = 0; attempt < RECONNECT_DELAYS_MS.length; attempt++) {
            try {
                const server = await device.gatt?.connect();
                if (server) return server;
            } catch (error) {
                lastError = error;
            }

            await this.delay(RECONNECT_DELAYS_MS[attempt]);
        }

        throw lastError instanceof Error
            ? lastError
            : new Error("GATT Server not found");
    }

    private delay(ms: number): Promise<void> {
        return new Promise((resolve) => window.setTimeout(resolve, ms));
    }
}
