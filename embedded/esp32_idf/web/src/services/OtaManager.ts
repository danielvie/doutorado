import { bleManager } from "./BleManager";
import type { OtaStatusUpdate } from "./BleManager";
import { encodeOtaCommand } from "../proto/messaging-helpers";
import type { OtaCommand } from "../proto/messaging-helpers";
import { useBleStore } from "../store/bleStore";

export class OtaManager {
    private static CHUNK_SIZE = 440;
    private static MAX_PACKET_SIZE = 512;
    private static ACK_BATCH_CHUNKS = 24;
    private static ACK_TIMEOUT_MS = 3000;

    static async flash(file: File, onProgress?: (percent: number) => void) {
        const buffer = await file.arrayBuffer();
        const data = new Uint8Array(buffer);
        const totalSize = data.length;
        const totalChunks = Math.ceil(totalSize / this.CHUNK_SIZE);
        const startedAt = performance.now();
        let sentBytes = 0;
        let lastLoggedPercent = -10;
        let chunkWriteMode: "without-response" | "with-response" = "without-response";
        let totalSendMs = 0;
        let totalAckWaitMs = 0;
        let totalAckCount = 0;
        let latestStatus: OtaStatusUpdate | null = null;
        const unsubscribeOtaStatus = bleManager.onOtaStatus((status) => {
            latestStatus = status;
        });

        try {
            console.log(`Starting OTA of ${totalSize} bytes`);
            this.log(
                `OTA start: ${this.formatBytes(totalSize)}, ${totalChunks} chunks, chunk=${this.CHUNK_SIZE} bytes, ackBatch=${this.ACK_BATCH_CHUNKS}, browser=${navigator.userAgent}`,
            );

            // 1. Send OTA Begin
            const beginCmd: OtaCommand = {
                begin: { file_size: totalSize }
            };
            await this.sendProtobuf(beginCmd);

            // 2. Fast but simple: send a small no-response batch, then wait for firmware ACK.
            for (let seq = 0; seq < totalChunks;) {
                const batchEndSeq = Math.min(seq + this.ACK_BATCH_CHUNKS, totalChunks);
                const batchStartedAt = performance.now();

                for (; seq < batchEndSeq; seq++) {
                    const status = latestStatus as OtaStatusUpdate | null;
                    if (status?.state === 4) {
                        throw new Error(status.message || "OTA failed on ESP32");
                    }

                    const offset = seq * this.CHUNK_SIZE;
                    const end = Math.min(offset + this.CHUNK_SIZE, totalSize);
                    const chunkData = data.slice(offset, end);

                    const chunkCmd: OtaCommand = {
                        chunk: {
                            seq,
                            data: chunkData
                        }
                    };

                    try {
                        await this.sendProtobuf(chunkCmd, { withoutResponse: chunkWriteMode === "without-response" });
                    } catch (err) {
                        if (chunkWriteMode === "without-response") {
                            chunkWriteMode = "with-response";
                            this.log(
                                `OTA write-without-response failed at seq ${seq}; falling back to write-with-response (${this.errorMessage(err)})`,
                            );
                            await this.sendProtobuf(chunkCmd);
                        } else {
                            throw err;
                        }
                    }

                    sentBytes = end;

                    if (onProgress) {
                        onProgress(Math.round((end / totalSize) * 100));
                    }

                    const percent = Math.round((sentBytes / totalSize) * 100);
                    if (percent >= lastLoggedPercent + 10 || sentBytes === totalSize) {
                        lastLoggedPercent = percent;
                        this.logProgress(percent, sentBytes, totalSize, startedAt, chunkWriteMode);
                    }
                }
                totalSendMs += performance.now() - batchStartedAt;

                if (chunkWriteMode === "without-response") {
                    const ackStartedAt = performance.now();
                    const acked = await this.waitForAck(() => latestStatus, batchEndSeq, this.ACK_TIMEOUT_MS);
                    const ackWaitMs = performance.now() - ackStartedAt;
                    totalAckWaitMs += ackWaitMs;
                    totalAckCount++;

                    if (!acked) {
                        throw new Error(`Timed out waiting for OTA ACK seq ${batchEndSeq}`);
                    }
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
            this.log(
                `OTA timing: send=${(totalSendMs / 1000).toFixed(1)}s, ackWait=${(totalAckWaitMs / 1000).toFixed(1)}s, avgAck=${totalAckCount ? totalAckWaitMs / totalAckCount : 0}ms`,
            );
        } finally {
            unsubscribeOtaStatus();
        }
    }

    private static async sendProtobuf(cmd: OtaCommand, options: { withoutResponse?: boolean } = {}) {
        const encoded = encodeOtaCommand(cmd);
        const packet = new Uint8Array(encoded.length + 1);
        packet[0] = 0x02; // Binary prefix for OtaCommand
        packet.set(encoded, 1);
        
        if (packet.length > this.MAX_PACKET_SIZE) {
            throw new Error(`OTA packet size ${packet.length} exceeds BLE payload limit ${this.MAX_PACKET_SIZE}`);
        }

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

    private static async waitForAck(
        getStatus: () => OtaStatusUpdate | null,
        targetExpectedSeq: number,
        timeoutMs: number,
    ) {
        const startedAt = performance.now();

        while (performance.now() - startedAt < timeoutMs) {
            const status = getStatus();

            if (status?.state === 4) {
                throw new Error(status.message || "OTA failed on ESP32");
            }

            if (status && status.expected_seq >= targetExpectedSeq) {
                return true;
            }

            await this.delay(10);
        }

        return false;
    }

    private static errorMessage(err: unknown) {
        return err instanceof Error ? err.message : String(err);
    }

    private static delay(ms: number): Promise<void> {
        return new Promise((resolve) => window.setTimeout(resolve, ms));
    }

}
