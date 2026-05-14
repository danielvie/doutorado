import {
    BleAnalogReadState,
    BleControlState,
    BleLedMode,
    BlePacket,
    BleSignalSet,
    BleSignalState,
    OtaCommand as GeneratedOtaCommand,
    OtaState,
    UiCommand as GeneratedUiCommand,
} from "./messaging";

export const decodeBleSignalSet = BleSignalSet as Record<number, string>;
export const decodeBleSignalState = BleSignalState as Record<number, string>;
export const decodeBleAnalogReadState = BleAnalogReadState as Record<number, string>;
export const decodeBleControlState = BleControlState as Record<number, string>;
export const decodeBleLedMode = BleLedMode as Record<number, string>;
export const decodeOtaState = OtaState as Record<number, string>;

export type UiCommand = {
    name?: string;
    json?: string;
    request_id?: number;
};

export type OtaCommand = {
    begin?: {
        file_size?: number;
    };
    chunk?: {
        seq?: number;
        data?: Uint8Array;
    };
    end?: {
        sha256?: string;
    };
    abort?: boolean;
};

export function encodeUiCommand(message: UiCommand): Uint8Array {
    return GeneratedUiCommand.encode(
        GeneratedUiCommand.create({
            name: message.name,
            json: message.json,
            requestId: message.request_id,
        }),
    ).finish();
}

export function encodeOtaCommand(message: OtaCommand): Uint8Array {
    return GeneratedOtaCommand.encode(
        GeneratedOtaCommand.create({
            begin: message.begin
                ? {
                      fileSize: message.begin.file_size,
                  }
                : undefined,
            chunk: message.chunk
                ? {
                      seq: message.chunk.seq,
                      data: message.chunk.data,
                  }
                : undefined,
            end: message.end,
            abort: message.abort,
        }),
    ).finish();
}

export function decodeBlePacket(binary: Uint8Array) {
    const packet = BlePacket.toObject(BlePacket.decode(binary));
    const numberValue = (value: unknown) => {
        if (typeof value === "number") return value;
        if (value && typeof (value as { toNumber?: unknown }).toNumber === "function") {
            return (value as { toNumber: () => number }).toNumber();
        }
        return 0;
    };
    const booleanValue = (value: unknown) => (typeof value === "boolean" ? value : false);

    return {
        telemetry: packet.telemetry
            ? {
                  an3: numberValue(packet.telemetry.an3),
                  an5: numberValue(packet.telemetry.an5),
                  an6: numberValue(packet.telemetry.an6),
                  timestamp_ms: numberValue(packet.telemetry.timestampMs),
              }
            : undefined,
        status: packet.status
            ? {
                  active_set: numberValue(packet.status.activeSet),
                  signal_state: numberValue(packet.status.signalState),
                  ble_read_state: numberValue(packet.status.bleReadState),
                  control_state: numberValue(packet.status.controlState),
                  alpha: numberValue(packet.status.alpha),
                  has_alpha: booleanValue(packet.status.hasAlpha),
                  matrix_a_valid: booleanValue(packet.status.matrixAValid),
                  matrix_b_valid: booleanValue(packet.status.matrixBValid),
                  current_cycles: numberValue(packet.status.currentCycles),
                  total_cycles: numberValue(packet.status.totalCycles),
                  monitor_ms: numberValue(packet.status.monitorMs),
                  dead_time_us: numberValue(packet.status.deadTimeUs),
                  led_mode: numberValue(packet.status.ledMode),
                  ble_congested: booleanValue(packet.status.bleCongested),
                  adc_min: numberValue(packet.status.adcMin),
                  adc_max: numberValue(packet.status.adcMax),
                  adc_avg: numberValue(packet.status.adcAvg),
                  dead_time_tail_overhead_cycles: numberValue(
                      packet.status.deadTimeTailOverheadCycles,
                  ),
                  analog: packet.status.analog
                      ? {
                            seq: numberValue(packet.status.analog.seq),
                            valid: booleanValue(packet.status.analog.valid),
                            timestamp_us: numberValue(packet.status.analog.timestampUs),
                            age_us: numberValue(packet.status.analog.ageUs),
                            target_triples_per_cycle: numberValue(
                                packet.status.analog.targetTriplesPerCycle,
                            ),
                            measured_triples_per_second:
                                numberValue(packet.status.analog.measuredTriplesPerSecond),
                            raw_an3: numberValue(packet.status.analog.rawAn3),
                            raw_an5: numberValue(packet.status.analog.rawAn5),
                            raw_an6: numberValue(packet.status.analog.rawAn6),
                            calibrated_an3: numberValue(packet.status.analog.calibratedAn3),
                            calibrated_an5: numberValue(packet.status.analog.calibratedAn5),
                            calibrated_an6: numberValue(packet.status.analog.calibratedAn6),
                            latency_min_us: numberValue(packet.status.analog.latencyMinUs),
                            latency_avg_us: numberValue(packet.status.analog.latencyAvgUs),
                            latency_p95_us: numberValue(packet.status.analog.latencyP95Us),
                            latency_max_us: numberValue(packet.status.analog.latencyMaxUs),
                            overflow_count: numberValue(packet.status.analog.overflowCount),
                            miss_count: numberValue(packet.status.analog.missCount),
                            consecutive_misses: numberValue(
                                packet.status.analog.consecutiveMisses,
                            ),
                            fault_code: numberValue(packet.status.analog.faultCode),
                            acquisition_mode: numberValue(packet.status.analog.acquisitionMode),
                            samples_read: numberValue(packet.status.analog.samplesRead),
                            samples_rejected: numberValue(packet.status.analog.samplesRejected),
                            channel_order_anomalies: numberValue(
                                packet.status.analog.channelOrderAnomalies,
                            ),
                            partial_triples: numberValue(packet.status.analog.partialTriples),
                            frame_drops: numberValue(packet.status.analog.frameDrops),
                            pool_flushes: numberValue(packet.status.analog.poolFlushes),
                            calibration_lut_ready: booleanValue(
                                packet.status.analog.calibrationLutReady,
                            ),
                        }
                      : undefined,
              }
            : undefined,
        log: packet.log,
        ota_status: packet.otaStatus
            ? {
                  state: packet.otaStatus.state ?? 0,
                  progress_percent: packet.otaStatus.progressPercent ?? 0,
                  message: packet.otaStatus.message ?? "",
                  written_size: packet.otaStatus.writtenSize ?? 0,
                  expected_seq: packet.otaStatus.expectedSeq ?? 0,
              }
            : undefined,
        command_result: packet.commandResult
            ? {
                  request_id: packet.commandResult.requestId,
                  name: packet.commandResult.name,
                  ok: packet.commandResult.ok,
                  code: packet.commandResult.code,
                  message: packet.commandResult.message,
                  json: packet.commandResult.json,
              }
            : undefined,
        analog_diagnostic_result: packet.analogDiagnosticResult
            ? {
                  valid: booleanValue(packet.analogDiagnosticResult.valid),
                  running: booleanValue(packet.analogDiagnosticResult.running),
                  duration_ms: numberValue(packet.analogDiagnosticResult.durationMs),
                  elapsed_us: numberValue(packet.analogDiagnosticResult.elapsedUs),
                  seq_delta: numberValue(packet.analogDiagnosticResult.seqDelta),
                  miss_delta: numberValue(packet.analogDiagnosticResult.missDelta),
                  overflow_delta: numberValue(packet.analogDiagnosticResult.overflowDelta),
                  seq: numberValue(packet.analogDiagnosticResult.seq),
                  age_us: numberValue(packet.analogDiagnosticResult.ageUs),
                  rate_tps: numberValue(packet.analogDiagnosticResult.rateTps),
                  raw_an3: numberValue(packet.analogDiagnosticResult.rawAn3),
                  raw_an5: numberValue(packet.analogDiagnosticResult.rawAn5),
                  raw_an6: numberValue(packet.analogDiagnosticResult.rawAn6),
                  cal_an3: numberValue(packet.analogDiagnosticResult.calAn3),
                  cal_an5: numberValue(packet.analogDiagnosticResult.calAn5),
                  cal_an6: numberValue(packet.analogDiagnosticResult.calAn6),
                  latency_avg_us: numberValue(packet.analogDiagnosticResult.latencyAvgUs),
                  latency_p95_us: numberValue(packet.analogDiagnosticResult.latencyP95Us),
                  fault_code: numberValue(packet.analogDiagnosticResult.faultCode),
                  timing_samples: numberValue(packet.analogDiagnosticResult.timingSamples),
                  playback_avg_us: numberValue(packet.analogDiagnosticResult.playbackAvgUs),
                  loop_us: numberValue(packet.analogDiagnosticResult.loopUs),
                  overruns: numberValue(packet.analogDiagnosticResult.overruns),
                  timing_faults: numberValue(packet.analogDiagnosticResult.timingFaults),
                  message: packet.analogDiagnosticResult.message ?? "",
              }
            : undefined,
    };
}
