export const encodeBleSignalSet = {
  BLE_SET_A: 0,
  BLE_SET_B: 1,
};

export const decodeBleSignalSet = {
  0: "BLE_SET_A",
  1: "BLE_SET_B",
};

export const encodeBleAnalogReadState = {
  BLE_READ_IDLE: 0,
  BLE_READING: 1,
  BLE_READ_DISABLED: 2,
};

export const decodeBleAnalogReadState = {
  0: "BLE_READ_IDLE",
  1: "BLE_READING",
  2: "BLE_READ_DISABLED",
};

export const encodeBleSignalState = {
  BLE_SIG_IDLE: 0,
  BLE_SIG_RUNNING: 1,
};

export const decodeBleSignalState = {
  0: "BLE_SIG_IDLE",
  1: "BLE_SIG_RUNNING",
};

export const encodeBleControlState = {
  BLE_CTRL_OFF: 0,
  BLE_CTRL_ON: 1,
};

export const decodeBleControlState = {
  0: "BLE_CTRL_OFF",
  1: "BLE_CTRL_ON",
};

export const encodeBleLedMode = {
  LED_NORMAL: 0,
  LED_BLINKING: 1,
};

export const decodeBleLedMode = {
  0: "LED_NORMAL",
  1: "LED_BLINKING",
};

export const encodeBleLogLevel = {
  BLE_LOG_INFO: 0,
  BLE_LOG_WARN: 1,
  BLE_LOG_ERROR: 2,
};

export const decodeBleLogLevel = {
  0: "BLE_LOG_INFO",
  1: "BLE_LOG_WARN",
  2: "BLE_LOG_ERROR",
};

export const encodeOtaState = {
  OTA_IDLE: 0,
  OTA_DOWNLOADING: 1,
  OTA_VERIFYING: 2,
  OTA_FINISHED: 3,
  OTA_ERROR: 4,
};

export const decodeOtaState = {
  0: "OTA_IDLE",
  1: "OTA_DOWNLOADING",
  2: "OTA_VERIFYING",
  3: "OTA_FINISHED",
  4: "OTA_ERROR",
};

export function encodeTelemetry(message) {
  let bb = popByteBuffer();
  _encodeTelemetry(message, bb);
  return toUint8Array(bb);
}

function _encodeTelemetry(message, bb) {
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

export function decodeTelemetry(binary) {
  return _decodeTelemetry(wrapByteBuffer(binary));
}

function _decodeTelemetry(bb) {
  let message = {};

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

export function encodeSystemStatus(message) {
  let bb = popByteBuffer();
  _encodeSystemStatus(message, bb);
  return toUint8Array(bb);
}

function _encodeSystemStatus(message, bb) {
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

  // optional bool ble_congested = 15;
  let $ble_congested = message.ble_congested;
  if ($ble_congested !== undefined) {
    writeVarint32(bb, 120);
    writeByte(bb, $ble_congested ? 1 : 0);
  }

  // optional uint32 adc_min = 16;
  let $adc_min = message.adc_min;
  if ($adc_min !== undefined) {
    writeVarint32(bb, 128);
    writeVarint32(bb, $adc_min);
  }

  // optional uint32 adc_max = 17;
  let $adc_max = message.adc_max;
  if ($adc_max !== undefined) {
    writeVarint32(bb, 136);
    writeVarint32(bb, $adc_max);
  }

  // optional uint32 adc_avg = 18;
  let $adc_avg = message.adc_avg;
  if ($adc_avg !== undefined) {
    writeVarint32(bb, 144);
    writeVarint32(bb, $adc_avg);
  }
}

export function decodeSystemStatus(binary) {
  return _decodeSystemStatus(wrapByteBuffer(binary));
}

function _decodeSystemStatus(bb) {
  let message = {};

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

      // optional bool ble_congested = 15;
      case 15: {
        message.ble_congested = !!readByte(bb);
        break;
      }

      // optional uint32 adc_min = 16;
      case 16: {
        message.adc_min = readVarint32(bb) >>> 0;
        break;
      }

      // optional uint32 adc_max = 17;
      case 17: {
        message.adc_max = readVarint32(bb) >>> 0;
        break;
      }

      // optional uint32 adc_avg = 18;
      case 18: {
        message.adc_avg = readVarint32(bb) >>> 0;
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeLogMessage(message) {
  let bb = popByteBuffer();
  _encodeLogMessage(message, bb);
  return toUint8Array(bb);
}

function _encodeLogMessage(message, bb) {
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

export function decodeLogMessage(binary) {
  return _decodeLogMessage(wrapByteBuffer(binary));
}

function _decodeLogMessage(bb) {
  let message = {};

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

export function encodeOtaStatus(message) {
  let bb = popByteBuffer();
  _encodeOtaStatus(message, bb);
  return toUint8Array(bb);
}

function _encodeOtaStatus(message, bb) {
  // optional OtaState state = 1;
  let $state = message.state;
  if ($state !== undefined) {
    writeVarint32(bb, 8);
    writeVarint32(bb, encodeOtaState[$state]);
  }

  // optional uint32 progress_percent = 2;
  let $progress_percent = message.progress_percent;
  if ($progress_percent !== undefined) {
    writeVarint32(bb, 16);
    writeVarint32(bb, $progress_percent);
  }

  // optional string message = 3;
  let $message = message.message;
  if ($message !== undefined) {
    writeVarint32(bb, 26);
    writeString(bb, $message);
  }
}

export function decodeOtaStatus(binary) {
  return _decodeOtaStatus(wrapByteBuffer(binary));
}

function _decodeOtaStatus(bb) {
  let message = {};

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional OtaState state = 1;
      case 1: {
        message.state = decodeOtaState[readVarint32(bb)];
        break;
      }

      // optional uint32 progress_percent = 2;
      case 2: {
        message.progress_percent = readVarint32(bb) >>> 0;
        break;
      }

      // optional string message = 3;
      case 3: {
        message.message = readString(bb, readVarint32(bb));
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeOtaBegin(message) {
  let bb = popByteBuffer();
  _encodeOtaBegin(message, bb);
  return toUint8Array(bb);
}

function _encodeOtaBegin(message, bb) {
  // optional uint32 file_size = 1;
  let $file_size = message.file_size;
  if ($file_size !== undefined) {
    writeVarint32(bb, 8);
    writeVarint32(bb, $file_size);
  }
}

export function decodeOtaBegin(binary) {
  return _decodeOtaBegin(wrapByteBuffer(binary));
}

function _decodeOtaBegin(bb) {
  let message = {};

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional uint32 file_size = 1;
      case 1: {
        message.file_size = readVarint32(bb) >>> 0;
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeOtaChunk(message) {
  let bb = popByteBuffer();
  _encodeOtaChunk(message, bb);
  return toUint8Array(bb);
}

function _encodeOtaChunk(message, bb) {
  // optional uint32 seq = 1;
  let $seq = message.seq;
  if ($seq !== undefined) {
    writeVarint32(bb, 8);
    writeVarint32(bb, $seq);
  }

  // optional bytes data = 2;
  let $data = message.data;
  if ($data !== undefined) {
    writeVarint32(bb, 18);
    writeVarint32(bb, $data.length), writeBytes(bb, $data);
  }
}

export function decodeOtaChunk(binary) {
  return _decodeOtaChunk(wrapByteBuffer(binary));
}

function _decodeOtaChunk(bb) {
  let message = {};

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional uint32 seq = 1;
      case 1: {
        message.seq = readVarint32(bb) >>> 0;
        break;
      }

      // optional bytes data = 2;
      case 2: {
        message.data = readBytes(bb, readVarint32(bb));
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeOtaEnd(message) {
  let bb = popByteBuffer();
  _encodeOtaEnd(message, bb);
  return toUint8Array(bb);
}

function _encodeOtaEnd(message, bb) {
  // optional string sha256 = 1;
  let $sha256 = message.sha256;
  if ($sha256 !== undefined) {
    writeVarint32(bb, 10);
    writeString(bb, $sha256);
  }
}

export function decodeOtaEnd(binary) {
  return _decodeOtaEnd(wrapByteBuffer(binary));
}

function _decodeOtaEnd(bb) {
  let message = {};

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional string sha256 = 1;
      case 1: {
        message.sha256 = readString(bb, readVarint32(bb));
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeOtaCommand(message) {
  let bb = popByteBuffer();
  _encodeOtaCommand(message, bb);
  return toUint8Array(bb);
}

function _encodeOtaCommand(message, bb) {
  // optional OtaBegin begin = 1;
  let $begin = message.begin;
  if ($begin !== undefined) {
    writeVarint32(bb, 10);
    let nested = popByteBuffer();
    _encodeOtaBegin($begin, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }

  // optional OtaChunk chunk = 2;
  let $chunk = message.chunk;
  if ($chunk !== undefined) {
    writeVarint32(bb, 18);
    let nested = popByteBuffer();
    _encodeOtaChunk($chunk, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }

  // optional OtaEnd end = 3;
  let $end = message.end;
  if ($end !== undefined) {
    writeVarint32(bb, 26);
    let nested = popByteBuffer();
    _encodeOtaEnd($end, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }

  // optional bool abort = 4;
  let $abort = message.abort;
  if ($abort !== undefined) {
    writeVarint32(bb, 32);
    writeByte(bb, $abort ? 1 : 0);
  }
}

export function decodeOtaCommand(binary) {
  return _decodeOtaCommand(wrapByteBuffer(binary));
}

function _decodeOtaCommand(bb) {
  let message = {};

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional OtaBegin begin = 1;
      case 1: {
        let limit = pushTemporaryLength(bb);
        message.begin = _decodeOtaBegin(bb);
        bb.limit = limit;
        break;
      }

      // optional OtaChunk chunk = 2;
      case 2: {
        let limit = pushTemporaryLength(bb);
        message.chunk = _decodeOtaChunk(bb);
        bb.limit = limit;
        break;
      }

      // optional OtaEnd end = 3;
      case 3: {
        let limit = pushTemporaryLength(bb);
        message.end = _decodeOtaEnd(bb);
        bb.limit = limit;
        break;
      }

      // optional bool abort = 4;
      case 4: {
        message.abort = !!readByte(bb);
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeUiCommand(message) {
  let bb = popByteBuffer();
  _encodeUiCommand(message, bb);
  return toUint8Array(bb);
}

function _encodeUiCommand(message, bb) {
  // optional string name = 1;
  let $name = message.name;
  if ($name !== undefined) {
    writeVarint32(bb, 10);
    writeString(bb, $name);
  }

  // optional string json = 2;
  let $json = message.json;
  if ($json !== undefined) {
    writeVarint32(bb, 18);
    writeString(bb, $json);
  }

  // optional uint32 request_id = 3;
  let $request_id = message.request_id;
  if ($request_id !== undefined) {
    writeVarint32(bb, 24);
    writeVarint32(bb, $request_id);
  }
}

export function decodeUiCommand(binary) {
  return _decodeUiCommand(wrapByteBuffer(binary));
}

function _decodeUiCommand(bb) {
  let message = {};

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional string name = 1;
      case 1: {
        message.name = readString(bb, readVarint32(bb));
        break;
      }

      // optional string json = 2;
      case 2: {
        message.json = readString(bb, readVarint32(bb));
        break;
      }

      // optional uint32 request_id = 3;
      case 3: {
        message.request_id = readVarint32(bb) >>> 0;
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeUiCommandResult(message) {
  let bb = popByteBuffer();
  _encodeUiCommandResult(message, bb);
  return toUint8Array(bb);
}

function _encodeUiCommandResult(message, bb) {
  // optional uint32 request_id = 1;
  let $request_id = message.request_id;
  if ($request_id !== undefined) {
    writeVarint32(bb, 8);
    writeVarint32(bb, $request_id);
  }

  // optional string name = 2;
  let $name = message.name;
  if ($name !== undefined) {
    writeVarint32(bb, 18);
    writeString(bb, $name);
  }

  // optional bool ok = 3;
  let $ok = message.ok;
  if ($ok !== undefined) {
    writeVarint32(bb, 24);
    writeByte(bb, $ok ? 1 : 0);
  }

  // optional string code = 4;
  let $code = message.code;
  if ($code !== undefined) {
    writeVarint32(bb, 34);
    writeString(bb, $code);
  }

  // optional string message = 5;
  let $message = message.message;
  if ($message !== undefined) {
    writeVarint32(bb, 42);
    writeString(bb, $message);
  }

  // optional string json = 6;
  let $json = message.json;
  if ($json !== undefined) {
    writeVarint32(bb, 50);
    writeString(bb, $json);
  }
}

export function decodeUiCommandResult(binary) {
  return _decodeUiCommandResult(wrapByteBuffer(binary));
}

function _decodeUiCommandResult(bb) {
  let message = {};

  end_of_message: while (!isAtEnd(bb)) {
    let tag = readVarint32(bb);

    switch (tag >>> 3) {
      case 0:
        break end_of_message;

      // optional uint32 request_id = 1;
      case 1: {
        message.request_id = readVarint32(bb) >>> 0;
        break;
      }

      // optional string name = 2;
      case 2: {
        message.name = readString(bb, readVarint32(bb));
        break;
      }

      // optional bool ok = 3;
      case 3: {
        message.ok = !!readByte(bb);
        break;
      }

      // optional string code = 4;
      case 4: {
        message.code = readString(bb, readVarint32(bb));
        break;
      }

      // optional string message = 5;
      case 5: {
        message.message = readString(bb, readVarint32(bb));
        break;
      }

      // optional string json = 6;
      case 6: {
        message.json = readString(bb, readVarint32(bb));
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

export function encodeBlePacket(message) {
  let bb = popByteBuffer();
  _encodeBlePacket(message, bb);
  return toUint8Array(bb);
}

function _encodeBlePacket(message, bb) {
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

  // optional OtaStatus ota_status = 4;
  let $ota_status = message.ota_status;
  if ($ota_status !== undefined) {
    writeVarint32(bb, 34);
    let nested = popByteBuffer();
    _encodeOtaStatus($ota_status, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }

  // optional UiCommandResult command_result = 5;
  let $command_result = message.command_result;
  if ($command_result !== undefined) {
    writeVarint32(bb, 42);
    let nested = popByteBuffer();
    _encodeUiCommandResult($command_result, nested);
    writeVarint32(bb, nested.limit);
    writeByteBuffer(bb, nested);
    pushByteBuffer(nested);
  }
}

export function decodeBlePacket(binary) {
  return _decodeBlePacket(wrapByteBuffer(binary));
}

function _decodeBlePacket(bb) {
  let message = {};

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

      // optional OtaStatus ota_status = 4;
      case 4: {
        let limit = pushTemporaryLength(bb);
        message.ota_status = _decodeOtaStatus(bb);
        bb.limit = limit;
        break;
      }

      // optional UiCommandResult command_result = 5;
      case 5: {
        let limit = pushTemporaryLength(bb);
        message.command_result = _decodeUiCommandResult(bb);
        bb.limit = limit;
        break;
      }

      default:
        skipUnknownField(bb, tag & 7);
    }
  }

  return message;
}

function pushTemporaryLength(bb) {
  let length = readVarint32(bb);
  let limit = bb.limit;
  bb.limit = bb.offset + length;
  return limit;
}

function skipUnknownField(bb, type) {
  switch (type) {
    case 0: while (readByte(bb) & 0x80) { } break;
    case 2: skip(bb, readVarint32(bb)); break;
    case 5: skip(bb, 4); break;
    case 1: skip(bb, 8); break;
    default: throw new Error("Unimplemented type: " + type);
  }
}

function stringToLong(value) {
  return {
    low: value.charCodeAt(0) | (value.charCodeAt(1) << 16),
    high: value.charCodeAt(2) | (value.charCodeAt(3) << 16),
    unsigned: false,
  };
}

function longToString(value) {
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

function intToLong(value) {
  value |= 0;
  return {
    low: value,
    high: value >> 31,
    unsigned: value >= 0,
  };
}

let bbStack = [];

function popByteBuffer() {
  const bb = bbStack.pop();
  if (!bb) return { bytes: new Uint8Array(64), offset: 0, limit: 0 };
  bb.offset = bb.limit = 0;
  return bb;
}

function pushByteBuffer(bb) {
  bbStack.push(bb);
}

function wrapByteBuffer(bytes) {
  return { bytes, offset: 0, limit: bytes.length };
}

function toUint8Array(bb) {
  let bytes = bb.bytes;
  let limit = bb.limit;
  return bytes.length === limit ? bytes : bytes.subarray(0, limit);
}

function skip(bb, offset) {
  if (bb.offset + offset > bb.limit) {
    throw new Error('Skip past limit');
  }
  bb.offset += offset;
}

function isAtEnd(bb) {
  return bb.offset >= bb.limit;
}

function grow(bb, count) {
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

function advance(bb, count) {
  let offset = bb.offset;
  if (offset + count > bb.limit) {
    throw new Error('Read past limit');
  }
  bb.offset += count;
  return offset;
}

function readBytes(bb, count) {
  let offset = advance(bb, count);
  return bb.bytes.subarray(offset, offset + count);
}

function writeBytes(bb, buffer) {
  let offset = grow(bb, buffer.length);
  bb.bytes.set(buffer, offset);
}

function readString(bb, count) {
  // Sadly a hand-coded UTF8 decoder is much faster than subarray+TextDecoder in V8
  let offset = advance(bb, count);
  let fromCharCode = String.fromCharCode;
  let bytes = bb.bytes;
  let invalid = '\uFFFD';
  let text = '';

  for (let i = 0; i < count; i++) {
    let c1 = bytes[i + offset], c2, c3, c4, c;

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

function writeString(bb, text) {
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

function writeByteBuffer(bb, buffer) {
  let offset = grow(bb, buffer.limit);
  let from = bb.bytes;
  let to = buffer.bytes;

  // This for loop is much faster than subarray+set on V8
  for (let i = 0, n = buffer.limit; i < n; i++) {
    from[i + offset] = to[i];
  }
}

function readByte(bb) {
  return bb.bytes[advance(bb, 1)];
}

function writeByte(bb, value) {
  let offset = grow(bb, 1);
  bb.bytes[offset] = value;
}

function readFloat(bb) {
  let offset = advance(bb, 4);
  let bytes = bb.bytes;

  // Manual copying is much faster than subarray+set in V8
  f32_u8[0] = bytes[offset++];
  f32_u8[1] = bytes[offset++];
  f32_u8[2] = bytes[offset++];
  f32_u8[3] = bytes[offset++];
  return f32[0];
}

function writeFloat(bb, value) {
  let offset = grow(bb, 4);
  let bytes = bb.bytes;
  f32[0] = value;

  // Manual copying is much faster than subarray+set in V8
  bytes[offset++] = f32_u8[0];
  bytes[offset++] = f32_u8[1];
  bytes[offset++] = f32_u8[2];
  bytes[offset++] = f32_u8[3];
}

function readDouble(bb) {
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

function writeDouble(bb, value) {
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

function readInt32(bb) {
  let offset = advance(bb, 4);
  let bytes = bb.bytes;
  return (
    bytes[offset] |
    (bytes[offset + 1] << 8) |
    (bytes[offset + 2] << 16) |
    (bytes[offset + 3] << 24)
  );
}

function writeInt32(bb, value) {
  let offset = grow(bb, 4);
  let bytes = bb.bytes;
  bytes[offset] = value;
  bytes[offset + 1] = value >> 8;
  bytes[offset + 2] = value >> 16;
  bytes[offset + 3] = value >> 24;
}

function readInt64(bb, unsigned) {
  return {
    low: readInt32(bb),
    high: readInt32(bb),
    unsigned,
  };
}

function writeInt64(bb, value) {
  writeInt32(bb, value.low);
  writeInt32(bb, value.high);
}

function readVarint32(bb) {
  let c = 0;
  let value = 0;
  let b;
  do {
    b = readByte(bb);
    if (c < 32) value |= (b & 0x7F) << c;
    c += 7;
  } while (b & 0x80);
  return value;
}

function writeVarint32(bb, value) {
  value >>>= 0;
  while (value >= 0x80) {
    writeByte(bb, (value & 0x7f) | 0x80);
    value >>>= 7;
  }
  writeByte(bb, value);
}

function readVarint64(bb, unsigned) {
  let part0 = 0;
  let part1 = 0;
  let part2 = 0;
  let b;

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

function writeVarint64(bb, value) {
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

function readVarint32ZigZag(bb) {
  let value = readVarint32(bb);

  // ref: src/google/protobuf/wire_format_lite.h
  return (value >>> 1) ^ -(value & 1);
}

function writeVarint32ZigZag(bb, value) {
  // ref: src/google/protobuf/wire_format_lite.h
  writeVarint32(bb, (value << 1) ^ (value >> 31));
}

function readVarint64ZigZag(bb) {
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

function writeVarint64ZigZag(bb, value) {
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
