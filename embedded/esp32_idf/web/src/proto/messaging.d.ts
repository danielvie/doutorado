export const enum BleSignalSet {
  BLE_SET_A = "BLE_SET_A",
  BLE_SET_B = "BLE_SET_B",
}

export const encodeBleSignalSet: { [key: string]: number } = {
  BLE_SET_A: 0,
  BLE_SET_B: 1,
};

export const decodeBleSignalSet: { [key: number]: BleSignalSet } = {
  0: BleSignalSet.BLE_SET_A,
  1: BleSignalSet.BLE_SET_B,
};

export const enum BleAnalogReadState {
  BLE_READ_IDLE = "BLE_READ_IDLE",
  BLE_READING = "BLE_READING",
  BLE_READ_DISABLED = "BLE_READ_DISABLED",
}

export const encodeBleAnalogReadState: { [key: string]: number } = {
  BLE_READ_IDLE: 0,
  BLE_READING: 1,
  BLE_READ_DISABLED: 2,
};

export const decodeBleAnalogReadState: { [key: number]: BleAnalogReadState } = {
  0: BleAnalogReadState.BLE_READ_IDLE,
  1: BleAnalogReadState.BLE_READING,
  2: BleAnalogReadState.BLE_READ_DISABLED,
};

export const enum BleSignalState {
  BLE_SIG_IDLE = "BLE_SIG_IDLE",
  BLE_SIG_RUNNING = "BLE_SIG_RUNNING",
}

export const encodeBleSignalState: { [key: string]: number } = {
  BLE_SIG_IDLE: 0,
  BLE_SIG_RUNNING: 1,
};

export const decodeBleSignalState: { [key: number]: BleSignalState } = {
  0: BleSignalState.BLE_SIG_IDLE,
  1: BleSignalState.BLE_SIG_RUNNING,
};

export const enum BleControlState {
  BLE_CTRL_OFF = "BLE_CTRL_OFF",
  BLE_CTRL_ON = "BLE_CTRL_ON",
}

export const encodeBleControlState: { [key: string]: number } = {
  BLE_CTRL_OFF: 0,
  BLE_CTRL_ON: 1,
};

export const decodeBleControlState: { [key: number]: BleControlState } = {
  0: BleControlState.BLE_CTRL_OFF,
  1: BleControlState.BLE_CTRL_ON,
};

export const enum BleLedMode {
  LED_NORMAL = "LED_NORMAL",
  LED_BLINKING = "LED_BLINKING",
}

export const encodeBleLedMode: { [key: string]: number } = {
  LED_NORMAL: 0,
  LED_BLINKING: 1,
};

export const decodeBleLedMode: { [key: number]: BleLedMode } = {
  0: BleLedMode.LED_NORMAL,
  1: BleLedMode.LED_BLINKING,
};

export const enum BleLogLevel {
  BLE_LOG_INFO = "BLE_LOG_INFO",
  BLE_LOG_WARN = "BLE_LOG_WARN",
  BLE_LOG_ERROR = "BLE_LOG_ERROR",
}

export const encodeBleLogLevel: { [key: string]: number } = {
  BLE_LOG_INFO: 0,
  BLE_LOG_WARN: 1,
  BLE_LOG_ERROR: 2,
};

export const decodeBleLogLevel: { [key: number]: BleLogLevel } = {
  0: BleLogLevel.BLE_LOG_INFO,
  1: BleLogLevel.BLE_LOG_WARN,
  2: BleLogLevel.BLE_LOG_ERROR,
};

export interface Telemetry {
  an3?: number;
  an5?: number;
  an6?: number;
  timestamp_ms?: number;
}

export function encodeTelemetry(message: Telemetry): Uint8Array {
  let bb = popByteBuffer();
  _encodeTelemetry(message, bb);
  return toUint8Array(bb);
}

function _encodeTelemetry(message: Telemetry, bb: ByteBuffer): void {
  // optional float an3 = 1;
  let $an3 = message.an3;
  if ($an3 !== undefined) {
    writeVarint32(bb, 13);
    writeFloat(bb, $an3);
  }

  // optional float an5 = 2;
  let $an5 = message.an5;
  if ($an5 !== undefined) {
    writeVarint32(bb, 21);
    writeFloat(bb, $an5);
  }

  // optional float an6 = 3;
  let $an6 = message.an6;
  if ($an6 !== undefined) {
    writeVarint32(bb, 29);
    writeFloat(bb, $an6);
  }

  // optional uint32 timestamp_ms = 4;
  let $timestamp_ms = message.timestamp_ms;
  if ($timestamp_ms !== undefined) {
    writeVarint32(bb, 32);
    writeVarint32(bb, $timestamp_ms);
  }
}

export function decodeTelemetry(binary: Uint8Array): Telemetry {
  return _decodeTelemetry(wrapByteBuffer(binary));
}

function _decodeTelemetry(bb: ByteBuffer): Telemetry {
  let message: Telemetry = {} as any;

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional float an3 = 1;
      case 1: {
        message.an3 = readFloat(bb);
        break;
      }

      // optional float an5 = 2;
      case 2: {
        message.an5 = readFloat(bb);
        break;
      }

      // optional float an6 = 3;
      case 3: {
        message.an6 = readFloat(bb);
        break;
      }

      // optional uint32 timestamp_ms = 4;
      case 4: {
        message.timestamp_ms = readVarint32(bb) >>> 0;
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export interface SystemStatus {
  active_set?: BleSignalSet;
  signal_state?: BleSignalState;
  ble_read_state?: BleAnalogReadState;
  control_state?: BleControlState;
  alpha?: number;
  has_alpha?: boolean;
  matrix_a_valid?: boolean;
  matrix_b_valid?: boolean;
  current_cycles?: number;
  total_cycles?: number;
  monitor_ms?: number;
  us_cycles_up?: number;
  us_cycles_down?: number;
  led_mode?: BleLedMode;
}

export function encodeSystemStatus(message: SystemStatus): Uint8Array {
  let bb = popByteBuffer();
  _encodeSystemStatus(message, bb);
  return toUint8Array(bb);
}

function _encodeSystemStatus(message: SystemStatus, bb: ByteBuffer): void {
  // optional BleSignalSet active_set = 1;
  let $active_set = message.active_set;
  if ($active_set !== undefined) {
    writeVarint32(bb, 8);
    writeVarint32(bb, encodeBleSignalSet[$active_set]);
  }

  // optional BleSignalState signal_state = 2;
  let $signal_state = message.signal_state;
  if ($signal_state !== undefined) {
    writeVarint32(bb, 16);
    writeVarint32(bb, encodeBleSignalState[$signal_state]);
  }

  // optional BleAnalogReadState ble_read_state = 3;
  let $ble_read_state = message.ble_read_state;
  if ($ble_read_state !== undefined) {
    writeVarint32(bb, 24);
    writeVarint32(bb, encodeBleAnalogReadState[$ble_read_state]);
  }

  // optional BleControlState control_state = 4;
  let $control_state = message.control_state;
  if ($control_state !== undefined) {
    writeVarint32(bb, 32);
    writeVarint32(bb, encodeBleControlState[$control_state]);
  }

  // optional float alpha = 5;
  let $alpha = message.alpha;
  if ($alpha !== undefined) {
    writeVarint32(bb, 45);
    writeFloat(bb, $alpha);
  }

  // optional bool has_alpha = 6;
  let $has_alpha = message.has_alpha;
  if ($has_alpha !== undefined) {
    writeVarint32(bb, 48);
    writeByte(bb, $has_alpha ? 1 : 0);
  }

  // optional bool matrix_a_valid = 7;
  let $matrix_a_valid = message.matrix_a_valid;
  if ($matrix_a_valid !== undefined) {
    writeVarint32(bb, 56);
    writeByte(bb, $matrix_a_valid ? 1 : 0);
  }

  // optional bool matrix_b_valid = 8;
  let $matrix_b_valid = message.matrix_b_valid;
  if ($matrix_b_valid !== undefined) {
    writeVarint32(bb, 64);
    writeByte(bb, $matrix_b_valid ? 1 : 0);
  }

  // optional uint32 current_cycles = 9;
  let $current_cycles = message.current_cycles;
  if ($current_cycles !== undefined) {
    writeVarint32(bb, 72);
    writeVarint32(bb, $current_cycles);
  }

  // optional uint32 total_cycles = 10;
  let $total_cycles = message.total_cycles;
  if ($total_cycles !== undefined) {
    writeVarint32(bb, 80);
    writeVarint32(bb, $total_cycles);
  }

  // optional uint32 monitor_ms = 11;
  let $monitor_ms = message.monitor_ms;
  if ($monitor_ms !== undefined) {
    writeVarint32(bb, 88);
    writeVarint32(bb, $monitor_ms);
  }

  // optional uint32 us_cycles_up = 12;
  let $us_cycles_up = message.us_cycles_up;
  if ($us_cycles_up !== undefined) {
    writeVarint32(bb, 96);
    writeVarint32(bb, $us_cycles_up);
  }

  // optional uint32 us_cycles_down = 13;
  let $us_cycles_down = message.us_cycles_down;
  if ($us_cycles_down !== undefined) {
    writeVarint32(bb, 104);
    writeVarint32(bb, $us_cycles_down);
  }

  // optional BleLedMode led_mode = 14;
  let $led_mode = message.led_mode;
  if ($led_mode !== undefined) {
    writeVarint32(bb, 112);
    writeVarint32(bb, encodeBleLedMode[$led_mode]);
  }
}

export function decodeSystemStatus(binary: Uint8Array): SystemStatus {
  return _decodeSystemStatus(wrapByteBuffer(binary));
}

function _decodeSystemStatus(bb: ByteBuffer): SystemStatus {
  let message: SystemStatus = {} as any;

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional BleSignalSet active_set = 1;
      case 1: {
        message.active_set = decodeBleSignalSet[readVarint32(bb)];
        break;
      }

      // optional BleSignalState signal_state = 2;
      case 2: {
        message.signal_state = decodeBleSignalState[readVarint32(bb)];
        break;
      }

      // optional BleAnalogReadState ble_read_state = 3;
      case 3: {
        message.ble_read_state = decodeBleAnalogReadState[readVarint32(bb)];
        break;
      }

      // optional BleControlState control_state = 4;
      case 4: {
        message.control_state = decodeBleControlState[readVarint32(bb)];
        break;
      }

      // optional float alpha = 5;
      case 5: {
        message.alpha = readFloat(bb);
        break;
      }

      // optional bool has_alpha = 6;
      case 6: {
        message.has_alpha = !!readByte(bb);
        break;
      }

      // optional bool matrix_a_valid = 7;
      case 7: {
        message.matrix_a_valid = !!readByte(bb);
        break;
      }

      // optional bool matrix_b_valid = 8;
      case 8: {
        message.matrix_b_valid = !!readByte(bb);
        break;
      }

      // optional uint32 current_cycles = 9;
      case 9: {
        message.current_cycles = readVarint32(bb) >>> 0;
        break;
      }

      // optional uint32 total_cycles = 10;
      case 10: {
        message.total_cycles = readVarint32(bb) >>> 0;
        break;
      }

      // optional uint32 monitor_ms = 11;
      case 11: {
        message.monitor_ms = readVarint32(bb) >>> 0;
        break;
      }

      // optional uint32 us_cycles_up = 12;
      case 12: {
        message.us_cycles_up = readVarint32(bb) >>> 0;
        break;
      }

      // optional uint32 us_cycles_down = 13;
      case 13: {
        message.us_cycles_down = readVarint32(bb) >>> 0;
        break;
      }

      // optional BleLedMode led_mode = 14;
      case 14: {
        message.led_mode = decodeBleLedMode[readVarint32(bb)];
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export interface LogMessage {
  level?: BleLogLevel;
  text?: string;
}

export function encodeLogMessage(message: LogMessage): Uint8Array {
  let bb = popByteBuffer();
  _encodeLogMessage(message, bb);
  return toUint8Array(bb);
}

function _encodeLogMessage(message: LogMessage, bb: ByteBuffer): void {
  // optional BleLogLevel level = 1;
  let $level = message.level;
  if ($level !== undefined) {
    writeVarint32(bb, 8);
    writeVarint32(bb, encodeBleLogLevel[$level]);
  }

  // optional string text = 2;
  let $text = message.text;
  if ($text !== undefined) {
    writeVarint32(bb, 18);
    writeString(bb, $text);
  }
}

export function decodeLogMessage(binary: Uint8Array): LogMessage {
  return _decodeLogMessage(wrapByteBuffer(binary));
}

function _decodeLogMessage(bb: ByteBuffer): LogMessage {
  let message: LogMessage = {} as any;

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional BleLogLevel level = 1;
      case 1: {
        message.level = decodeBleLogLevel[readVarint32(bb)];
        break;
      }

      // optional string text = 2;
      case 2: {
        message.text = readString(bb, readVarint32(bb));
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export interface BlePacket {
  telemetry?: Telemetry;
  status?: SystemStatus;
  log?: LogMessage;
}

export function encodeBlePacket(message: BlePacket): Uint8Array {
  let bb = popByteBuffer();
  _encodeBlePacket(message, bb);
  return toUint8Array(bb);
}

function _encodeBlePacket(message: BlePacket, bb: ByteBuffer): void {
  // optional Telemetry telemetry = 1;
  let $telemetry = message.telemetry;
  if ($telemetry !== undefined) {
    writeVarint32(bb, 10);
    let nested = popByteBuffer();
    _encodeTelemetry($telemetry, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }

  // optional SystemStatus status = 2;
  let $status = message.status;
  if ($status !== undefined) {
    writeVarint32(bb, 18);
    let nested = popByteBuffer();
    _encodeSystemStatus($status, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }

  // optional LogMessage log = 3;
  let $log = message.log;
  if ($log !== undefined) {
    writeVarint32(bb, 26);
    let nested = popByteBuffer();
    _encodeLogMessage($log, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }
}

export function decodeBlePacket(binary: Uint8Array): BlePacket {
  return _decodeBlePacket(wrapByteBuffer(binary));
}

function _decodeBlePacket(bb: ByteBuffer): BlePacket {
  let message: BlePacket = {} as any;

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional Telemetry telemetry = 1;
      case 1: {
        let limit = pushTemporaryLength(bb);
        message.telemetry = _decodeTelemetry(bb);
        bb.limit = limit;
        break;
      }

      // optional SystemStatus status = 2;
      case 2: {
        let limit = pushTemporaryLength(bb);
        message.status = _decodeSystemStatus(bb);
        bb.limit = limit;
        break;
      }

      // optional LogMessage log = 3;
      case 3: {
        let limit = pushTemporaryLength(bb);
        message.log = _decodeLogMessage(bb);
        bb.limit = limit;
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export interface Long {
  low: number;
  high: number;
  unsigned: boolean;
}

interface ByteBuffer {
  bytes: Uint8Array;
  offset: number;
  limit: number;
}

function pushTemporaryLength(bb: ByteBuffer): number {
  let length = readVarint32(bb);
  let limit = bb.limit;
  bb.limit = bb.offset + length;
  return limit;
}

function skipUnknownField(bb: ByteBuffer, type: number): void {
  switch (type) {
    case 0: while (readByte(bb) & 0x80) { } break;
    case 2: skip(bb, readVarint32(bb)); break;
    case 5: skip(bb, 4); break;
    case 1: skip(bb, 8); break;
    default: throw new Error("Unimplemented type: " + type);
  }
}

function stringToLong(value: string): Long {
  return {
    low: value.charCodeAt(0) | (value.charCodeAt(1) << 16),
    high: value.charCodeAt(2) | (value.charCodeAt(3) << 16),
    unsigned: false,
  };
}

function longToString(value: Long): string {
  let low = value.low;
  let high = value.high;
  return String.fromCharCode(
    low & 0xFFFF,
    low >>> 16,
    high & 0xFFFF,
    high >>> 16);
}

// The code below was modified from https://github.com/protobufjs/bytebuffer.js
// which is under the Apache License 2.0.

let f32 = new Float32Array(1);
let f32_u8 = new Uint8Array(f32.buffer);

let f64 = new Float64Array(1);
let f64_u8 = new Uint8Array(f64.buffer);

function intToLong(value: number): Long {
  value |= 0;
  return {
    low: value,
    high: value >> 31,
    unsigned: value >= 0,
  };
}

let bbStack: ByteBuffer[] = [];

function popByteBuffer(): ByteBuffer {
  const bb = bbStack.pop();
  if (!bb) return { bytes: new Uint8Array(64), offset: 0, limit: 0 };
  bb.offset = bb.limit = 0;
  return bb;
}

function pushByteBuffer(bb: ByteBuffer): void {
  bbStack.push(bb);
}

function wrapByteBuffer(bytes: Uint8Array): ByteBuffer {
  return { bytes, offset: 0, limit: bytes.length };
}

function toUint8Array(bb: ByteBuffer): Uint8Array {
  let bytes = bb.bytes;
  let limit = bb.limit;
  return bytes.length === limit ? bytes : bytes.subarray(0, limit);
}

function skip(bb: ByteBuffer, offset: number): void {
  if (bb.offset + offset > bb.limit) {
    throw new Error('Skip past limit');
  }
  bb.offset += offset;
}

function isAtEnd(bb: ByteBuffer): boolean {
  return bb.offset >= bb.limit;
}

function grow(bb: ByteBuffer, count: number): number {
  let bytes = bb.bytes;
  let offset = bb.offset;
  let limit = bb.limit;
  let finalOffset = offset + count;
  if (finalOffset > bytes.length) {
    let newBytes = new Uint8Array(finalOffset * 2);
    newBytes.set(bytes);
    bb.bytes = newBytes;
  }
  bb.offset = finalOffset;
  if (finalOffset > limit) {
    bb.limit = finalOffset;
  }
  return offset;
}

function advance(bb: ByteBuffer, count: number): number {
  let offset = bb.offset;
  if (offset + count > bb.limit) {
    throw new Error('Read past limit');
  }
  bb.offset += count;
  return offset;
}

function readBytes(bb: ByteBuffer, count: number): Uint8Array {
  let offset = advance(bb, count);
  return bb.bytes.subarray(offset, offset + count);
}

function writeBytes(bb: ByteBuffer, buffer: Uint8Array): void {
  let offset = grow(bb, buffer.length);
  bb.bytes.set(buffer, offset);
}

function readString(bb: ByteBuffer, count: number): string {
  // Sadly a hand-coded UTF8 decoder is much faster than subarray+TextDecoder in V8
  let offset = advance(bb, count);
  let fromCharCode = String.fromCharCode;
  let bytes = bb.bytes;
  let invalid = '\uFFFD';
  let text = '';

  for (let i = 0; i < count; i++) {
    let c1 = bytes[i + offset], c2: number, c3: number, c4: number, c: number;

    // 1 byte
    if ((c1 & 0x80) === 0) {
      text += fromCharCode(c1);
    }

    // 2 bytes
    else if ((c1 & 0xE0) === 0xC0) {
      if (i + 1 >= count) text += invalid;
      else {
        c2 = bytes[i + offset + 1];
        if ((c2 & 0xC0) !== 0x80) text += invalid;
        else {
          c = ((c1 & 0x1F) << 6) | (c2 & 0x3F);
          if (c < 0x80) text += invalid;
          else {
            text += fromCharCode(c);
            i++;
          }
        }
      }
    }

    // 3 bytes
    else if ((c1 & 0xF0) == 0xE0) {
      if (i + 2 >= count) text += invalid;
      else {
        c2 = bytes[i + offset + 1];
        c3 = bytes[i + offset + 2];
        if (((c2 | (c3 << 8)) & 0xC0C0) !== 0x8080) text += invalid;
        else {
          c = ((c1 & 0x0F) << 12) | ((c2 & 0x3F) << 6) | (c3 & 0x3F);
          if (c < 0x0800 || (c >= 0xD800 && c <= 0xDFFF)) text += invalid;
          else {
            text += fromCharCode(c);
            i += 2;
          }
        }
      }
    }

    // 4 bytes
    else if ((c1 & 0xF8) == 0xF0) {
      if (i + 3 >= count) text += invalid;
      else {
        c2 = bytes[i + offset + 1];
        c3 = bytes[i + offset + 2];
        c4 = bytes[i + offset + 3];
        if (((c2 | (c3 << 8) | (c4 << 16)) & 0xC0C0C0) !== 0x808080) text += invalid;
        else {
          c = ((c1 & 0x07) << 0x12) | ((c2 & 0x3F) << 0x0C) | ((c3 & 0x3F) << 0x06) | (c4 & 0x3F);
          if (c < 0x10000 || c > 0x10FFFF) text += invalid;
          else {
            c -= 0x10000;
            text += fromCharCode((c >> 10) + 0xD800, (c & 0x3FF) + 0xDC00);
            i += 3;
          }
        }
      }
    }

    else text += invalid;
  }

  return text;
}

function writeString(bb: ByteBuffer, text: string): void {
  // Sadly a hand-coded UTF8 encoder is much faster than TextEncoder+set in V8
  let n = text.length;
  let byteCount = 0;

  // Write the byte count first
  for (let i = 0; i < n; i++) {
    let c = text.charCodeAt(i);
    if (c >= 0xD800 && c <= 0xDBFF && i + 1 < n) {
      c = (c << 10) + text.charCodeAt(++i) - 0x35FDC00;
    }
    byteCount += c < 0x80 ? 1 : c < 0x800 ? 2 : c < 0x10000 ? 3 : 4;
  }
  writeVarint32(bb, byteCount);

  let offset = grow(bb, byteCount);
  let bytes = bb.bytes;

  // Then write the bytes
  for (let i = 0; i < n; i++) {
    let c = text.charCodeAt(i);
    if (c >= 0xD800 && c <= 0xDBFF && i + 1 < n) {
      c = (c << 10) + text.charCodeAt(++i) - 0x35FDC00;
    }
    if (c < 0x80) {
      bytes[offset++] = c;
    } else {
      if (c < 0x800) {
        bytes[offset++] = ((c >> 6) & 0x1F) | 0xC0;
      } else {
        if (c < 0x10000) {
          bytes[offset++] = ((c >> 12) & 0x0F) | 0xE0;
        } else {
          bytes[offset++] = ((c >> 18) & 0x07) | 0xF0;
          bytes[offset++] = ((c >> 12) & 0x3F) | 0x80;
        }
        bytes[offset++] = ((c >> 6) & 0x3F) | 0x80;
      }
      bytes[offset++] = (c & 0x3F) | 0x80;
    }
  }
}

function writeByteBuffer(bb: ByteBuffer, buffer: ByteBuffer): void {
  let offset = grow(bb, buffer.limit);
  let from = bb.bytes;
  let to = buffer.bytes;

  // This for loop is much faster than subarray+set on V8
  for (let i = 0, n = buffer.limit; i < n; i++) {
    from[i + offset] = to[i];
  }
}

function readByte(bb: ByteBuffer): number {
  return bb.bytes[advance(bb, 1)];
}

function writeByte(bb: ByteBuffer, value: number): void {
  let offset = grow(bb, 1);
  bb.bytes[offset] = value;
}

function readFloat(bb: ByteBuffer): number {
  let offset = advance(bb, 4);
  let bytes = bb.bytes;

  // Manual copying is much faster than subarray+set in V8
  f32_u8[0] = bytes[offset++];
  f32_u8[1] = bytes[offset++];
  f32_u8[2] = bytes[offset++];
  f32_u8[3] = bytes[offset++];
  return f32[0];
}

function writeFloat(bb: ByteBuffer, value: number): void {
  let offset = grow(bb, 4);
  let bytes = bb.bytes;
  f32[0] = value;

  // Manual copying is much faster than subarray+set in V8
  bytes[offset++] = f32_u8[0];
  bytes[offset++] = f32_u8[1];
  bytes[offset++] = f32_u8[2];
  bytes[offset++] = f32_u8[3];
}

function readDouble(bb: ByteBuffer): number {
  let offset = advance(bb, 8);
  let bytes = bb.bytes;

  // Manual copying is much faster than subarray+set in V8
  f64_u8[0] = bytes[offset++];
  f64_u8[1] = bytes[offset++];
  f64_u8[2] = bytes[offset++];
  f64_u8[3] = bytes[offset++];
  f64_u8[4] = bytes[offset++];
  f64_u8[5] = bytes[offset++];
  f64_u8[6] = bytes[offset++];
  f64_u8[7] = bytes[offset++];
  return f64[0];
}

function writeDouble(bb: ByteBuffer, value: number): void {
  let offset = grow(bb, 8);
  let bytes = bb.bytes;
  f64[0] = value;

  // Manual copying is much faster than subarray+set in V8
  bytes[offset++] = f64_u8[0];
  bytes[offset++] = f64_u8[1];
  bytes[offset++] = f64_u8[2];
  bytes[offset++] = f64_u8[3];
  bytes[offset++] = f64_u8[4];
  bytes[offset++] = f64_u8[5];
  bytes[offset++] = f64_u8[6];
  bytes[offset++] = f64_u8[7];
}

function readInt32(bb: ByteBuffer): number {
  let offset = advance(bb, 4);
  let bytes = bb.bytes;
  return (
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24)
  );
}

function writeInt32(bb: ByteBuffer, value: number): void {
  let offset = grow(bb, 4);
  let bytes = bb.bytes;
  bytes[offset] = value;
  bytes[offset + 1] = value >> 8;
  bytes[offset + 2] = value >> 16;
  bytes[offset + 3] = value >> 24;
}

function readInt64(bb: ByteBuffer, unsigned: boolean): Long {
  return {
    low: readInt32(bb),
    high: readInt32(bb),
    unsigned,
  };
}

function writeInt64(bb: ByteBuffer, value: Long): void {
  writeInt32(bb, value.low);
  writeInt32(bb, value.high);
}

function readVarint32(bb: ByteBuffer): number {
  let c = 0;
  let value = 0;
  let b: number;
  do {
    b = readByte(bb);
    if (c < 32) value |= (b & 0x7F) << c;
    c += 7;
  } while (b & 0x80);
  return value;
}

function writeVarint32(bb: ByteBuffer, value: number): void {
  value >>>= 0;
  while (value >= 0x80) {
    writeByte(bb, (value & 0x7f) | 0x80);
    value >>>= 7;
  }
  writeByte(bb, value);
}

function readVarint64(bb: ByteBuffer, unsigned: boolean): Long {
  let part0 = 0;
  let part1 = 0;
  let part2 = 0;
  let b: number;

  b = readByte(bb); part0 = (b & 0x7F); if (b & 0x80) {
    b = readByte(bb); part0 |= (b & 0x7F) << 7; if (b & 0x80) {
      b = readByte(bb); part0 |= (b & 0x7F) << 14; if (b & 0x80) {
        b = readByte(bb); part0 |= (b & 0x7F) << 21; if (b & 0x80) {

          b = readByte(bb); part1 = (b & 0x7F); if (b & 0x80) {
            b = readByte(bb); part1 |= (b & 0x7F) << 7; if (b & 0x80) {
              b = readByte(bb); part1 |= (b & 0x7F) << 14; if (b & 0x80) {
                b = readByte(bb); part1 |= (b & 0x7F) << 21; if (b & 0x80) {

                  b = readByte(bb); part2 = (b & 0x7F); if (b & 0x80) {
                    b = readByte(bb); part2 |= (b & 0x7F) << 7;
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  return {
    low: part0 | (part1 << 28),
    high: (part1 >>> 4) | (part2 << 24),
    unsigned,
  };
}

function writeVarint64(bb: ByteBuffer, value: Long): void {
  let part0 = value.low >>> 0;
  let part1 = ((value.low >>> 28) | (value.high << 4)) >>> 0;
  let part2 = value.high >>> 24;

  // ref: src/google/protobuf/io/coded_stream.cc
  let size =
    part2 === 0 ?
      part1 === 0 ?
        part0 < 1 << 14 ?
          part0 < 1 << 7 ? 1 : 2 :
          part0 < 1 << 21 ? 3 : 4 :
        part1 < 1 << 14 ?
          part1 < 1 << 7 ? 5 : 6 :
          part1 < 1 << 21 ? 7 : 8 :
      part2 < 1 << 7 ? 9 : 10;

  let offset = grow(bb, size);
  let bytes = bb.bytes;

  switch (size) {
    case 10: bytes[offset + 9] = (part2 >>> 7) & 0x01;
    case 9: bytes[offset + 8] = size !== 9 ? part2 | 0x80 : part2 & 0x7F;
    case 8: bytes[offset + 7] = size !== 8 ? (part1 >>> 21) | 0x80 : (part1 >>> 21) & 0x7F;
    case 7: bytes[offset + 6] = size !== 7 ? (part1 >>> 14) | 0x80 : (part1 >>> 14) & 0x7F;
    case 6: bytes[offset + 5] = size !== 6 ? (part1 >>> 7) | 0x80 : (part1 >>> 7) & 0x7F;
    case 5: bytes[offset + 4] = size !== 5 ? part1 | 0x80 : part1 & 0x7F;
    case 4: bytes[offset + 3] = size !== 4 ? (part0 >>> 21) | 0x80 : (part0 >>> 21) & 0x7F;
    case 3: bytes[offset + 2] = size !== 3 ? (part0 >>> 14) | 0x80 : (part0 >>> 14) & 0x7F;
    case 2: bytes[offset + 1] = size !== 2 ? (part0 >>> 7) | 0x80 : (part0 >>> 7) & 0x7F;
    case 1: bytes[offset] = size !== 1 ? part0 | 0x80 : part0 & 0x7F;
  }
}

function readVarint32ZigZag(bb: ByteBuffer): number {
  let value = readVarint32(bb);

  // ref: src/google/protobuf/wire_format_lite.h
  return (value >>> 1) ^ -(value & 1);
}

function writeVarint32ZigZag(bb: ByteBuffer, value: number): void {
  // ref: src/google/protobuf/wire_format_lite.h
  writeVarint32(bb, (value << 1) ^ (value >> 31));
}

function readVarint64ZigZag(bb: ByteBuffer): Long {
  let value = readVarint64(bb, /* unsigned */ false);
  let low = value.low;
  let high = value.high;
  let flip = -(low & 1);

  // ref: src/google/protobuf/wire_format_lite.h
  return {
    low: ((low >>> 1) | (high << 31)) ^ flip,
    high: (high >>> 1) ^ flip,
    unsigned: false,
  };
}

function writeVarint64ZigZag(bb: ByteBuffer, value: Long): void {
  let low = value.low;
  let high = value.high;
  let flip = high >> 31;

  // ref: src/google/protobuf/wire_format_lite.h
  writeVarint64(bb, {
    low: (low << 1) ^ flip,
    high: ((high << 1) | (low >>> 31)) ^ flip,
    unsigned: false,
  });
}
