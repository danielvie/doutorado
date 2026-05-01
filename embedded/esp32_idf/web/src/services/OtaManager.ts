import { bleManager } from "./BleManager";
import { encodeOtaCommand } from "../proto/messaging-helpers";
import type { OtaCommand } from "../proto/messaging-helpers";
import { useBleStore } from "../store/bleStore";

export class OtaManager {
    private static CHUNK_SIZE = 440; // High speed chunk size
    private static WITHOUT_RESPONSE_WINDOW = 6;
    private static WITHOUT_RESPONSE_PAUSE_MS = 10;

    static async flash(file: File, onProgress?: (percent: number) => void) {
        const buffer = await file.arrayBuffer();
        const data = new Uint8Array(buffer);
        const totalSize = data.length;
        const totalChunks = Math.ceil(totalSize / this.CHUNK_SIZE);
        const startedAt = performance.now();
        let sentBytes = 0;
        let lastLoggedPercent = -10;
        let chunkWriteMode: "without-response" | "with-response" = "without-response";

        console.log(`Starting OTA of ${totalSize} bytes`);
        this.log(
            `OTA start: ${this.formatBytes(totalSize)}, ${totalChunks} chunks, chunk=${this.CHUNK_SIZE} bytes, browser=${navigator.userAgent}`,
        );

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

            try {
                await this.sendProtobuf(chunkCmd, { withoutResponse: chunkWriteMode === "without-response" });
            } catch (err) {
                if (chunkWriteMode === "without-response") {
                    chunkWriteMode = "with-response";
                    this.log(
                        `OTA write-without-response unavailable; falling back to write-with-response (${this.errorMessage(err)})`,
                    );
                    await this.sendProtobuf(chunkCmd);
                } else {
                    throw err;
                }
            }

            sentBytes = end;
            const sentChunks = Math.floor(offset / this.CHUNK_SIZE) + 1;

            if (chunkWriteMode === "without-response" && sentChunks % this.WITHOUT_RESPONSE_WINDOW === 0) {
                await this.delay(this.WITHOUT_RESPONSE_PAUSE_MS);
            }
            
            if (onProgress) {
                onProgress(Math.round((end / totalSize) * 100));
            }

            const percent = Math.round((sentBytes / totalSize) * 100);
            if (percent >= lastLoggedPercent + 10 || sentBytes === totalSize) {
                lastLoggedPercent = percent;
                this.logProgress(percent, sentBytes, totalSize, startedAt, chunkWriteMode);
            }
        }

        // 3. Send OTA End
        const endCmd: OtaCommand = {
            end: { sha256: "" }
        };
        await this.sendProtobuf(endCmd);

        const elapsedSeconds = (performance.now() - startedAt) / 1000;
        console.log("OTA sequence sent.");
        this.log(
            `OTA sequence sent in ${elapsedSeconds.toFixed(1)}s, average ${this.formatBytes(totalSize / elapsedSeconds)}/s`,
        );
    }

    private static async sendProtobuf(cmd: OtaCommand, options: { withoutResponse?: boolean } = {}) {
        const encoded = encodeOtaCommand(cmd);
        const packet = new Uint8Array(encoded.length + 1);
        packet[0] = 0x02; // Binary prefix for OtaCommand
        packet.set(encoded, 1);
        
        if (packet.length > 512) {
            console.error(`CRITICAL: Packet size ${packet.length} exceeds BLE limit!`, cmd);
        }

        console.log(`[OTA] Sending packet of ${packet.length} bytes`);
        await bleManager.sendBinary(packet, options);
    }

    private static logProgress(
        percent: number,
        sentBytes: number,
        totalSize: number,
        startedAt: number,
        mode: "without-response" | "with-response",
    ) {
        const elapsedSeconds = (performance.now() - startedAt) / 1000;
        const bytesPerSecond = elapsedSeconds > 0 ? sentBytes / elapsedSeconds : 0;
        this.log(
            `OTA ${percent}%: ${this.formatBytes(sentBytes)}/${this.formatBytes(totalSize)}, ${this.formatBytes(bytesPerSecond)}/s, mode=${mode}`,
        );
    }

    private static log(message: string) {
        useBleStore.getState().addLog(message);
        console.log(`[OTA] ${message}`);
    }

    private static formatBytes(bytes: number) {
        if (bytes >= 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(2)} MB`;
        if (bytes >= 1024) return `${(bytes / 1024).toFixed(1)} KB`;
        return `${Math.round(bytes)} B`;
    }

    private static errorMessage(err: unknown) {
        return err instanceof Error ? err.message : String(err);
    }

    private static delay(ms: number): Promise<void> {
        return new Promise((resolve) => window.setTimeout(resolve, ms));
    }
}
