export interface BleConnectOptions {
    preferRememberedDevice?: boolean;
    forceNewDevice?: boolean;
}

export interface IBleService {
    connect(options?: BleConnectOptions): Promise<void>;
    disconnect(): Promise<void>;
    send(data: Uint8Array, options?: { withoutResponse?: boolean }): Promise<void>;
    subscribe(callback: (data: any) => void): Promise<void>;
}
