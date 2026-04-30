export interface IBleService {
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    send(data: Uint8Array): Promise<void>;
    subscribe(callback: (data: any) => void): Promise<void>;
}
