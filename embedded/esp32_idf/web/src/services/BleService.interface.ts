export interface IBleService {
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    send(command: string | Uint8Array): Promise<void>;
    subscribe(callback: (data: any) => void): Promise<void>;
}
