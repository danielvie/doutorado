import { bleManager } from "./BleManager";
import { encodeOtaCommand } from "../proto/messaging";
import type { OtaCommand } from "../proto/messaging";

export class OtaManager {
    private static CHUNK_SIZE = 440; // High speed chunk size

    static async flash(file: File, onProgress?: (percent: number) => void) {
        const buffer = await file.arrayBuffer();
        const data = new Uint8Array(buffer);
        const totalSize = data.length;

        console.log(`Starting OTA of ${totalSize} bytes`);

        // 1. Send OTA Begin
        const beginCmd: OtaCommand = {
            begin: { file_size: totalSize }
        };
        await this.sendProtobuf(beginCmd);

        // 2. Send Chunks
        for (let offset = 0; offset < totalSize; offset += this.CHUNK_SIZE) {
            const end = Math.min(offset + this.CHUNK_SIZE, totalSize);
            const chunkData = data.slice(offset, end);
            
            const chunkCmd: OtaCommand = {
                chunk: {
                    seq: Math.floor(offset / this.CHUNK_SIZE),
                    data: chunkData
                }
            };

            await this.sendProtobuf(chunkCmd);
            
            if (onProgress) {
                onProgress(Math.round((end / totalSize) * 100));
            }
        }

        // 3. Send OTA End
        const endCmd: OtaCommand = {
            end: { sha256: "" }
        };
        await this.sendProtobuf(endCmd);

        console.log("OTA sequence sent.");
    }

    private static async sendProtobuf(cmd: OtaCommand) {
        const encoded = encodeOtaCommand(cmd);
        const packet = new Uint8Array(encoded.length + 1);
        packet[0] = 0x02; // Binary prefix for OtaCommand
        packet.set(encoded, 1);
        
        if (packet.length > 512) {
            console.error(`CRITICAL: Packet size ${packet.length} exceeds BLE limit!`, cmd);
        }

        console.log(`[OTA] Sending packet of ${packet.length} bytes`);
        await bleManager.sendBinary(packet);
    }
}
