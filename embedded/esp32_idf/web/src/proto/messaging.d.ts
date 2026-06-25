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

/** Represents an AnalogStatus. */
export class AnalogStatus implements IAnalogStatus {

    /**
     * Constructs a new AnalogStatus.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAnalogStatus);

    /** AnalogStatus seq. */
    public seq: number;

    /** AnalogStatus valid. */
    public valid: boolean;

    /** AnalogStatus timestampUs. */
    public timestampUs: (number|Long);

    /** AnalogStatus ageUs. */
    public ageUs: number;

    /** AnalogStatus targetTriplesPerCycle. */
    public targetTriplesPerCycle: number;

    /** AnalogStatus measuredTriplesPerSecond. */
    public measuredTriplesPerSecond: number;

    /** AnalogStatus rawAn3. */
    public rawAn3: number;

    /** AnalogStatus rawAn5. */
    public rawAn5: number;

    /** AnalogStatus rawAn6. */
    public rawAn6: number;

    /** AnalogStatus calibratedAn3. */
    public calibratedAn3: number;

    /** AnalogStatus calibratedAn5. */
    public calibratedAn5: number;

    /** AnalogStatus calibratedAn6. */
    public calibratedAn6: number;

    /** AnalogStatus latencyMinUs. */
    public latencyMinUs: number;

    /** AnalogStatus latencyAvgUs. */
    public latencyAvgUs: number;

    /** AnalogStatus latencyP95Us. */
    public latencyP95Us: number;

    /** AnalogStatus latencyMaxUs. */
    public latencyMaxUs: number;

    /** AnalogStatus overflowCount. */
    public overflowCount: number;

    /** AnalogStatus missCount. */
    public missCount: number;

    /** AnalogStatus consecutiveMisses. */
    public consecutiveMisses: number;

    /** AnalogStatus faultCode. */
    public faultCode: number;

    /** AnalogStatus acquisitionMode. */
    public acquisitionMode: number;

    /** AnalogStatus samplesRead. */
    public samplesRead: number;

    /** AnalogStatus samplesRejected. */
    public samplesRejected: number;

    /** AnalogStatus channelOrderAnomalies. */
    public channelOrderAnomalies: number;

    /** AnalogStatus partialTriples. */
    public partialTriples: number;

    /** AnalogStatus frameDrops. */
    public frameDrops: number;

    /** AnalogStatus poolFlushes. */
    public poolFlushes: number;

    /** AnalogStatus calibrationLutReady. */
    public calibrationLutReady: boolean;

    /**
     * Creates a new AnalogStatus instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AnalogStatus instance
     */
    public static create(properties?: IAnalogStatus): AnalogStatus;

    /**
     * Encodes the specified AnalogStatus message. Does not implicitly {@link AnalogStatus.verify|verify} messages.
     * @param message AnalogStatus message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAnalogStatus, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AnalogStatus message, length delimited. Does not implicitly {@link AnalogStatus.verify|verify} messages.
     * @param message AnalogStatus message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAnalogStatus, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AnalogStatus message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AnalogStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AnalogStatus;

    /**
     * Decodes an AnalogStatus message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AnalogStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AnalogStatus;

    /**
     * Verifies an AnalogStatus message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AnalogStatus message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AnalogStatus
     */
    public static fromObject(object: { [k: string]: any }): AnalogStatus;

    /**
     * Creates a plain object from an AnalogStatus message. Also converts values to other types if specified.
     * @param message AnalogStatus
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AnalogStatus, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AnalogStatus to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AnalogStatus
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

    /** SystemStatus deadTimeUs. */
    public deadTimeUs: number;

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

    /** SystemStatus deadTimeTailOverheadCycles. */
    public deadTimeTailOverheadCycles: number;

    /** SystemStatus analog. */
    public analog?: (IAnalogStatus|null);

    /** SystemStatus signalEdgeOverheadUpCycles. */
    public signalEdgeOverheadUpCycles: number;

    /** SystemStatus signalEdgeOverheadDownCycles. */
    public signalEdgeOverheadDownCycles: number;

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

/** Represents an AnalogDiagnosticResult. */
export class AnalogDiagnosticResult implements IAnalogDiagnosticResult {

    /**
     * Constructs a new AnalogDiagnosticResult.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAnalogDiagnosticResult);

    /** AnalogDiagnosticResult valid. */
    public valid: boolean;

    /** AnalogDiagnosticResult running. */
    public running: boolean;

    /** AnalogDiagnosticResult durationMs. */
    public durationMs: number;

    /** AnalogDiagnosticResult elapsedUs. */
    public elapsedUs: (number|Long);

    /** AnalogDiagnosticResult seqDelta. */
    public seqDelta: number;

    /** AnalogDiagnosticResult missDelta. */
    public missDelta: number;

    /** AnalogDiagnosticResult overflowDelta. */
    public overflowDelta: number;

    /** AnalogDiagnosticResult seq. */
    public seq: number;

    /** AnalogDiagnosticResult ageUs. */
    public ageUs: number;

    /** AnalogDiagnosticResult rateTps. */
    public rateTps: number;

    /** AnalogDiagnosticResult rawAn3. */
    public rawAn3: number;

    /** AnalogDiagnosticResult rawAn5. */
    public rawAn5: number;

    /** AnalogDiagnosticResult rawAn6. */
    public rawAn6: number;

    /** AnalogDiagnosticResult calAn3. */
    public calAn3: number;

    /** AnalogDiagnosticResult calAn5. */
    public calAn5: number;

    /** AnalogDiagnosticResult calAn6. */
    public calAn6: number;

    /** AnalogDiagnosticResult latencyAvgUs. */
    public latencyAvgUs: number;

    /** AnalogDiagnosticResult latencyP95Us. */
    public latencyP95Us: number;

    /** AnalogDiagnosticResult faultCode. */
    public faultCode: number;

    /** AnalogDiagnosticResult timingSamples. */
    public timingSamples: number;

    /** AnalogDiagnosticResult playbackAvgUs. */
    public playbackAvgUs: number;

    /** AnalogDiagnosticResult loopUs. */
    public loopUs: number;

    /** AnalogDiagnosticResult overruns. */
    public overruns: number;

    /** AnalogDiagnosticResult timingFaults. */
    public timingFaults: number;

    /** AnalogDiagnosticResult message. */
    public message: string;

    /**
     * Creates a new AnalogDiagnosticResult instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AnalogDiagnosticResult instance
     */
    public static create(properties?: IAnalogDiagnosticResult): AnalogDiagnosticResult;

    /**
     * Encodes the specified AnalogDiagnosticResult message. Does not implicitly {@link AnalogDiagnosticResult.verify|verify} messages.
     * @param message AnalogDiagnosticResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAnalogDiagnosticResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AnalogDiagnosticResult message, length delimited. Does not implicitly {@link AnalogDiagnosticResult.verify|verify} messages.
     * @param message AnalogDiagnosticResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAnalogDiagnosticResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AnalogDiagnosticResult message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AnalogDiagnosticResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AnalogDiagnosticResult;

    /**
     * Decodes an AnalogDiagnosticResult message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AnalogDiagnosticResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AnalogDiagnosticResult;

    /**
     * Verifies an AnalogDiagnosticResult message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AnalogDiagnosticResult message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AnalogDiagnosticResult
     */
    public static fromObject(object: { [k: string]: any }): AnalogDiagnosticResult;

    /**
     * Creates a plain object from an AnalogDiagnosticResult message. Also converts values to other types if specified.
     * @param message AnalogDiagnosticResult
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AnalogDiagnosticResult, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AnalogDiagnosticResult to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AnalogDiagnosticResult
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an AnalogConfigCaseResult. */
export class AnalogConfigCaseResult implements IAnalogConfigCaseResult {

    /**
     * Constructs a new AnalogConfigCaseResult.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAnalogConfigCaseResult);

    /** AnalogConfigCaseResult sampleHz. */
    public sampleHz: number;

    /** AnalogConfigCaseResult durationMs. */
    public durationMs: number;

    /** AnalogConfigCaseResult elapsedUs. */
    public elapsedUs: (number|Long);

    /** AnalogConfigCaseResult seqDelta. */
    public seqDelta: number;

    /** AnalogConfigCaseResult rateTps. */
    public rateTps: number;

    /** AnalogConfigCaseResult ageUs. */
    public ageUs: number;

    /** AnalogConfigCaseResult missDelta. */
    public missDelta: number;

    /** AnalogConfigCaseResult overflowDelta. */
    public overflowDelta: number;

    /** AnalogConfigCaseResult faultCode. */
    public faultCode: number;

    /** AnalogConfigCaseResult latencyAvgUs. */
    public latencyAvgUs: number;

    /** AnalogConfigCaseResult latencyP95Us. */
    public latencyP95Us: number;

    /** AnalogConfigCaseResult playbackAvgUsX100. */
    public playbackAvgUsX100: number;

    /** AnalogConfigCaseResult loopUsX100. */
    public loopUsX100: number;

    /** AnalogConfigCaseResult overrunsDelta. */
    public overrunsDelta: number;

    /** AnalogConfigCaseResult timingFaultsDelta. */
    public timingFaultsDelta: number;

    /** AnalogConfigCaseResult dmaSamplesDelta. */
    public dmaSamplesDelta: number;

    /** AnalogConfigCaseResult dmaAnomaliesDelta. */
    public dmaAnomaliesDelta: number;

    /**
     * Creates a new AnalogConfigCaseResult instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AnalogConfigCaseResult instance
     */
    public static create(properties?: IAnalogConfigCaseResult): AnalogConfigCaseResult;

    /**
     * Encodes the specified AnalogConfigCaseResult message. Does not implicitly {@link AnalogConfigCaseResult.verify|verify} messages.
     * @param message AnalogConfigCaseResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAnalogConfigCaseResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AnalogConfigCaseResult message, length delimited. Does not implicitly {@link AnalogConfigCaseResult.verify|verify} messages.
     * @param message AnalogConfigCaseResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAnalogConfigCaseResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AnalogConfigCaseResult message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AnalogConfigCaseResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AnalogConfigCaseResult;

    /**
     * Decodes an AnalogConfigCaseResult message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AnalogConfigCaseResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AnalogConfigCaseResult;

    /**
     * Verifies an AnalogConfigCaseResult message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AnalogConfigCaseResult message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AnalogConfigCaseResult
     */
    public static fromObject(object: { [k: string]: any }): AnalogConfigCaseResult;

    /**
     * Creates a plain object from an AnalogConfigCaseResult message. Also converts values to other types if specified.
     * @param message AnalogConfigCaseResult
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AnalogConfigCaseResult, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AnalogConfigCaseResult to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AnalogConfigCaseResult
     * @param [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns The default type url
     */
    public static getTypeUrl(typeUrlPrefix?: string): string;
}

/** Represents an AnalogConfigTestResult. */
export class AnalogConfigTestResult implements IAnalogConfigTestResult {

    /**
     * Constructs a new AnalogConfigTestResult.
     * @param [properties] Properties to set
     */
    constructor(properties?: IAnalogConfigTestResult);

    /** AnalogConfigTestResult valid. */
    public valid: boolean;

    /** AnalogConfigTestResult running. */
    public running: boolean;

    /** AnalogConfigTestResult caseCount. */
    public caseCount: number;

    /** AnalogConfigTestResult cases. */
    public cases: IAnalogConfigCaseResult[];

    /** AnalogConfigTestResult message. */
    public message: string;

    /**
     * Creates a new AnalogConfigTestResult instance using the specified properties.
     * @param [properties] Properties to set
     * @returns AnalogConfigTestResult instance
     */
    public static create(properties?: IAnalogConfigTestResult): AnalogConfigTestResult;

    /**
     * Encodes the specified AnalogConfigTestResult message. Does not implicitly {@link AnalogConfigTestResult.verify|verify} messages.
     * @param message AnalogConfigTestResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encode(message: IAnalogConfigTestResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Encodes the specified AnalogConfigTestResult message, length delimited. Does not implicitly {@link AnalogConfigTestResult.verify|verify} messages.
     * @param message AnalogConfigTestResult message or plain object to encode
     * @param [writer] Writer to encode to
     * @returns Writer
     */
    public static encodeDelimited(message: IAnalogConfigTestResult, writer?: $protobuf.Writer): $protobuf.Writer;

    /**
     * Decodes an AnalogConfigTestResult message from the specified reader or buffer.
     * @param reader Reader or buffer to decode from
     * @param [length] Message length if known beforehand
     * @returns AnalogConfigTestResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decode(reader: ($protobuf.Reader|Uint8Array), length?: number): AnalogConfigTestResult;

    /**
     * Decodes an AnalogConfigTestResult message from the specified reader or buffer, length delimited.
     * @param reader Reader or buffer to decode from
     * @returns AnalogConfigTestResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    public static decodeDelimited(reader: ($protobuf.Reader|Uint8Array)): AnalogConfigTestResult;

    /**
     * Verifies an AnalogConfigTestResult message.
     * @param message Plain object to verify
     * @returns `null` if valid, otherwise the reason why it is not
     */
    public static verify(message: { [k: string]: any }): (string|null);

    /**
     * Creates an AnalogConfigTestResult message from a plain object. Also converts values to their respective internal types.
     * @param object Plain object
     * @returns AnalogConfigTestResult
     */
    public static fromObject(object: { [k: string]: any }): AnalogConfigTestResult;

    /**
     * Creates a plain object from an AnalogConfigTestResult message. Also converts values to other types if specified.
     * @param message AnalogConfigTestResult
     * @param [options] Conversion options
     * @returns Plain object
     */
    public static toObject(message: AnalogConfigTestResult, options?: $protobuf.IConversionOptions): { [k: string]: any };

    /**
     * Converts this AnalogConfigTestResult to JSON.
     * @returns JSON object
     */
    public toJSON(): { [k: string]: any };

    /**
     * Gets the default type url for AnalogConfigTestResult
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

    /** BlePacket analogDiagnosticResult. */
    public analogDiagnosticResult?: (IAnalogDiagnosticResult|null);

    /** BlePacket analogConfigTestResult. */
    public analogConfigTestResult?: (IAnalogConfigTestResult|null);

    /** BlePacket payload. */
    public payload?: ("telemetry"|"status"|"log"|"otaStatus"|"commandResult"|"analogDiagnosticResult"|"analogConfigTestResult");

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
