export interface IBleService {
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    send(command: string): Promise<void>;
    subscribe(callback: (data: any) => void): Promise<void>;
}
