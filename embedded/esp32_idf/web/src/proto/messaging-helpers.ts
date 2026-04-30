import {
    BleAnalogReadState,
    BleControlState,
    BleLedMode,
    BlePacket,
    BleSignalSet,
    BleSignalState,
    OtaCommand as GeneratedOtaCommand,
    UiCommand as GeneratedUiCommand,
} from "./messaging";

export const decodeBleSignalSet = BleSignalSet as Record<number, string>;
export const decodeBleSignalState = BleSignalState as Record<number, string>;
export const decodeBleAnalogReadState = BleAnalogReadState as Record<number, string>;
export const decodeBleControlState = BleControlState as Record<number, string>;
export const decodeBleLedMode = BleLedMode as Record<number, string>;

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

    return {
        telemetry: packet.telemetry
            ? {
                  an3: packet.telemetry.an3,
                  an5: packet.telemetry.an5,
                  an6: packet.telemetry.an6,
                  timestamp_ms: packet.telemetry.timestampMs,
              }
            : undefined,
        status: packet.status
            ? {
                  active_set: packet.status.activeSet,
                  signal_state: packet.status.signalState,
                  ble_read_state: packet.status.bleReadState,
                  control_state: packet.status.controlState,
                  alpha: packet.status.alpha,
                  has_alpha: packet.status.hasAlpha,
                  matrix_a_valid: packet.status.matrixAValid,
                  matrix_b_valid: packet.status.matrixBValid,
                  current_cycles: packet.status.currentCycles,
                  total_cycles: packet.status.totalCycles,
                  monitor_ms: packet.status.monitorMs,
                  us_cycles_up: packet.status.usCyclesUp,
                  us_cycles_down: packet.status.usCyclesDown,
                  led_mode: packet.status.ledMode,
                  ble_congested: packet.status.bleCongested,
                  adc_min: packet.status.adcMin,
                  adc_max: packet.status.adcMax,
                  adc_avg: packet.status.adcAvg,
              }
            : undefined,
        log: packet.log,
        ota_status: packet.otaStatus
            ? {
                  state: packet.otaStatus.state,
                  progress_percent: packet.otaStatus.progressPercent,
                  message: packet.otaStatus.message,
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
    };
}
