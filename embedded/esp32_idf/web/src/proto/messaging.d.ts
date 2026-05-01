import * as $protobuf from "protobufjs";
import Long = require("long");
/** BleSignalSet enum. */
export enum BleSignalSet {
    BLE_SET_A = 0,
    BLE_SET_B = 1
}

/** BleAnalogReadState enum. */
export enum BleAnalogReadState {
    BLE_READ_IDLE = 0,
    BLE_READING = 1,
    BLE_READ_DISABLED = 2
}

/** BleSignalState enum. */
export enum BleSignalState {
    BLE_SIG_IDLE = 0,
    BLE_SIG_RUNNING = 1
}

/** BleControlState enum. */
export enum BleControlState {
    BLE_CTRL_OFF = 0,
    BLE_CTRL_ON = 1
}

/** BleLedMode enum. */
export enum BleLedMode {
    LED_NORMAL = 0,
    LED_BLINKING = 1
}

/** BleLogLevel enum. */
export enum BleLogLevel {
    BLE_LOG_INFO = 0,
    BLE_LOG_WARN = 1,
    BLE_LOG_ERROR = 2
}

/** Represents a Telemetry. */
export class Telemetry implements ITelemetry {

    /**
     * Constructs a new Telemetry.
     * @param [properties] Properties to set
     */
    constructor(properties?: ITelemetry);

    /** Telemetry an3. */
    public an3: number;

    /** Telemetry an5. */
    public an5: number;

    /** Telemetry an6. */
    public an6: number;

    /** Telemetry timestampMs. */
    public timestampMs: number;

    /**
     * Creates a new Telemetry instance using the specified properties.
     * @param [properties] Properties to set
     * @returns Telemetry instance
     */
    public static create(properties?: ITelemetry): Telemetry;

    /**
     * Encodes the specified Telemetry message. Does not implicitly {@link Telemetry.verify|verify} messages.
     * @param message Telemetry message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ITelemetry, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified Telemetry message, length delimited. Does not implicitly {@link Telemetry.verify|verify} messages.
     * @param message Telemetry message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ITelemetry, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a Telemetry message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns Telemetry
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): Telemetry;

    /**
     * Decodes a Telemetry message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns Telemetry
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): Telemetry;

    /**
     * Verifies a Telemetry message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a Telemetry message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns Telemetry
     */
    public static fromObject(object: { [k: string]: any }): Telemetry;

    /**
     * Creates a plain object from a Telemetry message. Also converts values to other types if specified.
     * @param message Telemetry
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: Telemetry, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this Telemetry to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for Telemetry
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a SystemStatus. */
export class SystemStatus implements ISystemStatus {

    /**
     * Constructs a new SystemStatus.
     * @param [properties] Properties to set
     */
    constructor(properties?: ISystemStatus);

    /** SystemStatus activeSet. */
    public activeSet: BleSignalSet;

    /** SystemStatus signalState. */
    public signalState: BleSignalState;

    /** SystemStatus bleReadState. */
    public bleReadState: BleAnalogReadState;

    /** SystemStatus controlState. */
    public controlState: BleControlState;

    /** SystemStatus alpha. */
    public alpha: number;

    /** SystemStatus hasAlpha. */
    public hasAlpha: boolean;

    /** SystemStatus matrixAValid. */
    public matrixAValid: boolean;

    /** SystemStatus matrixBValid. */
    public matrixBValid: boolean;

    /** SystemStatus currentCycles. */
    public currentCycles: number;

    /** SystemStatus totalCycles. */
    public totalCycles: number;

    /** SystemStatus monitorMs. */
    public monitorMs: number;

    /** SystemStatus usCyclesUp. */
    public usCyclesUp: number;

    /** SystemStatus usCyclesDown. */
    public usCyclesDown: number;

    /** SystemStatus ledMode. */
    public ledMode: BleLedMode;

    /** SystemStatus bleCongested. */
    public bleCongested: boolean;

    /** SystemStatus adcMin. */
    public adcMin: number;

    /** SystemStatus adcMax. */
    public adcMax: number;

    /** SystemStatus adcAvg. */
    public adcAvg: number;

    /**
     * Creates a new SystemStatus instance using the specified properties.
     * @param [properties] Properties to set
     * @returns SystemStatus instance
     */
    public static create(properties?: ISystemStatus): SystemStatus;

    /**
     * Encodes the specified SystemStatus message. Does not implicitly {@link SystemStatus.verify|verify} messages.
     * @param message SystemStatus message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ISystemStatus, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified SystemStatus message, length delimited. Does not implicitly {@link SystemStatus.verify|verify} messages.
     * @param message SystemStatus message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ISystemStatus, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a SystemStatus message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns SystemStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): SystemStatus;

    /**
     * Decodes a SystemStatus message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns SystemStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): SystemStatus;

    /**
     * Verifies a SystemStatus message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a SystemStatus message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns SystemStatus
     */
    public static fromObject(object: { [k: string]: any }): SystemStatus;

    /**
     * Creates a plain object from a SystemStatus message. Also converts values to other types if specified.
     * @param message SystemStatus
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: SystemStatus, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this SystemStatus to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for SystemStatus
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a LogMessage. */
export class LogMessage implements ILogMessage {

    /**
     * Constructs a new LogMessage.
     * @param [properties] Properties to set
     */
    constructor(properties?: ILogMessage);

    /** LogMessage level. */
    public level: BleLogLevel;

    /** LogMessage text. */
    public text: string;

    /**
     * Creates a new LogMessage instance using the specified properties.
     * @param [properties] Properties to set
     * @returns LogMessage instance
     */
    public static create(properties?: ILogMessage): LogMessage;

    /**
     * Encodes the specified LogMessage message. Does not implicitly {@link LogMessage.verify|verify} messages.
     * @param message LogMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: ILogMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified LogMessage message, length delimited. Does not implicitly {@link LogMessage.verify|verify} messages.
     * @param message LogMessage message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: ILogMessage, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a LogMessage message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns LogMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): LogMessage;

    /**
     * Decodes a LogMessage message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns LogMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): LogMessage;

    /**
     * Verifies a LogMessage message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a LogMessage message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns LogMessage
     */
    public static fromObject(object: { [k: string]: any }): LogMessage;

    /**
     * Creates a plain object from a LogMessage message. Also converts values to other types if specified.
     * @param message LogMessage
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: LogMessage, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this LogMessage to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for LogMessage
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** OtaState enum. */
export enum OtaState {
    OTA_IDLE = 0,
    OTA_DOWNLOADING = 1,
    OTA_VERIFYING = 2,
    OTA_FINISHED = 3,
    OTA_ERROR = 4
}

/** Represents an OtaStatus. */
export class OtaStatus implements IOtaStatus {

    /**
     * Constructs a new OtaStatus.
     * @param [properties] Properties to set
     */
    constructor(properties?: IOtaStatus);

    /** OtaStatus state. */
    public state: OtaState;

    /** OtaStatus progressPercent. */
    public progressPercent: number;

    /** OtaStatus message. */
    public message: string;

    /** OtaStatus writtenSize. */
    public writtenSize: number;

    /** OtaStatus expectedSeq. */
    public expectedSeq: number;

    /**
     * Creates a new OtaStatus instance using the specified properties.
     * @param [properties] Properties to set
     * @returns OtaStatus instance
     */
    public static create(properties?: IOtaStatus): OtaStatus;

    /**
     * Encodes the specified OtaStatus message. Does not implicitly {@link OtaStatus.verify|verify} messages.
     * @param message OtaStatus message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IOtaStatus, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified OtaStatus message, length delimited. Does not implicitly {@link OtaStatus.verify|verify} messages.
     * @param message OtaStatus message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IOtaStatus, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an OtaStatus message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns OtaStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): OtaStatus;

    /**
     * Decodes an OtaStatus message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns OtaStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): OtaStatus;

    /**
     * Verifies an OtaStatus message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an OtaStatus message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns OtaStatus
     */
    public static fromObject(object: { [k: string]: any }): OtaStatus;

    /**
     * Creates a plain object from an OtaStatus message. Also converts values to other types if specified.
     * @param message OtaStatus
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: OtaStatus, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this OtaStatus to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for OtaStatus
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an OtaBegin. */
export class OtaBegin implements IOtaBegin {

    /**
     * Constructs a new OtaBegin.
     * @param [properties] Properties to set
     */
    constructor(properties?: IOtaBegin);

    /** OtaBegin fileSize. */
    public fileSize: number;

    /**
     * Creates a new OtaBegin instance using the specified properties.
     * @param [properties] Properties to set
     * @returns OtaBegin instance
     */
    public static create(properties?: IOtaBegin): OtaBegin;

    /**
     * Encodes the specified OtaBegin message. Does not implicitly {@link OtaBegin.verify|verify} messages.
     * @param message OtaBegin message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IOtaBegin, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified OtaBegin message, length delimited. Does not implicitly {@link OtaBegin.verify|verify} messages.
     * @param message OtaBegin message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IOtaBegin, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an OtaBegin message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns OtaBegin
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): OtaBegin;

    /**
     * Decodes an OtaBegin message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns OtaBegin
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): OtaBegin;

    /**
     * Verifies an OtaBegin message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an OtaBegin message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns OtaBegin
     */
    public static fromObject(object: { [k: string]: any }): OtaBegin;

    /**
     * Creates a plain object from an OtaBegin message. Also converts values to other types if specified.
     * @param message OtaBegin
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: OtaBegin, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this OtaBegin to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for OtaBegin
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an OtaChunk. */
export class OtaChunk implements IOtaChunk {

    /**
     * Constructs a new OtaChunk.
     * @param [properties] Properties to set
     */
    constructor(properties?: IOtaChunk);

    /** OtaChunk seq. */
    public seq: number;

    /** OtaChunk data. */
    public data: Uint8Array;

    /**
     * Creates a new OtaChunk instance using the specified properties.
     * @param [properties] Properties to set
     * @returns OtaChunk instance
     */
    public static create(properties?: IOtaChunk): OtaChunk;

    /**
     * Encodes the specified OtaChunk message. Does not implicitly {@link OtaChunk.verify|verify} messages.
     * @param message OtaChunk message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IOtaChunk, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified OtaChunk message, length delimited. Does not implicitly {@link OtaChunk.verify|verify} messages.
     * @param message OtaChunk message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IOtaChunk, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an OtaChunk message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns OtaChunk
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): OtaChunk;

    /**
     * Decodes an OtaChunk message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns OtaChunk
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): OtaChunk;

    /**
     * Verifies an OtaChunk message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an OtaChunk message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns OtaChunk
     */
    public static fromObject(object: { [k: string]: any }): OtaChunk;

    /**
     * Creates a plain object from an OtaChunk message. Also converts values to other types if specified.
     * @param message OtaChunk
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: OtaChunk, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this OtaChunk to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for OtaChunk
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an OtaEnd. */
export class OtaEnd implements IOtaEnd {

    /**
     * Constructs a new OtaEnd.
     * @param [properties] Properties to set
     */
    constructor(properties?: IOtaEnd);

    /** OtaEnd sha256. */
    public sha256: string;

    /**
     * Creates a new OtaEnd instance using the specified properties.
     * @param [properties] Properties to set
     * @returns OtaEnd instance
     */
    public static create(properties?: IOtaEnd): OtaEnd;

    /**
     * Encodes the specified OtaEnd message. Does not implicitly {@link OtaEnd.verify|verify} messages.
     * @param message OtaEnd message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IOtaEnd, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified OtaEnd message, length delimited. Does not implicitly {@link OtaEnd.verify|verify} messages.
     * @param message OtaEnd message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IOtaEnd, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an OtaEnd message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns OtaEnd
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): OtaEnd;

    /**
     * Decodes an OtaEnd message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns OtaEnd
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): OtaEnd;

    /**
     * Verifies an OtaEnd message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an OtaEnd message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns OtaEnd
     */
    public static fromObject(object: { [k: string]: any }): OtaEnd;

    /**
     * Creates a plain object from an OtaEnd message. Also converts values to other types if specified.
     * @param message OtaEnd
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: OtaEnd, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this OtaEnd to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for OtaEnd
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an OtaCommand. */
export class OtaCommand implements IOtaCommand {

    /**
     * Constructs a new OtaCommand.
     * @param [properties] Properties to set
     */
    constructor(properties?: IOtaCommand);

    /** OtaCommand begin. */
    public begin?: (IOtaBegin|null);

    /** OtaCommand chunk. */
    public chunk?: (IOtaChunk|null);

    /** OtaCommand end. */
    public end?: (IOtaEnd|null);

    /** OtaCommand abort. */
    public abort?: (boolean|null);

    /** OtaCommand type. */
    public type?: ("begin"|"chunk"|"end"|"abort");

    /**
     * Creates a new OtaCommand instance using the specified properties.
     * @param [properties] Properties to set
     * @returns OtaCommand instance
     */
    public static create(properties?: IOtaCommand): OtaCommand;

    /**
     * Encodes the specified OtaCommand message. Does not implicitly {@link OtaCommand.verify|verify} messages.
     * @param message OtaCommand message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IOtaCommand, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified OtaCommand message, length delimited. Does not implicitly {@link OtaCommand.verify|verify} messages.
     * @param message OtaCommand message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IOtaCommand, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an OtaCommand message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns OtaCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): OtaCommand;

    /**
     * Decodes an OtaCommand message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns OtaCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): OtaCommand;

    /**
     * Verifies an OtaCommand message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an OtaCommand message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns OtaCommand
     */
    public static fromObject(object: { [k: string]: any }): OtaCommand;

    /**
     * Creates a plain object from an OtaCommand message. Also converts values to other types if specified.
     * @param message OtaCommand
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: OtaCommand, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this OtaCommand to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for OtaCommand
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an UiCommand. */
export class UiCommand implements IUiCommand {

    /**
     * Constructs a new UiCommand.
     * @param [properties] Properties to set
     */
    constructor(properties?: IUiCommand);

    /** UiCommand name. */
    public name: string;

    /** UiCommand json. */
    public json: string;

    /** UiCommand requestId. */
    public requestId: number;

    /**
     * Creates a new UiCommand instance using the specified properties.
     * @param [properties] Properties to set
     * @returns UiCommand instance
     */
    public static create(properties?: IUiCommand): UiCommand;

    /**
     * Encodes the specified UiCommand message. Does not implicitly {@link UiCommand.verify|verify} messages.
     * @param message UiCommand message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IUiCommand, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified UiCommand message, length delimited. Does not implicitly {@link UiCommand.verify|verify} messages.
     * @param message UiCommand message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IUiCommand, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an UiCommand message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns UiCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): UiCommand;

    /**
     * Decodes an UiCommand message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns UiCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): UiCommand;

    /**
     * Verifies an UiCommand message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an UiCommand message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns UiCommand
     */
    public static fromObject(object: { [k: string]: any }): UiCommand;

    /**
     * Creates a plain object from an UiCommand message. Also converts values to other types if specified.
     * @param message UiCommand
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: UiCommand, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this UiCommand to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for UiCommand
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an UiCommandResult. */
export class UiCommandResult implements IUiCommandResult {

    /**
     * Constructs a new UiCommandResult.
     * @param [properties] Properties to set
     */
    constructor(properties?: IUiCommandResult);

    /** UiCommandResult requestId. */
    public requestId: number;

    /** UiCommandResult name. */
    public name: string;

    /** UiCommandResult ok. */
    public ok: boolean;

    /** UiCommandResult code. */
    public code: string;

    /** UiCommandResult message. */
    public message: string;

    /** UiCommandResult json. */
    public json: string;

    /**
     * Creates a new UiCommandResult instance using the specified properties.
     * @param [properties] Properties to set
     * @returns UiCommandResult instance
     */
    public static create(properties?: IUiCommandResult): UiCommandResult;

    /**
     * Encodes the specified UiCommandResult message. Does not implicitly {@link UiCommandResult.verify|verify} messages.
     * @param message UiCommandResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IUiCommandResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified UiCommandResult message, length delimited. Does not implicitly {@link UiCommandResult.verify|verify} messages.
     * @param message UiCommandResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IUiCommandResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an UiCommandResult message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns UiCommandResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): UiCommandResult;

    /**
     * Decodes an UiCommandResult message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns UiCommandResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): UiCommandResult;

    /**
     * Verifies an UiCommandResult message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an UiCommandResult message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns UiCommandResult
     */
    public static fromObject(object: { [k: string]: any }): UiCommandResult;

    /**
     * Creates a plain object from an UiCommandResult message. Also converts values to other types if specified.
     * @param message UiCommandResult
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: UiCommandResult, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this UiCommandResult to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for UiCommandResult
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents a BlePacket. */
export class BlePacket implements IBlePacket {

    /**
     * Constructs a new BlePacket.
     * @param [properties] Properties to set
     */
    constructor(properties?: IBlePacket);

    /** BlePacket telemetry. */
    public telemetry?: (ITelemetry|null);

    /** BlePacket status. */
    public status?: (ISystemStatus|null);

    /** BlePacket log. */
    public log?: (ILogMessage|null);

    /** BlePacket otaStatus. */
    public otaStatus?: (IOtaStatus|null);

    /** BlePacket commandResult. */
    public commandResult?: (IUiCommandResult|null);

    /** BlePacket payload. */
    public payload?: ("telemetry"|"status"|"log"|"otaStatus"|"commandResult");

    /**
     * Creates a new BlePacket instance using the specified properties.
     * @param [properties] Properties to set
     * @returns BlePacket instance
     */
    public static create(properties?: IBlePacket): BlePacket;

    /**
     * Encodes the specified BlePacket message. Does not implicitly {@link BlePacket.verify|verify} messages.
     * @param message BlePacket message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IBlePacket, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified BlePacket message, length delimited. Does not implicitly {@link BlePacket.verify|verify} messages.
     * @param message BlePacket message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IBlePacket, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes a BlePacket message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns BlePacket
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): BlePacket;

    /**
     * Decodes a BlePacket message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns BlePacket
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): BlePacket;

    /**
     * Verifies a BlePacket message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates a BlePacket message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns BlePacket
     */
    public static fromObject(object: { [k: string]: any }): BlePacket;

    /**
     * Creates a plain object from a BlePacket message. Also converts values to other types if specified.
     * @param message BlePacket
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: BlePacket, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this BlePacket to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for BlePacket
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}
