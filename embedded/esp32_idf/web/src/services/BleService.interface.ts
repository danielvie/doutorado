export interface BleConnectOptions {
    preferRememberedDevice?: boolean;
}

export interface IBleService {
    connect(options?: BleConnectOptions): Promise<void>;
    disconnect(): Promise<void>;
    send(data: Uint8Array): Promise<void>;
    subscribe(callback: (data: any) => void): Promise<void>;
}
