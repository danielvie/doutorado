/*eslint-disable block-scoped-var, id-length, no-control-regex, no-magic-numbers, no-prototype-builtins, no-redeclare, no-shadow, no-var, sort-vars*/
import * as $protobuf from "protobufjs/minimal";

// Common aliases
const $Reader = $protobuf.Reader, $Writer = $protobuf.Writer, $util = $protobuf.util;

// Exported root namespace
const $root = $protobuf.roots["default"] || ($protobuf.roots["default"] = {});

/**
 * BleSignalSet enum.
 * @exports BleSignalSet
 * @enum {number}
 * @property {number} BLE_SET_A=0 BLE_SET_A value
 * @property {number} BLE_SET_B=1 BLE_SET_B value
 */
export const BleSignalSet = $root.BleSignalSet = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "BLE_SET_A"] = 0;
    values[valuesById[1] = "BLE_SET_B"] = 1;
    return values;
})();

/**
 * BleAnalogReadState enum.
 * @exports BleAnalogReadState
 * @enum {number}
 * @property {number} BLE_READ_IDLE=0 BLE_READ_IDLE value
 * @property {number} BLE_READING=1 BLE_READING value
 * @property {number} BLE_READ_DISABLED=2 BLE_READ_DISABLED value
 */
export const BleAnalogReadState = $root.BleAnalogReadState = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "BLE_READ_IDLE"] = 0;
    values[valuesById[1] = "BLE_READING"] = 1;
    values[valuesById[2] = "BLE_READ_DISABLED"] = 2;
    return values;
})();

/**
 * BleSignalState enum.
 * @exports BleSignalState
 * @enum {number}
 * @property {number} BLE_SIG_IDLE=0 BLE_SIG_IDLE value
 * @property {number} BLE_SIG_RUNNING=1 BLE_SIG_RUNNING value
 */
export const BleSignalState = $root.BleSignalState = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "BLE_SIG_IDLE"] = 0;
    values[valuesById[1] = "BLE_SIG_RUNNING"] = 1;
    return values;
})();

/**
 * BleControlState enum.
 * @exports BleControlState
 * @enum {number}
 * @property {number} BLE_CTRL_OFF=0 BLE_CTRL_OFF value
 * @property {number} BLE_CTRL_ON=1 BLE_CTRL_ON value
 */
export const BleControlState = $root.BleControlState = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "BLE_CTRL_OFF"] = 0;
    values[valuesById[1] = "BLE_CTRL_ON"] = 1;
    return values;
})();

/**
 * BleLedMode enum.
 * @exports BleLedMode
 * @enum {number}
 * @property {number} LED_NORMAL=0 LED_NORMAL value
 * @property {number} LED_BLINKING=1 LED_BLINKING value
 */
export const BleLedMode = $root.BleLedMode = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "LED_NORMAL"] = 0;
    values[valuesById[1] = "LED_BLINKING"] = 1;
    return values;
})();

/**
 * BleLogLevel enum.
 * @exports BleLogLevel
 * @enum {number}
 * @property {number} BLE_LOG_INFO=0 BLE_LOG_INFO value
 * @property {number} BLE_LOG_WARN=1 BLE_LOG_WARN value
 * @property {number} BLE_LOG_ERROR=2 BLE_LOG_ERROR value
 */
export const BleLogLevel = $root.BleLogLevel = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "BLE_LOG_INFO"] = 0;
    values[valuesById[1] = "BLE_LOG_WARN"] = 1;
    values[valuesById[2] = "BLE_LOG_ERROR"] = 2;
    return values;
})();

export const Telemetry = $root.Telemetry = (() => {

    /**
     * Properties of a Telemetry.
     * @exports ITelemetry
     * @interface ITelemetry
     * @property {number|null} [an3] Telemetry an3
     * @property {number|null} [an5] Telemetry an5
     * @property {number|null} [an6] Telemetry an6
     * @property {number|null} [timestampMs] Telemetry timestampMs
     */

    /**
     * Constructs a new Telemetry.
     * @exports Telemetry
     * @classdesc Represents a Telemetry.
     * @implements ITelemetry
     * @constructor
     * @param {ITelemetry=} [properties] Properties to set
     */
    function Telemetry(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * Telemetry an3.
     * @member {number} an3
     * @memberof Telemetry
     * @instance
     */
    Telemetry.prototype.an3 = 0;

    /**
     * Telemetry an5.
     * @member {number} an5
     * @memberof Telemetry
     * @instance
     */
    Telemetry.prototype.an5 = 0;

    /**
     * Telemetry an6.
     * @member {number} an6
     * @memberof Telemetry
     * @instance
     */
    Telemetry.prototype.an6 = 0;

    /**
     * Telemetry timestampMs.
     * @member {number} timestampMs
     * @memberof Telemetry
     * @instance
     */
    Telemetry.prototype.timestampMs = 0;

    /**
     * Creates a new Telemetry instance using the specified properties.
     * @function create
     * @memberof Telemetry
     * @static
     * @param {ITelemetry=} [properties] Properties to set
     * @returns {Telemetry} Telemetry instance
     */
    Telemetry.create = function create(properties) {
        return new Telemetry(properties);
    };

    /**
     * Encodes the specified Telemetry message. Does not implicitly {@link Telemetry.verify|verify} messages.
     * @function encode
     * @memberof Telemetry
     * @static
     * @param {ITelemetry} message Telemetry message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    Telemetry.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.an3 != null && Object.hasOwnProperty.call(message, "an3"))
            writer.uint32(/* id 1, wireType 5 =*/13).float(message.an3);
        if (message.an5 != null && Object.hasOwnProperty.call(message, "an5"))
            writer.uint32(/* id 2, wireType 5 =*/21).float(message.an5);
        if (message.an6 != null && Object.hasOwnProperty.call(message, "an6"))
            writer.uint32(/* id 3, wireType 5 =*/29).float(message.an6);
        if (message.timestampMs != null && Object.hasOwnProperty.call(message, "timestampMs"))
            writer.uint32(/* id 4, wireType 0 =*/32).uint32(message.timestampMs);
        return writer;
    };

    /**
     * Encodes the specified Telemetry message, length delimited. Does not implicitly {@link Telemetry.verify|verify} messages.
     * @function encodeDelimited
     * @memberof Telemetry
     * @static
     * @param {ITelemetry} message Telemetry message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    Telemetry.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a Telemetry message from the specified reader or buffer.
     * @function decode
     * @memberof Telemetry
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {Telemetry} Telemetry
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    Telemetry.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.Telemetry();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.an3 = reader.float();
                    break;
                }
            case 2: {
                    message.an5 = reader.float();
                    break;
                }
            case 3: {
                    message.an6 = reader.float();
                    break;
                }
            case 4: {
                    message.timestampMs = reader.uint32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a Telemetry message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof Telemetry
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {Telemetry} Telemetry
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    Telemetry.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a Telemetry message.
     * @function verify
     * @memberof Telemetry
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    Telemetry.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.an3 != null && message.hasOwnProperty("an3"))
            if (typeof message.an3 !== "number")
                return "an3: number expected";
        if (message.an5 != null && message.hasOwnProperty("an5"))
            if (typeof message.an5 !== "number")
                return "an5: number expected";
        if (message.an6 != null && message.hasOwnProperty("an6"))
            if (typeof message.an6 !== "number")
                return "an6: number expected";
        if (message.timestampMs != null && message.hasOwnProperty("timestampMs"))
            if (!$util.isInteger(message.timestampMs))
                return "timestampMs: integer expected";
        return null;
    };

    /**
     * Creates a Telemetry message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof Telemetry
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {Telemetry} Telemetry
     */
    Telemetry.fromObject = function fromObject(object) {
        if (object instanceof $root.Telemetry)
            return object;
        let message = new $root.Telemetry();
        if (object.an3 != null)
            message.an3 = Number(object.an3);
        if (object.an5 != null)
            message.an5 = Number(object.an5);
        if (object.an6 != null)
            message.an6 = Number(object.an6);
        if (object.timestampMs != null)
            message.timestampMs = object.timestampMs >>> 0;
        return message;
    };

    /**
     * Creates a plain object from a Telemetry message. Also converts values to other types if specified.
     * @function toObject
     * @memberof Telemetry
     * @static
     * @param {Telemetry} message Telemetry
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    Telemetry.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.an3 = 0;
            object.an5 = 0;
            object.an6 = 0;
            object.timestampMs = 0;
        }
        if (message.an3 != null && message.hasOwnProperty("an3"))
            object.an3 = options.json && !isFinite(message.an3) ? String(message.an3) : message.an3;
        if (message.an5 != null && message.hasOwnProperty("an5"))
            object.an5 = options.json && !isFinite(message.an5) ? String(message.an5) : message.an5;
        if (message.an6 != null && message.hasOwnProperty("an6"))
            object.an6 = options.json && !isFinite(message.an6) ? String(message.an6) : message.an6;
        if (message.timestampMs != null && message.hasOwnProperty("timestampMs"))
            object.timestampMs = message.timestampMs;
        return object;
    };

    /**
     * Converts this Telemetry to JSON.
     * @function toJSON
     * @memberof Telemetry
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    Telemetry.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for Telemetry
     * @function getTypeUrl
     * @memberof Telemetry
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    Telemetry.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/Telemetry";
    };

    return Telemetry;
})();

export const AnalogStatus = $root.AnalogStatus = (() => {

    /**
     * Properties of an AnalogStatus.
     * @exports IAnalogStatus
     * @interface IAnalogStatus
     * @property {number|null} [seq] AnalogStatus seq
     * @property {boolean|null} [valid] AnalogStatus valid
     * @property {number|Long|null} [timestampUs] AnalogStatus timestampUs
     * @property {number|null} [ageUs] AnalogStatus ageUs
     * @property {number|null} [targetTriplesPerCycle] AnalogStatus targetTriplesPerCycle
     * @property {number|null} [measuredTriplesPerSecond] AnalogStatus measuredTriplesPerSecond
     * @property {number|null} [rawAn3] AnalogStatus rawAn3
     * @property {number|null} [rawAn5] AnalogStatus rawAn5
     * @property {number|null} [rawAn6] AnalogStatus rawAn6
     * @property {number|null} [calibratedAn3] AnalogStatus calibratedAn3
     * @property {number|null} [calibratedAn5] AnalogStatus calibratedAn5
     * @property {number|null} [calibratedAn6] AnalogStatus calibratedAn6
     * @property {number|null} [latencyMinUs] AnalogStatus latencyMinUs
     * @property {number|null} [latencyAvgUs] AnalogStatus latencyAvgUs
     * @property {number|null} [latencyP95Us] AnalogStatus latencyP95Us
     * @property {number|null} [latencyMaxUs] AnalogStatus latencyMaxUs
     * @property {number|null} [overflowCount] AnalogStatus overflowCount
     * @property {number|null} [missCount] AnalogStatus missCount
     * @property {number|null} [consecutiveMisses] AnalogStatus consecutiveMisses
     * @property {number|null} [faultCode] AnalogStatus faultCode
     * @property {number|null} [acquisitionMode] AnalogStatus acquisitionMode
     * @property {number|null} [samplesRead] AnalogStatus samplesRead
     * @property {number|null} [samplesRejected] AnalogStatus samplesRejected
     * @property {number|null} [channelOrderAnomalies] AnalogStatus channelOrderAnomalies
     * @property {number|null} [partialTriples] AnalogStatus partialTriples
     * @property {number|null} [frameDrops] AnalogStatus frameDrops
     * @property {number|null} [poolFlushes] AnalogStatus poolFlushes
     * @property {boolean|null} [calibrationLutReady] AnalogStatus calibrationLutReady
     */

    /**
     * Constructs a new AnalogStatus.
     * @exports AnalogStatus
     * @classdesc Represents an AnalogStatus.
     * @implements IAnalogStatus
     * @constructor
     * @param {IAnalogStatus=} [properties] Properties to set
     */
    function AnalogStatus(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AnalogStatus seq.
     * @member {number} seq
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.seq = 0;

    /**
     * AnalogStatus valid.
     * @member {boolean} valid
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.valid = false;

    /**
     * AnalogStatus timestampUs.
     * @member {number|Long} timestampUs
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.timestampUs = $util.Long ? $util.Long.fromBits(0,0,true) : 0;

    /**
     * AnalogStatus ageUs.
     * @member {number} ageUs
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.ageUs = 0;

    /**
     * AnalogStatus targetTriplesPerCycle.
     * @member {number} targetTriplesPerCycle
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.targetTriplesPerCycle = 0;

    /**
     * AnalogStatus measuredTriplesPerSecond.
     * @member {number} measuredTriplesPerSecond
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.measuredTriplesPerSecond = 0;

    /**
     * AnalogStatus rawAn3.
     * @member {number} rawAn3
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.rawAn3 = 0;

    /**
     * AnalogStatus rawAn5.
     * @member {number} rawAn5
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.rawAn5 = 0;

    /**
     * AnalogStatus rawAn6.
     * @member {number} rawAn6
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.rawAn6 = 0;

    /**
     * AnalogStatus calibratedAn3.
     * @member {number} calibratedAn3
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.calibratedAn3 = 0;

    /**
     * AnalogStatus calibratedAn5.
     * @member {number} calibratedAn5
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.calibratedAn5 = 0;

    /**
     * AnalogStatus calibratedAn6.
     * @member {number} calibratedAn6
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.calibratedAn6 = 0;

    /**
     * AnalogStatus latencyMinUs.
     * @member {number} latencyMinUs
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.latencyMinUs = 0;

    /**
     * AnalogStatus latencyAvgUs.
     * @member {number} latencyAvgUs
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.latencyAvgUs = 0;

    /**
     * AnalogStatus latencyP95Us.
     * @member {number} latencyP95Us
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.latencyP95Us = 0;

    /**
     * AnalogStatus latencyMaxUs.
     * @member {number} latencyMaxUs
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.latencyMaxUs = 0;

    /**
     * AnalogStatus overflowCount.
     * @member {number} overflowCount
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.overflowCount = 0;

    /**
     * AnalogStatus missCount.
     * @member {number} missCount
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.missCount = 0;

    /**
     * AnalogStatus consecutiveMisses.
     * @member {number} consecutiveMisses
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.consecutiveMisses = 0;

    /**
     * AnalogStatus faultCode.
     * @member {number} faultCode
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.faultCode = 0;

    /**
     * AnalogStatus acquisitionMode.
     * @member {number} acquisitionMode
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.acquisitionMode = 0;

    /**
     * AnalogStatus samplesRead.
     * @member {number} samplesRead
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.samplesRead = 0;

    /**
     * AnalogStatus samplesRejected.
     * @member {number} samplesRejected
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.samplesRejected = 0;

    /**
     * AnalogStatus channelOrderAnomalies.
     * @member {number} channelOrderAnomalies
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.channelOrderAnomalies = 0;

    /**
     * AnalogStatus partialTriples.
     * @member {number} partialTriples
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.partialTriples = 0;

    /**
     * AnalogStatus frameDrops.
     * @member {number} frameDrops
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.frameDrops = 0;

    /**
     * AnalogStatus poolFlushes.
     * @member {number} poolFlushes
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.poolFlushes = 0;

    /**
     * AnalogStatus calibrationLutReady.
     * @member {boolean} calibrationLutReady
     * @memberof AnalogStatus
     * @instance
     */
    AnalogStatus.prototype.calibrationLutReady = false;

    /**
     * Creates a new AnalogStatus instance using the specified properties.
     * @function create
     * @memberof AnalogStatus
     * @static
     * @param {IAnalogStatus=} [properties] Properties to set
     * @returns {AnalogStatus} AnalogStatus instance
     */
    AnalogStatus.create = function create(properties) {
        return new AnalogStatus(properties);
    };

    /**
     * Encodes the specified AnalogStatus message. Does not implicitly {@link AnalogStatus.verify|verify} messages.
     * @function encode
     * @memberof AnalogStatus
     * @static
     * @param {IAnalogStatus} message AnalogStatus message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogStatus.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.seq != null && Object.hasOwnProperty.call(message, "seq"))
            writer.uint32(/* id 1, wireType 0 =*/8).uint32(message.seq);
        if (message.valid != null && Object.hasOwnProperty.call(message, "valid"))
            writer.uint32(/* id 2, wireType 0 =*/16).bool(message.valid);
        if (message.timestampUs != null && Object.hasOwnProperty.call(message, "timestampUs"))
            writer.uint32(/* id 3, wireType 0 =*/24).uint64(message.timestampUs);
        if (message.ageUs != null && Object.hasOwnProperty.call(message, "ageUs"))
            writer.uint32(/* id 4, wireType 0 =*/32).uint32(message.ageUs);
        if (message.targetTriplesPerCycle != null && Object.hasOwnProperty.call(message, "targetTriplesPerCycle"))
            writer.uint32(/* id 5, wireType 0 =*/40).uint32(message.targetTriplesPerCycle);
        if (message.measuredTriplesPerSecond != null && Object.hasOwnProperty.call(message, "measuredTriplesPerSecond"))
            writer.uint32(/* id 6, wireType 0 =*/48).uint32(message.measuredTriplesPerSecond);
        if (message.rawAn3 != null && Object.hasOwnProperty.call(message, "rawAn3"))
            writer.uint32(/* id 7, wireType 0 =*/56).uint32(message.rawAn3);
        if (message.rawAn5 != null && Object.hasOwnProperty.call(message, "rawAn5"))
            writer.uint32(/* id 8, wireType 0 =*/64).uint32(message.rawAn5);
        if (message.rawAn6 != null && Object.hasOwnProperty.call(message, "rawAn6"))
            writer.uint32(/* id 9, wireType 0 =*/72).uint32(message.rawAn6);
        if (message.calibratedAn3 != null && Object.hasOwnProperty.call(message, "calibratedAn3"))
            writer.uint32(/* id 10, wireType 5 =*/85).float(message.calibratedAn3);
        if (message.calibratedAn5 != null && Object.hasOwnProperty.call(message, "calibratedAn5"))
            writer.uint32(/* id 11, wireType 5 =*/93).float(message.calibratedAn5);
        if (message.calibratedAn6 != null && Object.hasOwnProperty.call(message, "calibratedAn6"))
            writer.uint32(/* id 12, wireType 5 =*/101).float(message.calibratedAn6);
        if (message.latencyMinUs != null && Object.hasOwnProperty.call(message, "latencyMinUs"))
            writer.uint32(/* id 13, wireType 0 =*/104).uint32(message.latencyMinUs);
        if (message.latencyAvgUs != null && Object.hasOwnProperty.call(message, "latencyAvgUs"))
            writer.uint32(/* id 14, wireType 0 =*/112).uint32(message.latencyAvgUs);
        if (message.latencyP95Us != null && Object.hasOwnProperty.call(message, "latencyP95Us"))
            writer.uint32(/* id 15, wireType 0 =*/120).uint32(message.latencyP95Us);
        if (message.latencyMaxUs != null && Object.hasOwnProperty.call(message, "latencyMaxUs"))
            writer.uint32(/* id 16, wireType 0 =*/128).uint32(message.latencyMaxUs);
        if (message.overflowCount != null && Object.hasOwnProperty.call(message, "overflowCount"))
            writer.uint32(/* id 17, wireType 0 =*/136).uint32(message.overflowCount);
        if (message.missCount != null && Object.hasOwnProperty.call(message, "missCount"))
            writer.uint32(/* id 18, wireType 0 =*/144).uint32(message.missCount);
        if (message.consecutiveMisses != null && Object.hasOwnProperty.call(message, "consecutiveMisses"))
            writer.uint32(/* id 19, wireType 0 =*/152).uint32(message.consecutiveMisses);
        if (message.faultCode != null && Object.hasOwnProperty.call(message, "faultCode"))
            writer.uint32(/* id 20, wireType 0 =*/160).uint32(message.faultCode);
        if (message.acquisitionMode != null && Object.hasOwnProperty.call(message, "acquisitionMode"))
            writer.uint32(/* id 21, wireType 0 =*/168).uint32(message.acquisitionMode);
        if (message.samplesRead != null && Object.hasOwnProperty.call(message, "samplesRead"))
            writer.uint32(/* id 22, wireType 0 =*/176).uint32(message.samplesRead);
        if (message.samplesRejected != null && Object.hasOwnProperty.call(message, "samplesRejected"))
            writer.uint32(/* id 23, wireType 0 =*/184).uint32(message.samplesRejected);
        if (message.channelOrderAnomalies != null && Object.hasOwnProperty.call(message, "channelOrderAnomalies"))
            writer.uint32(/* id 24, wireType 0 =*/192).uint32(message.channelOrderAnomalies);
        if (message.partialTriples != null && Object.hasOwnProperty.call(message, "partialTriples"))
            writer.uint32(/* id 25, wireType 0 =*/200).uint32(message.partialTriples);
        if (message.frameDrops != null && Object.hasOwnProperty.call(message, "frameDrops"))
            writer.uint32(/* id 26, wireType 0 =*/208).uint32(message.frameDrops);
        if (message.poolFlushes != null && Object.hasOwnProperty.call(message, "poolFlushes"))
            writer.uint32(/* id 27, wireType 0 =*/216).uint32(message.poolFlushes);
        if (message.calibrationLutReady != null && Object.hasOwnProperty.call(message, "calibrationLutReady"))
            writer.uint32(/* id 28, wireType 0 =*/224).bool(message.calibrationLutReady);
        return writer;
    };

    /**
     * Encodes the specified AnalogStatus message, length delimited. Does not implicitly {@link AnalogStatus.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AnalogStatus
     * @static
     * @param {IAnalogStatus} message AnalogStatus message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogStatus.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AnalogStatus message from the specified reader or buffer.
     * @function decode
     * @memberof AnalogStatus
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AnalogStatus} AnalogStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogStatus.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AnalogStatus();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.seq = reader.uint32();
                    break;
                }
            case 2: {
                    message.valid = reader.bool();
                    break;
                }
            case 3: {
                    message.timestampUs = reader.uint64();
                    break;
                }
            case 4: {
                    message.ageUs = reader.uint32();
                    break;
                }
            case 5: {
                    message.targetTriplesPerCycle = reader.uint32();
                    break;
                }
            case 6: {
                    message.measuredTriplesPerSecond = reader.uint32();
                    break;
                }
            case 7: {
                    message.rawAn3 = reader.uint32();
                    break;
                }
            case 8: {
                    message.rawAn5 = reader.uint32();
                    break;
                }
            case 9: {
                    message.rawAn6 = reader.uint32();
                    break;
                }
            case 10: {
                    message.calibratedAn3 = reader.float();
                    break;
                }
            case 11: {
                    message.calibratedAn5 = reader.float();
                    break;
                }
            case 12: {
                    message.calibratedAn6 = reader.float();
                    break;
                }
            case 13: {
                    message.latencyMinUs = reader.uint32();
                    break;
                }
            case 14: {
                    message.latencyAvgUs = reader.uint32();
                    break;
                }
            case 15: {
                    message.latencyP95Us = reader.uint32();
                    break;
                }
            case 16: {
                    message.latencyMaxUs = reader.uint32();
                    break;
                }
            case 17: {
                    message.overflowCount = reader.uint32();
                    break;
                }
            case 18: {
                    message.missCount = reader.uint32();
                    break;
                }
            case 19: {
                    message.consecutiveMisses = reader.uint32();
                    break;
                }
            case 20: {
                    message.faultCode = reader.uint32();
                    break;
                }
            case 21: {
                    message.acquisitionMode = reader.uint32();
                    break;
                }
            case 22: {
                    message.samplesRead = reader.uint32();
                    break;
                }
            case 23: {
                    message.samplesRejected = reader.uint32();
                    break;
                }
            case 24: {
                    message.channelOrderAnomalies = reader.uint32();
                    break;
                }
            case 25: {
                    message.partialTriples = reader.uint32();
                    break;
                }
            case 26: {
                    message.frameDrops = reader.uint32();
                    break;
                }
            case 27: {
                    message.poolFlushes = reader.uint32();
                    break;
                }
            case 28: {
                    message.calibrationLutReady = reader.bool();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AnalogStatus message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AnalogStatus
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AnalogStatus} AnalogStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogStatus.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AnalogStatus message.
     * @function verify
     * @memberof AnalogStatus
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AnalogStatus.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.seq != null && message.hasOwnProperty("seq"))
            if (!$util.isInteger(message.seq))
                return "seq: integer expected";
        if (message.valid != null && message.hasOwnProperty("valid"))
            if (typeof message.valid !== "boolean")
                return "valid: boolean expected";
        if (message.timestampUs != null && message.hasOwnProperty("timestampUs"))
            if (!$util.isInteger(message.timestampUs) && !(message.timestampUs && $util.isInteger(message.timestampUs.low) && $util.isInteger(message.timestampUs.high)))
                return "timestampUs: integer|Long expected";
        if (message.ageUs != null && message.hasOwnProperty("ageUs"))
            if (!$util.isInteger(message.ageUs))
                return "ageUs: integer expected";
        if (message.targetTriplesPerCycle != null && message.hasOwnProperty("targetTriplesPerCycle"))
            if (!$util.isInteger(message.targetTriplesPerCycle))
                return "targetTriplesPerCycle: integer expected";
        if (message.measuredTriplesPerSecond != null && message.hasOwnProperty("measuredTriplesPerSecond"))
            if (!$util.isInteger(message.measuredTriplesPerSecond))
                return "measuredTriplesPerSecond: integer expected";
        if (message.rawAn3 != null && message.hasOwnProperty("rawAn3"))
            if (!$util.isInteger(message.rawAn3))
                return "rawAn3: integer expected";
        if (message.rawAn5 != null && message.hasOwnProperty("rawAn5"))
            if (!$util.isInteger(message.rawAn5))
                return "rawAn5: integer expected";
        if (message.rawAn6 != null && message.hasOwnProperty("rawAn6"))
            if (!$util.isInteger(message.rawAn6))
                return "rawAn6: integer expected";
        if (message.calibratedAn3 != null && message.hasOwnProperty("calibratedAn3"))
            if (typeof message.calibratedAn3 !== "number")
                return "calibratedAn3: number expected";
        if (message.calibratedAn5 != null && message.hasOwnProperty("calibratedAn5"))
            if (typeof message.calibratedAn5 !== "number")
                return "calibratedAn5: number expected";
        if (message.calibratedAn6 != null && message.hasOwnProperty("calibratedAn6"))
            if (typeof message.calibratedAn6 !== "number")
                return "calibratedAn6: number expected";
        if (message.latencyMinUs != null && message.hasOwnProperty("latencyMinUs"))
            if (!$util.isInteger(message.latencyMinUs))
                return "latencyMinUs: integer expected";
        if (message.latencyAvgUs != null && message.hasOwnProperty("latencyAvgUs"))
            if (!$util.isInteger(message.latencyAvgUs))
                return "latencyAvgUs: integer expected";
        if (message.latencyP95Us != null && message.hasOwnProperty("latencyP95Us"))
            if (!$util.isInteger(message.latencyP95Us))
                return "latencyP95Us: integer expected";
        if (message.latencyMaxUs != null && message.hasOwnProperty("latencyMaxUs"))
            if (!$util.isInteger(message.latencyMaxUs))
                return "latencyMaxUs: integer expected";
        if (message.overflowCount != null && message.hasOwnProperty("overflowCount"))
            if (!$util.isInteger(message.overflowCount))
                return "overflowCount: integer expected";
        if (message.missCount != null && message.hasOwnProperty("missCount"))
            if (!$util.isInteger(message.missCount))
                return "missCount: integer expected";
        if (message.consecutiveMisses != null && message.hasOwnProperty("consecutiveMisses"))
            if (!$util.isInteger(message.consecutiveMisses))
                return "consecutiveMisses: integer expected";
        if (message.faultCode != null && message.hasOwnProperty("faultCode"))
            if (!$util.isInteger(message.faultCode))
                return "faultCode: integer expected";
        if (message.acquisitionMode != null && message.hasOwnProperty("acquisitionMode"))
            if (!$util.isInteger(message.acquisitionMode))
                return "acquisitionMode: integer expected";
        if (message.samplesRead != null && message.hasOwnProperty("samplesRead"))
            if (!$util.isInteger(message.samplesRead))
                return "samplesRead: integer expected";
        if (message.samplesRejected != null && message.hasOwnProperty("samplesRejected"))
            if (!$util.isInteger(message.samplesRejected))
                return "samplesRejected: integer expected";
        if (message.channelOrderAnomalies != null && message.hasOwnProperty("channelOrderAnomalies"))
            if (!$util.isInteger(message.channelOrderAnomalies))
                return "channelOrderAnomalies: integer expected";
        if (message.partialTriples != null && message.hasOwnProperty("partialTriples"))
            if (!$util.isInteger(message.partialTriples))
                return "partialTriples: integer expected";
        if (message.frameDrops != null && message.hasOwnProperty("frameDrops"))
            if (!$util.isInteger(message.frameDrops))
                return "frameDrops: integer expected";
        if (message.poolFlushes != null && message.hasOwnProperty("poolFlushes"))
            if (!$util.isInteger(message.poolFlushes))
                return "poolFlushes: integer expected";
        if (message.calibrationLutReady != null && message.hasOwnProperty("calibrationLutReady"))
            if (typeof message.calibrationLutReady !== "boolean")
                return "calibrationLutReady: boolean expected";
        return null;
    };

    /**
     * Creates an AnalogStatus message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AnalogStatus
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AnalogStatus} AnalogStatus
     */
    AnalogStatus.fromObject = function fromObject(object) {
        if (object instanceof $root.AnalogStatus)
            return object;
        let message = new $root.AnalogStatus();
        if (object.seq != null)
            message.seq = object.seq >>> 0;
        if (object.valid != null)
            message.valid = Boolean(object.valid);
        if (object.timestampUs != null)
            if ($util.Long)
                (message.timestampUs = $util.Long.fromValue(object.timestampUs)).unsigned = true;
            else if (typeof object.timestampUs === "string")
                message.timestampUs = parseInt(object.timestampUs, 10);
            else if (typeof object.timestampUs === "number")
                message.timestampUs = object.timestampUs;
            else if (typeof object.timestampUs === "object")
                message.timestampUs = new $util.LongBits(object.timestampUs.low >>> 0, object.timestampUs.high >>> 0).toNumber(true);
        if (object.ageUs != null)
            message.ageUs = object.ageUs >>> 0;
        if (object.targetTriplesPerCycle != null)
            message.targetTriplesPerCycle = object.targetTriplesPerCycle >>> 0;
        if (object.measuredTriplesPerSecond != null)
            message.measuredTriplesPerSecond = object.measuredTriplesPerSecond >>> 0;
        if (object.rawAn3 != null)
            message.rawAn3 = object.rawAn3 >>> 0;
        if (object.rawAn5 != null)
            message.rawAn5 = object.rawAn5 >>> 0;
        if (object.rawAn6 != null)
            message.rawAn6 = object.rawAn6 >>> 0;
        if (object.calibratedAn3 != null)
            message.calibratedAn3 = Number(object.calibratedAn3);
        if (object.calibratedAn5 != null)
            message.calibratedAn5 = Number(object.calibratedAn5);
        if (object.calibratedAn6 != null)
            message.calibratedAn6 = Number(object.calibratedAn6);
        if (object.latencyMinUs != null)
            message.latencyMinUs = object.latencyMinUs >>> 0;
        if (object.latencyAvgUs != null)
            message.latencyAvgUs = object.latencyAvgUs >>> 0;
        if (object.latencyP95Us != null)
            message.latencyP95Us = object.latencyP95Us >>> 0;
        if (object.latencyMaxUs != null)
            message.latencyMaxUs = object.latencyMaxUs >>> 0;
        if (object.overflowCount != null)
            message.overflowCount = object.overflowCount >>> 0;
        if (object.missCount != null)
            message.missCount = object.missCount >>> 0;
        if (object.consecutiveMisses != null)
            message.consecutiveMisses = object.consecutiveMisses >>> 0;
        if (object.faultCode != null)
            message.faultCode = object.faultCode >>> 0;
        if (object.acquisitionMode != null)
            message.acquisitionMode = object.acquisitionMode >>> 0;
        if (object.samplesRead != null)
            message.samplesRead = object.samplesRead >>> 0;
        if (object.samplesRejected != null)
            message.samplesRejected = object.samplesRejected >>> 0;
        if (object.channelOrderAnomalies != null)
            message.channelOrderAnomalies = object.channelOrderAnomalies >>> 0;
        if (object.partialTriples != null)
            message.partialTriples = object.partialTriples >>> 0;
        if (object.frameDrops != null)
            message.frameDrops = object.frameDrops >>> 0;
        if (object.poolFlushes != null)
            message.poolFlushes = object.poolFlushes >>> 0;
        if (object.calibrationLutReady != null)
            message.calibrationLutReady = Boolean(object.calibrationLutReady);
        return message;
    };

    /**
     * Creates a plain object from an AnalogStatus message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AnalogStatus
     * @static
     * @param {AnalogStatus} message AnalogStatus
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AnalogStatus.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.seq = 0;
            object.valid = false;
            if ($util.Long) {
                let long = new $util.Long(0, 0, true);
                object.timestampUs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.timestampUs = options.longs === String ? "0" : 0;
            object.ageUs = 0;
            object.targetTriplesPerCycle = 0;
            object.measuredTriplesPerSecond = 0;
            object.rawAn3 = 0;
            object.rawAn5 = 0;
            object.rawAn6 = 0;
            object.calibratedAn3 = 0;
            object.calibratedAn5 = 0;
            object.calibratedAn6 = 0;
            object.latencyMinUs = 0;
            object.latencyAvgUs = 0;
            object.latencyP95Us = 0;
            object.latencyMaxUs = 0;
            object.overflowCount = 0;
            object.missCount = 0;
            object.consecutiveMisses = 0;
            object.faultCode = 0;
            object.acquisitionMode = 0;
            object.samplesRead = 0;
            object.samplesRejected = 0;
            object.channelOrderAnomalies = 0;
            object.partialTriples = 0;
            object.frameDrops = 0;
            object.poolFlushes = 0;
            object.calibrationLutReady = false;
        }
        if (message.seq != null && message.hasOwnProperty("seq"))
            object.seq = message.seq;
        if (message.valid != null && message.hasOwnProperty("valid"))
            object.valid = message.valid;
        if (message.timestampUs != null && message.hasOwnProperty("timestampUs"))
            if (typeof message.timestampUs === "number")
                object.timestampUs = options.longs === String ? String(message.timestampUs) : message.timestampUs;
            else
                object.timestampUs = options.longs === String ? $util.Long.prototype.toString.call(message.timestampUs) : options.longs === Number ? new $util.LongBits(message.timestampUs.low >>> 0, message.timestampUs.high >>> 0).toNumber(true) : message.timestampUs;
        if (message.ageUs != null && message.hasOwnProperty("ageUs"))
            object.ageUs = message.ageUs;
        if (message.targetTriplesPerCycle != null && message.hasOwnProperty("targetTriplesPerCycle"))
            object.targetTriplesPerCycle = message.targetTriplesPerCycle;
        if (message.measuredTriplesPerSecond != null && message.hasOwnProperty("measuredTriplesPerSecond"))
            object.measuredTriplesPerSecond = message.measuredTriplesPerSecond;
        if (message.rawAn3 != null && message.hasOwnProperty("rawAn3"))
            object.rawAn3 = message.rawAn3;
        if (message.rawAn5 != null && message.hasOwnProperty("rawAn5"))
            object.rawAn5 = message.rawAn5;
        if (message.rawAn6 != null && message.hasOwnProperty("rawAn6"))
            object.rawAn6 = message.rawAn6;
        if (message.calibratedAn3 != null && message.hasOwnProperty("calibratedAn3"))
            object.calibratedAn3 = options.json && !isFinite(message.calibratedAn3) ? String(message.calibratedAn3) : message.calibratedAn3;
        if (message.calibratedAn5 != null && message.hasOwnProperty("calibratedAn5"))
            object.calibratedAn5 = options.json && !isFinite(message.calibratedAn5) ? String(message.calibratedAn5) : message.calibratedAn5;
        if (message.calibratedAn6 != null && message.hasOwnProperty("calibratedAn6"))
            object.calibratedAn6 = options.json && !isFinite(message.calibratedAn6) ? String(message.calibratedAn6) : message.calibratedAn6;
        if (message.latencyMinUs != null && message.hasOwnProperty("latencyMinUs"))
            object.latencyMinUs = message.latencyMinUs;
        if (message.latencyAvgUs != null && message.hasOwnProperty("latencyAvgUs"))
            object.latencyAvgUs = message.latencyAvgUs;
        if (message.latencyP95Us != null && message.hasOwnProperty("latencyP95Us"))
            object.latencyP95Us = message.latencyP95Us;
        if (message.latencyMaxUs != null && message.hasOwnProperty("latencyMaxUs"))
            object.latencyMaxUs = message.latencyMaxUs;
        if (message.overflowCount != null && message.hasOwnProperty("overflowCount"))
            object.overflowCount = message.overflowCount;
        if (message.missCount != null && message.hasOwnProperty("missCount"))
            object.missCount = message.missCount;
        if (message.consecutiveMisses != null && message.hasOwnProperty("consecutiveMisses"))
            object.consecutiveMisses = message.consecutiveMisses;
        if (message.faultCode != null && message.hasOwnProperty("faultCode"))
            object.faultCode = message.faultCode;
        if (message.acquisitionMode != null && message.hasOwnProperty("acquisitionMode"))
            object.acquisitionMode = message.acquisitionMode;
        if (message.samplesRead != null && message.hasOwnProperty("samplesRead"))
            object.samplesRead = message.samplesRead;
        if (message.samplesRejected != null && message.hasOwnProperty("samplesRejected"))
            object.samplesRejected = message.samplesRejected;
        if (message.channelOrderAnomalies != null && message.hasOwnProperty("channelOrderAnomalies"))
            object.channelOrderAnomalies = message.channelOrderAnomalies;
        if (message.partialTriples != null && message.hasOwnProperty("partialTriples"))
            object.partialTriples = message.partialTriples;
        if (message.frameDrops != null && message.hasOwnProperty("frameDrops"))
            object.frameDrops = message.frameDrops;
        if (message.poolFlushes != null && message.hasOwnProperty("poolFlushes"))
            object.poolFlushes = message.poolFlushes;
        if (message.calibrationLutReady != null && message.hasOwnProperty("calibrationLutReady"))
            object.calibrationLutReady = message.calibrationLutReady;
        return object;
    };

    /**
     * Converts this AnalogStatus to JSON.
     * @function toJSON
     * @memberof AnalogStatus
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AnalogStatus.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AnalogStatus
     * @function getTypeUrl
     * @memberof AnalogStatus
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AnalogStatus.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AnalogStatus";
    };

    return AnalogStatus;
})();

export const SystemStatus = $root.SystemStatus = (() => {

    /**
     * Properties of a SystemStatus.
     * @exports ISystemStatus
     * @interface ISystemStatus
     * @property {BleSignalSet|null} [activeSet] SystemStatus activeSet
     * @property {BleSignalState|null} [signalState] SystemStatus signalState
     * @property {BleAnalogReadState|null} [bleReadState] SystemStatus bleReadState
     * @property {BleControlState|null} [controlState] SystemStatus controlState
     * @property {number|null} [alpha] SystemStatus alpha
     * @property {boolean|null} [hasAlpha] SystemStatus hasAlpha
     * @property {boolean|null} [matrixAValid] SystemStatus matrixAValid
     * @property {boolean|null} [matrixBValid] SystemStatus matrixBValid
     * @property {number|null} [currentCycles] SystemStatus currentCycles
     * @property {number|null} [totalCycles] SystemStatus totalCycles
     * @property {number|null} [monitorMs] SystemStatus monitorMs
     * @property {number|null} [deadTimeUs] SystemStatus deadTimeUs
     * @property {BleLedMode|null} [ledMode] SystemStatus ledMode
     * @property {boolean|null} [bleCongested] SystemStatus bleCongested
     * @property {number|null} [adcMin] SystemStatus adcMin
     * @property {number|null} [adcMax] SystemStatus adcMax
     * @property {number|null} [adcAvg] SystemStatus adcAvg
     * @property {number|null} [deadTimeTailOverheadCycles] SystemStatus deadTimeTailOverheadCycles
     * @property {IAnalogStatus|null} [analog] SystemStatus analog
     */

    /**
     * Constructs a new SystemStatus.
     * @exports SystemStatus
     * @classdesc Represents a SystemStatus.
     * @implements ISystemStatus
     * @constructor
     * @param {ISystemStatus=} [properties] Properties to set
     */
    function SystemStatus(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * SystemStatus activeSet.
     * @member {BleSignalSet} activeSet
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.activeSet = 0;

    /**
     * SystemStatus signalState.
     * @member {BleSignalState} signalState
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.signalState = 0;

    /**
     * SystemStatus bleReadState.
     * @member {BleAnalogReadState} bleReadState
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.bleReadState = 0;

    /**
     * SystemStatus controlState.
     * @member {BleControlState} controlState
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.controlState = 0;

    /**
     * SystemStatus alpha.
     * @member {number} alpha
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.alpha = 0;

    /**
     * SystemStatus hasAlpha.
     * @member {boolean} hasAlpha
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.hasAlpha = false;

    /**
     * SystemStatus matrixAValid.
     * @member {boolean} matrixAValid
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.matrixAValid = false;

    /**
     * SystemStatus matrixBValid.
     * @member {boolean} matrixBValid
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.matrixBValid = false;

    /**
     * SystemStatus currentCycles.
     * @member {number} currentCycles
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.currentCycles = 0;

    /**
     * SystemStatus totalCycles.
     * @member {number} totalCycles
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.totalCycles = 0;

    /**
     * SystemStatus monitorMs.
     * @member {number} monitorMs
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.monitorMs = 0;

    /**
     * SystemStatus deadTimeUs.
     * @member {number} deadTimeUs
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.deadTimeUs = 0;

    /**
     * SystemStatus ledMode.
     * @member {BleLedMode} ledMode
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.ledMode = 0;

    /**
     * SystemStatus bleCongested.
     * @member {boolean} bleCongested
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.bleCongested = false;

    /**
     * SystemStatus adcMin.
     * @member {number} adcMin
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.adcMin = 0;

    /**
     * SystemStatus adcMax.
     * @member {number} adcMax
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.adcMax = 0;

    /**
     * SystemStatus adcAvg.
     * @member {number} adcAvg
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.adcAvg = 0;

    /**
     * SystemStatus deadTimeTailOverheadCycles.
     * @member {number} deadTimeTailOverheadCycles
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.deadTimeTailOverheadCycles = 0;

    /**
     * SystemStatus analog.
     * @member {IAnalogStatus|null|undefined} analog
     * @memberof SystemStatus
     * @instance
     */
    SystemStatus.prototype.analog = null;

    /**
     * Creates a new SystemStatus instance using the specified properties.
     * @function create
     * @memberof SystemStatus
     * @static
     * @param {ISystemStatus=} [properties] Properties to set
     * @returns {SystemStatus} SystemStatus instance
     */
    SystemStatus.create = function create(properties) {
        return new SystemStatus(properties);
    };

    /**
     * Encodes the specified SystemStatus message. Does not implicitly {@link SystemStatus.verify|verify} messages.
     * @function encode
     * @memberof SystemStatus
     * @static
     * @param {ISystemStatus} message SystemStatus message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    SystemStatus.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.activeSet != null && Object.hasOwnProperty.call(message, "activeSet"))
            writer.uint32(/* id 1, wireType 0 =*/8).int32(message.activeSet);
        if (message.signalState != null && Object.hasOwnProperty.call(message, "signalState"))
            writer.uint32(/* id 2, wireType 0 =*/16).int32(message.signalState);
        if (message.bleReadState != null && Object.hasOwnProperty.call(message, "bleReadState"))
            writer.uint32(/* id 3, wireType 0 =*/24).int32(message.bleReadState);
        if (message.controlState != null && Object.hasOwnProperty.call(message, "controlState"))
            writer.uint32(/* id 4, wireType 0 =*/32).int32(message.controlState);
        if (message.alpha != null && Object.hasOwnProperty.call(message, "alpha"))
            writer.uint32(/* id 5, wireType 5 =*/45).float(message.alpha);
        if (message.hasAlpha != null && Object.hasOwnProperty.call(message, "hasAlpha"))
            writer.uint32(/* id 6, wireType 0 =*/48).bool(message.hasAlpha);
        if (message.matrixAValid != null && Object.hasOwnProperty.call(message, "matrixAValid"))
            writer.uint32(/* id 7, wireType 0 =*/56).bool(message.matrixAValid);
        if (message.matrixBValid != null && Object.hasOwnProperty.call(message, "matrixBValid"))
            writer.uint32(/* id 8, wireType 0 =*/64).bool(message.matrixBValid);
        if (message.currentCycles != null && Object.hasOwnProperty.call(message, "currentCycles"))
            writer.uint32(/* id 9, wireType 0 =*/72).uint32(message.currentCycles);
        if (message.totalCycles != null && Object.hasOwnProperty.call(message, "totalCycles"))
            writer.uint32(/* id 10, wireType 0 =*/80).uint32(message.totalCycles);
        if (message.monitorMs != null && Object.hasOwnProperty.call(message, "monitorMs"))
            writer.uint32(/* id 11, wireType 0 =*/88).uint32(message.monitorMs);
        if (message.deadTimeUs != null && Object.hasOwnProperty.call(message, "deadTimeUs"))
            writer.uint32(/* id 12, wireType 0 =*/96).uint32(message.deadTimeUs);
        if (message.ledMode != null && Object.hasOwnProperty.call(message, "ledMode"))
            writer.uint32(/* id 14, wireType 0 =*/112).int32(message.ledMode);
        if (message.bleCongested != null && Object.hasOwnProperty.call(message, "bleCongested"))
            writer.uint32(/* id 15, wireType 0 =*/120).bool(message.bleCongested);
        if (message.adcMin != null && Object.hasOwnProperty.call(message, "adcMin"))
            writer.uint32(/* id 16, wireType 0 =*/128).uint32(message.adcMin);
        if (message.adcMax != null && Object.hasOwnProperty.call(message, "adcMax"))
            writer.uint32(/* id 17, wireType 0 =*/136).uint32(message.adcMax);
        if (message.adcAvg != null && Object.hasOwnProperty.call(message, "adcAvg"))
            writer.uint32(/* id 18, wireType 0 =*/144).uint32(message.adcAvg);
        if (message.deadTimeTailOverheadCycles != null && Object.hasOwnProperty.call(message, "deadTimeTailOverheadCycles"))
            writer.uint32(/* id 19, wireType 0 =*/152).uint32(message.deadTimeTailOverheadCycles);
        if (message.analog != null && Object.hasOwnProperty.call(message, "analog"))
            $root.AnalogStatus.encode(message.analog, writer.uint32(/* id 20, wireType 2 =*/162).fork()).ldelim();
        return writer;
    };

    /**
     * Encodes the specified SystemStatus message, length delimited. Does not implicitly {@link SystemStatus.verify|verify} messages.
     * @function encodeDelimited
     * @memberof SystemStatus
     * @static
     * @param {ISystemStatus} message SystemStatus message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    SystemStatus.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a SystemStatus message from the specified reader or buffer.
     * @function decode
     * @memberof SystemStatus
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {SystemStatus} SystemStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    SystemStatus.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.SystemStatus();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.activeSet = reader.int32();
                    break;
                }
            case 2: {
                    message.signalState = reader.int32();
                    break;
                }
            case 3: {
                    message.bleReadState = reader.int32();
                    break;
                }
            case 4: {
                    message.controlState = reader.int32();
                    break;
                }
            case 5: {
                    message.alpha = reader.float();
                    break;
                }
            case 6: {
                    message.hasAlpha = reader.bool();
                    break;
                }
            case 7: {
                    message.matrixAValid = reader.bool();
                    break;
                }
            case 8: {
                    message.matrixBValid = reader.bool();
                    break;
                }
            case 9: {
                    message.currentCycles = reader.uint32();
                    break;
                }
            case 10: {
                    message.totalCycles = reader.uint32();
                    break;
                }
            case 11: {
                    message.monitorMs = reader.uint32();
                    break;
                }
            case 12: {
                    message.deadTimeUs = reader.uint32();
                    break;
                }
            case 14: {
                    message.ledMode = reader.int32();
                    break;
                }
            case 15: {
                    message.bleCongested = reader.bool();
                    break;
                }
            case 16: {
                    message.adcMin = reader.uint32();
                    break;
                }
            case 17: {
                    message.adcMax = reader.uint32();
                    break;
                }
            case 18: {
                    message.adcAvg = reader.uint32();
                    break;
                }
            case 19: {
                    message.deadTimeTailOverheadCycles = reader.uint32();
                    break;
                }
            case 20: {
                    message.analog = $root.AnalogStatus.decode(reader, reader.uint32());
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a SystemStatus message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof SystemStatus
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {SystemStatus} SystemStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    SystemStatus.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a SystemStatus message.
     * @function verify
     * @memberof SystemStatus
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    SystemStatus.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.activeSet != null && message.hasOwnProperty("activeSet"))
            switch (message.activeSet) {
            default:
                return "activeSet: enum value expected";
            case 0:
            case 1:
                break;
            }
        if (message.signalState != null && message.hasOwnProperty("signalState"))
            switch (message.signalState) {
            default:
                return "signalState: enum value expected";
            case 0:
            case 1:
                break;
            }
        if (message.bleReadState != null && message.hasOwnProperty("bleReadState"))
            switch (message.bleReadState) {
            default:
                return "bleReadState: enum value expected";
            case 0:
            case 1:
            case 2:
                break;
            }
        if (message.controlState != null && message.hasOwnProperty("controlState"))
            switch (message.controlState) {
            default:
                return "controlState: enum value expected";
            case 0:
            case 1:
                break;
            }
        if (message.alpha != null && message.hasOwnProperty("alpha"))
            if (typeof message.alpha !== "number")
                return "alpha: number expected";
        if (message.hasAlpha != null && message.hasOwnProperty("hasAlpha"))
            if (typeof message.hasAlpha !== "boolean")
                return "hasAlpha: boolean expected";
        if (message.matrixAValid != null && message.hasOwnProperty("matrixAValid"))
            if (typeof message.matrixAValid !== "boolean")
                return "matrixAValid: boolean expected";
        if (message.matrixBValid != null && message.hasOwnProperty("matrixBValid"))
            if (typeof message.matrixBValid !== "boolean")
                return "matrixBValid: boolean expected";
        if (message.currentCycles != null && message.hasOwnProperty("currentCycles"))
            if (!$util.isInteger(message.currentCycles))
                return "currentCycles: integer expected";
        if (message.totalCycles != null && message.hasOwnProperty("totalCycles"))
            if (!$util.isInteger(message.totalCycles))
                return "totalCycles: integer expected";
        if (message.monitorMs != null && message.hasOwnProperty("monitorMs"))
            if (!$util.isInteger(message.monitorMs))
                return "monitorMs: integer expected";
        if (message.deadTimeUs != null && message.hasOwnProperty("deadTimeUs"))
            if (!$util.isInteger(message.deadTimeUs))
                return "deadTimeUs: integer expected";
        if (message.ledMode != null && message.hasOwnProperty("ledMode"))
            switch (message.ledMode) {
            default:
                return "ledMode: enum value expected";
            case 0:
            case 1:
                break;
            }
        if (message.bleCongested != null && message.hasOwnProperty("bleCongested"))
            if (typeof message.bleCongested !== "boolean")
                return "bleCongested: boolean expected";
        if (message.adcMin != null && message.hasOwnProperty("adcMin"))
            if (!$util.isInteger(message.adcMin))
                return "adcMin: integer expected";
        if (message.adcMax != null && message.hasOwnProperty("adcMax"))
            if (!$util.isInteger(message.adcMax))
                return "adcMax: integer expected";
        if (message.adcAvg != null && message.hasOwnProperty("adcAvg"))
            if (!$util.isInteger(message.adcAvg))
                return "adcAvg: integer expected";
        if (message.deadTimeTailOverheadCycles != null && message.hasOwnProperty("deadTimeTailOverheadCycles"))
            if (!$util.isInteger(message.deadTimeTailOverheadCycles))
                return "deadTimeTailOverheadCycles: integer expected";
        if (message.analog != null && message.hasOwnProperty("analog")) {
            let error = $root.AnalogStatus.verify(message.analog);
            if (error)
                return "analog." + error;
        }
        return null;
    };

    /**
     * Creates a SystemStatus message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof SystemStatus
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {SystemStatus} SystemStatus
     */
    SystemStatus.fromObject = function fromObject(object) {
        if (object instanceof $root.SystemStatus)
            return object;
        let message = new $root.SystemStatus();
        switch (object.activeSet) {
        default:
            if (typeof object.activeSet === "number") {
                message.activeSet = object.activeSet;
                break;
            }
            break;
        case "BLE_SET_A":
        case 0:
            message.activeSet = 0;
            break;
        case "BLE_SET_B":
        case 1:
            message.activeSet = 1;
            break;
        }
        switch (object.signalState) {
        default:
            if (typeof object.signalState === "number") {
                message.signalState = object.signalState;
                break;
            }
            break;
        case "BLE_SIG_IDLE":
        case 0:
            message.signalState = 0;
            break;
        case "BLE_SIG_RUNNING":
        case 1:
            message.signalState = 1;
            break;
        }
        switch (object.bleReadState) {
        default:
            if (typeof object.bleReadState === "number") {
                message.bleReadState = object.bleReadState;
                break;
            }
            break;
        case "BLE_READ_IDLE":
        case 0:
            message.bleReadState = 0;
            break;
        case "BLE_READING":
        case 1:
            message.bleReadState = 1;
            break;
        case "BLE_READ_DISABLED":
        case 2:
            message.bleReadState = 2;
            break;
        }
        switch (object.controlState) {
        default:
            if (typeof object.controlState === "number") {
                message.controlState = object.controlState;
                break;
            }
            break;
        case "BLE_CTRL_OFF":
        case 0:
            message.controlState = 0;
            break;
        case "BLE_CTRL_ON":
        case 1:
            message.controlState = 1;
            break;
        }
        if (object.alpha != null)
            message.alpha = Number(object.alpha);
        if (object.hasAlpha != null)
            message.hasAlpha = Boolean(object.hasAlpha);
        if (object.matrixAValid != null)
            message.matrixAValid = Boolean(object.matrixAValid);
        if (object.matrixBValid != null)
            message.matrixBValid = Boolean(object.matrixBValid);
        if (object.currentCycles != null)
            message.currentCycles = object.currentCycles >>> 0;
        if (object.totalCycles != null)
            message.totalCycles = object.totalCycles >>> 0;
        if (object.monitorMs != null)
            message.monitorMs = object.monitorMs >>> 0;
        if (object.deadTimeUs != null)
            message.deadTimeUs = object.deadTimeUs >>> 0;
        switch (object.ledMode) {
        default:
            if (typeof object.ledMode === "number") {
                message.ledMode = object.ledMode;
                break;
            }
            break;
        case "LED_NORMAL":
        case 0:
            message.ledMode = 0;
            break;
        case "LED_BLINKING":
        case 1:
            message.ledMode = 1;
            break;
        }
        if (object.bleCongested != null)
            message.bleCongested = Boolean(object.bleCongested);
        if (object.adcMin != null)
            message.adcMin = object.adcMin >>> 0;
        if (object.adcMax != null)
            message.adcMax = object.adcMax >>> 0;
        if (object.adcAvg != null)
            message.adcAvg = object.adcAvg >>> 0;
        if (object.deadTimeTailOverheadCycles != null)
            message.deadTimeTailOverheadCycles = object.deadTimeTailOverheadCycles >>> 0;
        if (object.analog != null) {
            if (typeof object.analog !== "object")
                throw TypeError(".SystemStatus.analog: object expected");
            message.analog = $root.AnalogStatus.fromObject(object.analog);
        }
        return message;
    };

    /**
     * Creates a plain object from a SystemStatus message. Also converts values to other types if specified.
     * @function toObject
     * @memberof SystemStatus
     * @static
     * @param {SystemStatus} message SystemStatus
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    SystemStatus.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.activeSet = options.enums === String ? "BLE_SET_A" : 0;
            object.signalState = options.enums === String ? "BLE_SIG_IDLE" : 0;
            object.bleReadState = options.enums === String ? "BLE_READ_IDLE" : 0;
            object.controlState = options.enums === String ? "BLE_CTRL_OFF" : 0;
            object.alpha = 0;
            object.hasAlpha = false;
            object.matrixAValid = false;
            object.matrixBValid = false;
            object.currentCycles = 0;
            object.totalCycles = 0;
            object.monitorMs = 0;
            object.deadTimeUs = 0;
            object.ledMode = options.enums === String ? "LED_NORMAL" : 0;
            object.bleCongested = false;
            object.adcMin = 0;
            object.adcMax = 0;
            object.adcAvg = 0;
            object.deadTimeTailOverheadCycles = 0;
            object.analog = null;
        }
        if (message.activeSet != null && message.hasOwnProperty("activeSet"))
            object.activeSet = options.enums === String ? $root.BleSignalSet[message.activeSet] === undefined ? message.activeSet : $root.BleSignalSet[message.activeSet] : message.activeSet;
        if (message.signalState != null && message.hasOwnProperty("signalState"))
            object.signalState = options.enums === String ? $root.BleSignalState[message.signalState] === undefined ? message.signalState : $root.BleSignalState[message.signalState] : message.signalState;
        if (message.bleReadState != null && message.hasOwnProperty("bleReadState"))
            object.bleReadState = options.enums === String ? $root.BleAnalogReadState[message.bleReadState] === undefined ? message.bleReadState : $root.BleAnalogReadState[message.bleReadState] : message.bleReadState;
        if (message.controlState != null && message.hasOwnProperty("controlState"))
            object.controlState = options.enums === String ? $root.BleControlState[message.controlState] === undefined ? message.controlState : $root.BleControlState[message.controlState] : message.controlState;
        if (message.alpha != null && message.hasOwnProperty("alpha"))
            object.alpha = options.json && !isFinite(message.alpha) ? String(message.alpha) : message.alpha;
        if (message.hasAlpha != null && message.hasOwnProperty("hasAlpha"))
            object.hasAlpha = message.hasAlpha;
        if (message.matrixAValid != null && message.hasOwnProperty("matrixAValid"))
            object.matrixAValid = message.matrixAValid;
        if (message.matrixBValid != null && message.hasOwnProperty("matrixBValid"))
            object.matrixBValid = message.matrixBValid;
        if (message.currentCycles != null && message.hasOwnProperty("currentCycles"))
            object.currentCycles = message.currentCycles;
        if (message.totalCycles != null && message.hasOwnProperty("totalCycles"))
            object.totalCycles = message.totalCycles;
        if (message.monitorMs != null && message.hasOwnProperty("monitorMs"))
            object.monitorMs = message.monitorMs;
        if (message.deadTimeUs != null && message.hasOwnProperty("deadTimeUs"))
            object.deadTimeUs = message.deadTimeUs;
        if (message.ledMode != null && message.hasOwnProperty("ledMode"))
            object.ledMode = options.enums === String ? $root.BleLedMode[message.ledMode] === undefined ? message.ledMode : $root.BleLedMode[message.ledMode] : message.ledMode;
        if (message.bleCongested != null && message.hasOwnProperty("bleCongested"))
            object.bleCongested = message.bleCongested;
        if (message.adcMin != null && message.hasOwnProperty("adcMin"))
            object.adcMin = message.adcMin;
        if (message.adcMax != null && message.hasOwnProperty("adcMax"))
            object.adcMax = message.adcMax;
        if (message.adcAvg != null && message.hasOwnProperty("adcAvg"))
            object.adcAvg = message.adcAvg;
        if (message.deadTimeTailOverheadCycles != null && message.hasOwnProperty("deadTimeTailOverheadCycles"))
            object.deadTimeTailOverheadCycles = message.deadTimeTailOverheadCycles;
        if (message.analog != null && message.hasOwnProperty("analog"))
            object.analog = $root.AnalogStatus.toObject(message.analog, options);
        return object;
    };

    /**
     * Converts this SystemStatus to JSON.
     * @function toJSON
     * @memberof SystemStatus
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    SystemStatus.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for SystemStatus
     * @function getTypeUrl
     * @memberof SystemStatus
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    SystemStatus.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/SystemStatus";
    };

    return SystemStatus;
})();

export const LogMessage = $root.LogMessage = (() => {

    /**
     * Properties of a LogMessage.
     * @exports ILogMessage
     * @interface ILogMessage
     * @property {BleLogLevel|null} [level] LogMessage level
     * @property {string|null} [text] LogMessage text
     */

    /**
     * Constructs a new LogMessage.
     * @exports LogMessage
     * @classdesc Represents a LogMessage.
     * @implements ILogMessage
     * @constructor
     * @param {ILogMessage=} [properties] Properties to set
     */
    function LogMessage(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * LogMessage level.
     * @member {BleLogLevel} level
     * @memberof LogMessage
     * @instance
     */
    LogMessage.prototype.level = 0;

    /**
     * LogMessage text.
     * @member {string} text
     * @memberof LogMessage
     * @instance
     */
    LogMessage.prototype.text = "";

    /**
     * Creates a new LogMessage instance using the specified properties.
     * @function create
     * @memberof LogMessage
     * @static
     * @param {ILogMessage=} [properties] Properties to set
     * @returns {LogMessage} LogMessage instance
     */
    LogMessage.create = function create(properties) {
        return new LogMessage(properties);
    };

    /**
     * Encodes the specified LogMessage message. Does not implicitly {@link LogMessage.verify|verify} messages.
     * @function encode
     * @memberof LogMessage
     * @static
     * @param {ILogMessage} message LogMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    LogMessage.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.level != null && Object.hasOwnProperty.call(message, "level"))
            writer.uint32(/* id 1, wireType 0 =*/8).int32(message.level);
        if (message.text != null && Object.hasOwnProperty.call(message, "text"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.text);
        return writer;
    };

    /**
     * Encodes the specified LogMessage message, length delimited. Does not implicitly {@link LogMessage.verify|verify} messages.
     * @function encodeDelimited
     * @memberof LogMessage
     * @static
     * @param {ILogMessage} message LogMessage message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    LogMessage.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a LogMessage message from the specified reader or buffer.
     * @function decode
     * @memberof LogMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {LogMessage} LogMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    LogMessage.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.LogMessage();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.level = reader.int32();
                    break;
                }
            case 2: {
                    message.text = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a LogMessage message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof LogMessage
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {LogMessage} LogMessage
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    LogMessage.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a LogMessage message.
     * @function verify
     * @memberof LogMessage
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    LogMessage.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.level != null && message.hasOwnProperty("level"))
            switch (message.level) {
            default:
                return "level: enum value expected";
            case 0:
            case 1:
            case 2:
                break;
            }
        if (message.text != null && message.hasOwnProperty("text"))
            if (!$util.isString(message.text))
                return "text: string expected";
        return null;
    };

    /**
     * Creates a LogMessage message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof LogMessage
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {LogMessage} LogMessage
     */
    LogMessage.fromObject = function fromObject(object) {
        if (object instanceof $root.LogMessage)
            return object;
        let message = new $root.LogMessage();
        switch (object.level) {
        default:
            if (typeof object.level === "number") {
                message.level = object.level;
                break;
            }
            break;
        case "BLE_LOG_INFO":
        case 0:
            message.level = 0;
            break;
        case "BLE_LOG_WARN":
        case 1:
            message.level = 1;
            break;
        case "BLE_LOG_ERROR":
        case 2:
            message.level = 2;
            break;
        }
        if (object.text != null)
            message.text = String(object.text);
        return message;
    };

    /**
     * Creates a plain object from a LogMessage message. Also converts values to other types if specified.
     * @function toObject
     * @memberof LogMessage
     * @static
     * @param {LogMessage} message LogMessage
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    LogMessage.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.level = options.enums === String ? "BLE_LOG_INFO" : 0;
            object.text = "";
        }
        if (message.level != null && message.hasOwnProperty("level"))
            object.level = options.enums === String ? $root.BleLogLevel[message.level] === undefined ? message.level : $root.BleLogLevel[message.level] : message.level;
        if (message.text != null && message.hasOwnProperty("text"))
            object.text = message.text;
        return object;
    };

    /**
     * Converts this LogMessage to JSON.
     * @function toJSON
     * @memberof LogMessage
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    LogMessage.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for LogMessage
     * @function getTypeUrl
     * @memberof LogMessage
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    LogMessage.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/LogMessage";
    };

    return LogMessage;
})();

/**
 * OtaState enum.
 * @exports OtaState
 * @enum {number}
 * @property {number} OTA_IDLE=0 OTA_IDLE value
 * @property {number} OTA_DOWNLOADING=1 OTA_DOWNLOADING value
 * @property {number} OTA_VERIFYING=2 OTA_VERIFYING value
 * @property {number} OTA_FINISHED=3 OTA_FINISHED value
 * @property {number} OTA_ERROR=4 OTA_ERROR value
 */
export const OtaState = $root.OtaState = (() => {
    const valuesById = {}, values = Object.create(valuesById);
    values[valuesById[0] = "OTA_IDLE"] = 0;
    values[valuesById[1] = "OTA_DOWNLOADING"] = 1;
    values[valuesById[2] = "OTA_VERIFYING"] = 2;
    values[valuesById[3] = "OTA_FINISHED"] = 3;
    values[valuesById[4] = "OTA_ERROR"] = 4;
    return values;
})();

export const OtaStatus = $root.OtaStatus = (() => {

    /**
     * Properties of an OtaStatus.
     * @exports IOtaStatus
     * @interface IOtaStatus
     * @property {OtaState|null} [state] OtaStatus state
     * @property {number|null} [progressPercent] OtaStatus progressPercent
     * @property {string|null} [message] OtaStatus message
     * @property {number|null} [writtenSize] OtaStatus writtenSize
     * @property {number|null} [expectedSeq] OtaStatus expectedSeq
     */

    /**
     * Constructs a new OtaStatus.
     * @exports OtaStatus
     * @classdesc Represents an OtaStatus.
     * @implements IOtaStatus
     * @constructor
     * @param {IOtaStatus=} [properties] Properties to set
     */
    function OtaStatus(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * OtaStatus state.
     * @member {OtaState} state
     * @memberof OtaStatus
     * @instance
     */
    OtaStatus.prototype.state = 0;

    /**
     * OtaStatus progressPercent.
     * @member {number} progressPercent
     * @memberof OtaStatus
     * @instance
     */
    OtaStatus.prototype.progressPercent = 0;

    /**
     * OtaStatus message.
     * @member {string} message
     * @memberof OtaStatus
     * @instance
     */
    OtaStatus.prototype.message = "";

    /**
     * OtaStatus writtenSize.
     * @member {number} writtenSize
     * @memberof OtaStatus
     * @instance
     */
    OtaStatus.prototype.writtenSize = 0;

    /**
     * OtaStatus expectedSeq.
     * @member {number} expectedSeq
     * @memberof OtaStatus
     * @instance
     */
    OtaStatus.prototype.expectedSeq = 0;

    /**
     * Creates a new OtaStatus instance using the specified properties.
     * @function create
     * @memberof OtaStatus
     * @static
     * @param {IOtaStatus=} [properties] Properties to set
     * @returns {OtaStatus} OtaStatus instance
     */
    OtaStatus.create = function create(properties) {
        return new OtaStatus(properties);
    };

    /**
     * Encodes the specified OtaStatus message. Does not implicitly {@link OtaStatus.verify|verify} messages.
     * @function encode
     * @memberof OtaStatus
     * @static
     * @param {IOtaStatus} message OtaStatus message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaStatus.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.state != null && Object.hasOwnProperty.call(message, "state"))
            writer.uint32(/* id 1, wireType 0 =*/8).int32(message.state);
        if (message.progressPercent != null && Object.hasOwnProperty.call(message, "progressPercent"))
            writer.uint32(/* id 2, wireType 0 =*/16).uint32(message.progressPercent);
        if (message.message != null && Object.hasOwnProperty.call(message, "message"))
            writer.uint32(/* id 3, wireType 2 =*/26).string(message.message);
        if (message.writtenSize != null && Object.hasOwnProperty.call(message, "writtenSize"))
            writer.uint32(/* id 4, wireType 0 =*/32).uint32(message.writtenSize);
        if (message.expectedSeq != null && Object.hasOwnProperty.call(message, "expectedSeq"))
            writer.uint32(/* id 5, wireType 0 =*/40).uint32(message.expectedSeq);
        return writer;
    };

    /**
     * Encodes the specified OtaStatus message, length delimited. Does not implicitly {@link OtaStatus.verify|verify} messages.
     * @function encodeDelimited
     * @memberof OtaStatus
     * @static
     * @param {IOtaStatus} message OtaStatus message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaStatus.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an OtaStatus message from the specified reader or buffer.
     * @function decode
     * @memberof OtaStatus
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {OtaStatus} OtaStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaStatus.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.OtaStatus();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.state = reader.int32();
                    break;
                }
            case 2: {
                    message.progressPercent = reader.uint32();
                    break;
                }
            case 3: {
                    message.message = reader.string();
                    break;
                }
            case 4: {
                    message.writtenSize = reader.uint32();
                    break;
                }
            case 5: {
                    message.expectedSeq = reader.uint32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an OtaStatus message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof OtaStatus
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {OtaStatus} OtaStatus
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaStatus.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an OtaStatus message.
     * @function verify
     * @memberof OtaStatus
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    OtaStatus.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.state != null && message.hasOwnProperty("state"))
            switch (message.state) {
            default:
                return "state: enum value expected";
            case 0:
            case 1:
            case 2:
            case 3:
            case 4:
                break;
            }
        if (message.progressPercent != null && message.hasOwnProperty("progressPercent"))
            if (!$util.isInteger(message.progressPercent))
                return "progressPercent: integer expected";
        if (message.message != null && message.hasOwnProperty("message"))
            if (!$util.isString(message.message))
                return "message: string expected";
        if (message.writtenSize != null && message.hasOwnProperty("writtenSize"))
            if (!$util.isInteger(message.writtenSize))
                return "writtenSize: integer expected";
        if (message.expectedSeq != null && message.hasOwnProperty("expectedSeq"))
            if (!$util.isInteger(message.expectedSeq))
                return "expectedSeq: integer expected";
        return null;
    };

    /**
     * Creates an OtaStatus message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof OtaStatus
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {OtaStatus} OtaStatus
     */
    OtaStatus.fromObject = function fromObject(object) {
        if (object instanceof $root.OtaStatus)
            return object;
        let message = new $root.OtaStatus();
        switch (object.state) {
        default:
            if (typeof object.state === "number") {
                message.state = object.state;
                break;
            }
            break;
        case "OTA_IDLE":
        case 0:
            message.state = 0;
            break;
        case "OTA_DOWNLOADING":
        case 1:
            message.state = 1;
            break;
        case "OTA_VERIFYING":
        case 2:
            message.state = 2;
            break;
        case "OTA_FINISHED":
        case 3:
            message.state = 3;
            break;
        case "OTA_ERROR":
        case 4:
            message.state = 4;
            break;
        }
        if (object.progressPercent != null)
            message.progressPercent = object.progressPercent >>> 0;
        if (object.message != null)
            message.message = String(object.message);
        if (object.writtenSize != null)
            message.writtenSize = object.writtenSize >>> 0;
        if (object.expectedSeq != null)
            message.expectedSeq = object.expectedSeq >>> 0;
        return message;
    };

    /**
     * Creates a plain object from an OtaStatus message. Also converts values to other types if specified.
     * @function toObject
     * @memberof OtaStatus
     * @static
     * @param {OtaStatus} message OtaStatus
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    OtaStatus.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.state = options.enums === String ? "OTA_IDLE" : 0;
            object.progressPercent = 0;
            object.message = "";
            object.writtenSize = 0;
            object.expectedSeq = 0;
        }
        if (message.state != null && message.hasOwnProperty("state"))
            object.state = options.enums === String ? $root.OtaState[message.state] === undefined ? message.state : $root.OtaState[message.state] : message.state;
        if (message.progressPercent != null && message.hasOwnProperty("progressPercent"))
            object.progressPercent = message.progressPercent;
        if (message.message != null && message.hasOwnProperty("message"))
            object.message = message.message;
        if (message.writtenSize != null && message.hasOwnProperty("writtenSize"))
            object.writtenSize = message.writtenSize;
        if (message.expectedSeq != null && message.hasOwnProperty("expectedSeq"))
            object.expectedSeq = message.expectedSeq;
        return object;
    };

    /**
     * Converts this OtaStatus to JSON.
     * @function toJSON
     * @memberof OtaStatus
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    OtaStatus.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for OtaStatus
     * @function getTypeUrl
     * @memberof OtaStatus
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    OtaStatus.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/OtaStatus";
    };

    return OtaStatus;
})();

export const OtaBegin = $root.OtaBegin = (() => {

    /**
     * Properties of an OtaBegin.
     * @exports IOtaBegin
     * @interface IOtaBegin
     * @property {number|null} [fileSize] OtaBegin fileSize
     */

    /**
     * Constructs a new OtaBegin.
     * @exports OtaBegin
     * @classdesc Represents an OtaBegin.
     * @implements IOtaBegin
     * @constructor
     * @param {IOtaBegin=} [properties] Properties to set
     */
    function OtaBegin(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * OtaBegin fileSize.
     * @member {number} fileSize
     * @memberof OtaBegin
     * @instance
     */
    OtaBegin.prototype.fileSize = 0;

    /**
     * Creates a new OtaBegin instance using the specified properties.
     * @function create
     * @memberof OtaBegin
     * @static
     * @param {IOtaBegin=} [properties] Properties to set
     * @returns {OtaBegin} OtaBegin instance
     */
    OtaBegin.create = function create(properties) {
        return new OtaBegin(properties);
    };

    /**
     * Encodes the specified OtaBegin message. Does not implicitly {@link OtaBegin.verify|verify} messages.
     * @function encode
     * @memberof OtaBegin
     * @static
     * @param {IOtaBegin} message OtaBegin message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaBegin.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.fileSize != null && Object.hasOwnProperty.call(message, "fileSize"))
            writer.uint32(/* id 1, wireType 0 =*/8).uint32(message.fileSize);
        return writer;
    };

    /**
     * Encodes the specified OtaBegin message, length delimited. Does not implicitly {@link OtaBegin.verify|verify} messages.
     * @function encodeDelimited
     * @memberof OtaBegin
     * @static
     * @param {IOtaBegin} message OtaBegin message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaBegin.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an OtaBegin message from the specified reader or buffer.
     * @function decode
     * @memberof OtaBegin
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {OtaBegin} OtaBegin
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaBegin.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.OtaBegin();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.fileSize = reader.uint32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an OtaBegin message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof OtaBegin
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {OtaBegin} OtaBegin
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaBegin.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an OtaBegin message.
     * @function verify
     * @memberof OtaBegin
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    OtaBegin.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.fileSize != null && message.hasOwnProperty("fileSize"))
            if (!$util.isInteger(message.fileSize))
                return "fileSize: integer expected";
        return null;
    };

    /**
     * Creates an OtaBegin message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof OtaBegin
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {OtaBegin} OtaBegin
     */
    OtaBegin.fromObject = function fromObject(object) {
        if (object instanceof $root.OtaBegin)
            return object;
        let message = new $root.OtaBegin();
        if (object.fileSize != null)
            message.fileSize = object.fileSize >>> 0;
        return message;
    };

    /**
     * Creates a plain object from an OtaBegin message. Also converts values to other types if specified.
     * @function toObject
     * @memberof OtaBegin
     * @static
     * @param {OtaBegin} message OtaBegin
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    OtaBegin.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults)
            object.fileSize = 0;
        if (message.fileSize != null && message.hasOwnProperty("fileSize"))
            object.fileSize = message.fileSize;
        return object;
    };

    /**
     * Converts this OtaBegin to JSON.
     * @function toJSON
     * @memberof OtaBegin
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    OtaBegin.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for OtaBegin
     * @function getTypeUrl
     * @memberof OtaBegin
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    OtaBegin.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/OtaBegin";
    };

    return OtaBegin;
})();

export const OtaChunk = $root.OtaChunk = (() => {

    /**
     * Properties of an OtaChunk.
     * @exports IOtaChunk
     * @interface IOtaChunk
     * @property {number|null} [seq] OtaChunk seq
     * @property {Uint8Array|null} [data] OtaChunk data
     */

    /**
     * Constructs a new OtaChunk.
     * @exports OtaChunk
     * @classdesc Represents an OtaChunk.
     * @implements IOtaChunk
     * @constructor
     * @param {IOtaChunk=} [properties] Properties to set
     */
    function OtaChunk(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * OtaChunk seq.
     * @member {number} seq
     * @memberof OtaChunk
     * @instance
     */
    OtaChunk.prototype.seq = 0;

    /**
     * OtaChunk data.
     * @member {Uint8Array} data
     * @memberof OtaChunk
     * @instance
     */
    OtaChunk.prototype.data = $util.newBuffer([]);

    /**
     * Creates a new OtaChunk instance using the specified properties.
     * @function create
     * @memberof OtaChunk
     * @static
     * @param {IOtaChunk=} [properties] Properties to set
     * @returns {OtaChunk} OtaChunk instance
     */
    OtaChunk.create = function create(properties) {
        return new OtaChunk(properties);
    };

    /**
     * Encodes the specified OtaChunk message. Does not implicitly {@link OtaChunk.verify|verify} messages.
     * @function encode
     * @memberof OtaChunk
     * @static
     * @param {IOtaChunk} message OtaChunk message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaChunk.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.seq != null && Object.hasOwnProperty.call(message, "seq"))
            writer.uint32(/* id 1, wireType 0 =*/8).uint32(message.seq);
        if (message.data != null && Object.hasOwnProperty.call(message, "data"))
            writer.uint32(/* id 2, wireType 2 =*/18).bytes(message.data);
        return writer;
    };

    /**
     * Encodes the specified OtaChunk message, length delimited. Does not implicitly {@link OtaChunk.verify|verify} messages.
     * @function encodeDelimited
     * @memberof OtaChunk
     * @static
     * @param {IOtaChunk} message OtaChunk message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaChunk.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an OtaChunk message from the specified reader or buffer.
     * @function decode
     * @memberof OtaChunk
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {OtaChunk} OtaChunk
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaChunk.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.OtaChunk();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.seq = reader.uint32();
                    break;
                }
            case 2: {
                    message.data = reader.bytes();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an OtaChunk message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof OtaChunk
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {OtaChunk} OtaChunk
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaChunk.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an OtaChunk message.
     * @function verify
     * @memberof OtaChunk
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    OtaChunk.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.seq != null && message.hasOwnProperty("seq"))
            if (!$util.isInteger(message.seq))
                return "seq: integer expected";
        if (message.data != null && message.hasOwnProperty("data"))
            if (!(message.data && typeof message.data.length === "number" || $util.isString(message.data)))
                return "data: buffer expected";
        return null;
    };

    /**
     * Creates an OtaChunk message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof OtaChunk
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {OtaChunk} OtaChunk
     */
    OtaChunk.fromObject = function fromObject(object) {
        if (object instanceof $root.OtaChunk)
            return object;
        let message = new $root.OtaChunk();
        if (object.seq != null)
            message.seq = object.seq >>> 0;
        if (object.data != null)
            if (typeof object.data === "string")
                $util.base64.decode(object.data, message.data = $util.newBuffer($util.base64.length(object.data)), 0);
            else if (object.data.length >= 0)
                message.data = object.data;
        return message;
    };

    /**
     * Creates a plain object from an OtaChunk message. Also converts values to other types if specified.
     * @function toObject
     * @memberof OtaChunk
     * @static
     * @param {OtaChunk} message OtaChunk
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    OtaChunk.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.seq = 0;
            if (options.bytes === String)
                object.data = "";
            else {
                object.data = [];
                if (options.bytes !== Array)
                    object.data = $util.newBuffer(object.data);
            }
        }
        if (message.seq != null && message.hasOwnProperty("seq"))
            object.seq = message.seq;
        if (message.data != null && message.hasOwnProperty("data"))
            object.data = options.bytes === String ? $util.base64.encode(message.data, 0, message.data.length) : options.bytes === Array ? Array.prototype.slice.call(message.data) : message.data;
        return object;
    };

    /**
     * Converts this OtaChunk to JSON.
     * @function toJSON
     * @memberof OtaChunk
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    OtaChunk.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for OtaChunk
     * @function getTypeUrl
     * @memberof OtaChunk
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    OtaChunk.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/OtaChunk";
    };

    return OtaChunk;
})();

export const OtaEnd = $root.OtaEnd = (() => {

    /**
     * Properties of an OtaEnd.
     * @exports IOtaEnd
     * @interface IOtaEnd
     * @property {string|null} [sha256] OtaEnd sha256
     */

    /**
     * Constructs a new OtaEnd.
     * @exports OtaEnd
     * @classdesc Represents an OtaEnd.
     * @implements IOtaEnd
     * @constructor
     * @param {IOtaEnd=} [properties] Properties to set
     */
    function OtaEnd(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * OtaEnd sha256.
     * @member {string} sha256
     * @memberof OtaEnd
     * @instance
     */
    OtaEnd.prototype.sha256 = "";

    /**
     * Creates a new OtaEnd instance using the specified properties.
     * @function create
     * @memberof OtaEnd
     * @static
     * @param {IOtaEnd=} [properties] Properties to set
     * @returns {OtaEnd} OtaEnd instance
     */
    OtaEnd.create = function create(properties) {
        return new OtaEnd(properties);
    };

    /**
     * Encodes the specified OtaEnd message. Does not implicitly {@link OtaEnd.verify|verify} messages.
     * @function encode
     * @memberof OtaEnd
     * @static
     * @param {IOtaEnd} message OtaEnd message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaEnd.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.sha256 != null && Object.hasOwnProperty.call(message, "sha256"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.sha256);
        return writer;
    };

    /**
     * Encodes the specified OtaEnd message, length delimited. Does not implicitly {@link OtaEnd.verify|verify} messages.
     * @function encodeDelimited
     * @memberof OtaEnd
     * @static
     * @param {IOtaEnd} message OtaEnd message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaEnd.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an OtaEnd message from the specified reader or buffer.
     * @function decode
     * @memberof OtaEnd
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {OtaEnd} OtaEnd
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaEnd.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.OtaEnd();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.sha256 = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an OtaEnd message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof OtaEnd
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {OtaEnd} OtaEnd
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaEnd.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an OtaEnd message.
     * @function verify
     * @memberof OtaEnd
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    OtaEnd.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.sha256 != null && message.hasOwnProperty("sha256"))
            if (!$util.isString(message.sha256))
                return "sha256: string expected";
        return null;
    };

    /**
     * Creates an OtaEnd message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof OtaEnd
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {OtaEnd} OtaEnd
     */
    OtaEnd.fromObject = function fromObject(object) {
        if (object instanceof $root.OtaEnd)
            return object;
        let message = new $root.OtaEnd();
        if (object.sha256 != null)
            message.sha256 = String(object.sha256);
        return message;
    };

    /**
     * Creates a plain object from an OtaEnd message. Also converts values to other types if specified.
     * @function toObject
     * @memberof OtaEnd
     * @static
     * @param {OtaEnd} message OtaEnd
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    OtaEnd.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults)
            object.sha256 = "";
        if (message.sha256 != null && message.hasOwnProperty("sha256"))
            object.sha256 = message.sha256;
        return object;
    };

    /**
     * Converts this OtaEnd to JSON.
     * @function toJSON
     * @memberof OtaEnd
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    OtaEnd.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for OtaEnd
     * @function getTypeUrl
     * @memberof OtaEnd
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    OtaEnd.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/OtaEnd";
    };

    return OtaEnd;
})();

export const OtaCommand = $root.OtaCommand = (() => {

    /**
     * Properties of an OtaCommand.
     * @exports IOtaCommand
     * @interface IOtaCommand
     * @property {IOtaBegin|null} [begin] OtaCommand begin
     * @property {IOtaChunk|null} [chunk] OtaCommand chunk
     * @property {IOtaEnd|null} [end] OtaCommand end
     * @property {boolean|null} [abort] OtaCommand abort
     */

    /**
     * Constructs a new OtaCommand.
     * @exports OtaCommand
     * @classdesc Represents an OtaCommand.
     * @implements IOtaCommand
     * @constructor
     * @param {IOtaCommand=} [properties] Properties to set
     */
    function OtaCommand(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * OtaCommand begin.
     * @member {IOtaBegin|null|undefined} begin
     * @memberof OtaCommand
     * @instance
     */
    OtaCommand.prototype.begin = null;

    /**
     * OtaCommand chunk.
     * @member {IOtaChunk|null|undefined} chunk
     * @memberof OtaCommand
     * @instance
     */
    OtaCommand.prototype.chunk = null;

    /**
     * OtaCommand end.
     * @member {IOtaEnd|null|undefined} end
     * @memberof OtaCommand
     * @instance
     */
    OtaCommand.prototype.end = null;

    /**
     * OtaCommand abort.
     * @member {boolean|null|undefined} abort
     * @memberof OtaCommand
     * @instance
     */
    OtaCommand.prototype.abort = null;

    // OneOf field names bound to virtual getters and setters
    let $oneOfFields;

    /**
     * OtaCommand type.
     * @member {"begin"|"chunk"|"end"|"abort"|undefined} type
     * @memberof OtaCommand
     * @instance
     */
    Object.defineProperty(OtaCommand.prototype, "type", {
        get: $util.oneOfGetter($oneOfFields = ["begin", "chunk", "end", "abort"]),
        set: $util.oneOfSetter($oneOfFields)
    });

    /**
     * Creates a new OtaCommand instance using the specified properties.
     * @function create
     * @memberof OtaCommand
     * @static
     * @param {IOtaCommand=} [properties] Properties to set
     * @returns {OtaCommand} OtaCommand instance
     */
    OtaCommand.create = function create(properties) {
        return new OtaCommand(properties);
    };

    /**
     * Encodes the specified OtaCommand message. Does not implicitly {@link OtaCommand.verify|verify} messages.
     * @function encode
     * @memberof OtaCommand
     * @static
     * @param {IOtaCommand} message OtaCommand message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaCommand.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.begin != null && Object.hasOwnProperty.call(message, "begin"))
            $root.OtaBegin.encode(message.begin, writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
        if (message.chunk != null && Object.hasOwnProperty.call(message, "chunk"))
            $root.OtaChunk.encode(message.chunk, writer.uint32(/* id 2, wireType 2 =*/18).fork()).ldelim();
        if (message.end != null && Object.hasOwnProperty.call(message, "end"))
            $root.OtaEnd.encode(message.end, writer.uint32(/* id 3, wireType 2 =*/26).fork()).ldelim();
        if (message.abort != null && Object.hasOwnProperty.call(message, "abort"))
            writer.uint32(/* id 4, wireType 0 =*/32).bool(message.abort);
        return writer;
    };

    /**
     * Encodes the specified OtaCommand message, length delimited. Does not implicitly {@link OtaCommand.verify|verify} messages.
     * @function encodeDelimited
     * @memberof OtaCommand
     * @static
     * @param {IOtaCommand} message OtaCommand message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    OtaCommand.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an OtaCommand message from the specified reader or buffer.
     * @function decode
     * @memberof OtaCommand
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {OtaCommand} OtaCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaCommand.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.OtaCommand();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.begin = $root.OtaBegin.decode(reader, reader.uint32());
                    break;
                }
            case 2: {
                    message.chunk = $root.OtaChunk.decode(reader, reader.uint32());
                    break;
                }
            case 3: {
                    message.end = $root.OtaEnd.decode(reader, reader.uint32());
                    break;
                }
            case 4: {
                    message.abort = reader.bool();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an OtaCommand message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof OtaCommand
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {OtaCommand} OtaCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    OtaCommand.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an OtaCommand message.
     * @function verify
     * @memberof OtaCommand
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    OtaCommand.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        let properties = {};
        if (message.begin != null && message.hasOwnProperty("begin")) {
            properties.type = 1;
            {
                let error = $root.OtaBegin.verify(message.begin);
                if (error)
                    return "begin." + error;
            }
        }
        if (message.chunk != null && message.hasOwnProperty("chunk")) {
            if (properties.type === 1)
                return "type: multiple values";
            properties.type = 1;
            {
                let error = $root.OtaChunk.verify(message.chunk);
                if (error)
                    return "chunk." + error;
            }
        }
        if (message.end != null && message.hasOwnProperty("end")) {
            if (properties.type === 1)
                return "type: multiple values";
            properties.type = 1;
            {
                let error = $root.OtaEnd.verify(message.end);
                if (error)
                    return "end." + error;
            }
        }
        if (message.abort != null && message.hasOwnProperty("abort")) {
            if (properties.type === 1)
                return "type: multiple values";
            properties.type = 1;
            if (typeof message.abort !== "boolean")
                return "abort: boolean expected";
        }
        return null;
    };

    /**
     * Creates an OtaCommand message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof OtaCommand
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {OtaCommand} OtaCommand
     */
    OtaCommand.fromObject = function fromObject(object) {
        if (object instanceof $root.OtaCommand)
            return object;
        let message = new $root.OtaCommand();
        if (object.begin != null) {
            if (typeof object.begin !== "object")
                throw TypeError(".OtaCommand.begin: object expected");
            message.begin = $root.OtaBegin.fromObject(object.begin);
        }
        if (object.chunk != null) {
            if (typeof object.chunk !== "object")
                throw TypeError(".OtaCommand.chunk: object expected");
            message.chunk = $root.OtaChunk.fromObject(object.chunk);
        }
        if (object.end != null) {
            if (typeof object.end !== "object")
                throw TypeError(".OtaCommand.end: object expected");
            message.end = $root.OtaEnd.fromObject(object.end);
        }
        if (object.abort != null)
            message.abort = Boolean(object.abort);
        return message;
    };

    /**
     * Creates a plain object from an OtaCommand message. Also converts values to other types if specified.
     * @function toObject
     * @memberof OtaCommand
     * @static
     * @param {OtaCommand} message OtaCommand
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    OtaCommand.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (message.begin != null && message.hasOwnProperty("begin")) {
            object.begin = $root.OtaBegin.toObject(message.begin, options);
            if (options.oneofs)
                object.type = "begin";
        }
        if (message.chunk != null && message.hasOwnProperty("chunk")) {
            object.chunk = $root.OtaChunk.toObject(message.chunk, options);
            if (options.oneofs)
                object.type = "chunk";
        }
        if (message.end != null && message.hasOwnProperty("end")) {
            object.end = $root.OtaEnd.toObject(message.end, options);
            if (options.oneofs)
                object.type = "end";
        }
        if (message.abort != null && message.hasOwnProperty("abort")) {
            object.abort = message.abort;
            if (options.oneofs)
                object.type = "abort";
        }
        return object;
    };

    /**
     * Converts this OtaCommand to JSON.
     * @function toJSON
     * @memberof OtaCommand
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    OtaCommand.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for OtaCommand
     * @function getTypeUrl
     * @memberof OtaCommand
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    OtaCommand.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/OtaCommand";
    };

    return OtaCommand;
})();

export const UiCommand = $root.UiCommand = (() => {

    /**
     * Properties of an UiCommand.
     * @exports IUiCommand
     * @interface IUiCommand
     * @property {string|null} [name] UiCommand name
     * @property {string|null} [json] UiCommand json
     * @property {number|null} [requestId] UiCommand requestId
     */

    /**
     * Constructs a new UiCommand.
     * @exports UiCommand
     * @classdesc Represents an UiCommand.
     * @implements IUiCommand
     * @constructor
     * @param {IUiCommand=} [properties] Properties to set
     */
    function UiCommand(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * UiCommand name.
     * @member {string} name
     * @memberof UiCommand
     * @instance
     */
    UiCommand.prototype.name = "";

    /**
     * UiCommand json.
     * @member {string} json
     * @memberof UiCommand
     * @instance
     */
    UiCommand.prototype.json = "";

    /**
     * UiCommand requestId.
     * @member {number} requestId
     * @memberof UiCommand
     * @instance
     */
    UiCommand.prototype.requestId = 0;

    /**
     * Creates a new UiCommand instance using the specified properties.
     * @function create
     * @memberof UiCommand
     * @static
     * @param {IUiCommand=} [properties] Properties to set
     * @returns {UiCommand} UiCommand instance
     */
    UiCommand.create = function create(properties) {
        return new UiCommand(properties);
    };

    /**
     * Encodes the specified UiCommand message. Does not implicitly {@link UiCommand.verify|verify} messages.
     * @function encode
     * @memberof UiCommand
     * @static
     * @param {IUiCommand} message UiCommand message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    UiCommand.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.name != null && Object.hasOwnProperty.call(message, "name"))
            writer.uint32(/* id 1, wireType 2 =*/10).string(message.name);
        if (message.json != null && Object.hasOwnProperty.call(message, "json"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.json);
        if (message.requestId != null && Object.hasOwnProperty.call(message, "requestId"))
            writer.uint32(/* id 3, wireType 0 =*/24).uint32(message.requestId);
        return writer;
    };

    /**
     * Encodes the specified UiCommand message, length delimited. Does not implicitly {@link UiCommand.verify|verify} messages.
     * @function encodeDelimited
     * @memberof UiCommand
     * @static
     * @param {IUiCommand} message UiCommand message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    UiCommand.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an UiCommand message from the specified reader or buffer.
     * @function decode
     * @memberof UiCommand
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {UiCommand} UiCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    UiCommand.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.UiCommand();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.name = reader.string();
                    break;
                }
            case 2: {
                    message.json = reader.string();
                    break;
                }
            case 3: {
                    message.requestId = reader.uint32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an UiCommand message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof UiCommand
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {UiCommand} UiCommand
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    UiCommand.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an UiCommand message.
     * @function verify
     * @memberof UiCommand
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    UiCommand.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.name != null && message.hasOwnProperty("name"))
            if (!$util.isString(message.name))
                return "name: string expected";
        if (message.json != null && message.hasOwnProperty("json"))
            if (!$util.isString(message.json))
                return "json: string expected";
        if (message.requestId != null && message.hasOwnProperty("requestId"))
            if (!$util.isInteger(message.requestId))
                return "requestId: integer expected";
        return null;
    };

    /**
     * Creates an UiCommand message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof UiCommand
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {UiCommand} UiCommand
     */
    UiCommand.fromObject = function fromObject(object) {
        if (object instanceof $root.UiCommand)
            return object;
        let message = new $root.UiCommand();
        if (object.name != null)
            message.name = String(object.name);
        if (object.json != null)
            message.json = String(object.json);
        if (object.requestId != null)
            message.requestId = object.requestId >>> 0;
        return message;
    };

    /**
     * Creates a plain object from an UiCommand message. Also converts values to other types if specified.
     * @function toObject
     * @memberof UiCommand
     * @static
     * @param {UiCommand} message UiCommand
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    UiCommand.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.name = "";
            object.json = "";
            object.requestId = 0;
        }
        if (message.name != null && message.hasOwnProperty("name"))
            object.name = message.name;
        if (message.json != null && message.hasOwnProperty("json"))
            object.json = message.json;
        if (message.requestId != null && message.hasOwnProperty("requestId"))
            object.requestId = message.requestId;
        return object;
    };

    /**
     * Converts this UiCommand to JSON.
     * @function toJSON
     * @memberof UiCommand
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    UiCommand.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for UiCommand
     * @function getTypeUrl
     * @memberof UiCommand
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    UiCommand.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/UiCommand";
    };

    return UiCommand;
})();

export const UiCommandResult = $root.UiCommandResult = (() => {

    /**
     * Properties of an UiCommandResult.
     * @exports IUiCommandResult
     * @interface IUiCommandResult
     * @property {number|null} [requestId] UiCommandResult requestId
     * @property {string|null} [name] UiCommandResult name
     * @property {boolean|null} [ok] UiCommandResult ok
     * @property {string|null} [code] UiCommandResult code
     * @property {string|null} [message] UiCommandResult message
     * @property {string|null} [json] UiCommandResult json
     */

    /**
     * Constructs a new UiCommandResult.
     * @exports UiCommandResult
     * @classdesc Represents an UiCommandResult.
     * @implements IUiCommandResult
     * @constructor
     * @param {IUiCommandResult=} [properties] Properties to set
     */
    function UiCommandResult(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * UiCommandResult requestId.
     * @member {number} requestId
     * @memberof UiCommandResult
     * @instance
     */
    UiCommandResult.prototype.requestId = 0;

    /**
     * UiCommandResult name.
     * @member {string} name
     * @memberof UiCommandResult
     * @instance
     */
    UiCommandResult.prototype.name = "";

    /**
     * UiCommandResult ok.
     * @member {boolean} ok
     * @memberof UiCommandResult
     * @instance
     */
    UiCommandResult.prototype.ok = false;

    /**
     * UiCommandResult code.
     * @member {string} code
     * @memberof UiCommandResult
     * @instance
     */
    UiCommandResult.prototype.code = "";

    /**
     * UiCommandResult message.
     * @member {string} message
     * @memberof UiCommandResult
     * @instance
     */
    UiCommandResult.prototype.message = "";

    /**
     * UiCommandResult json.
     * @member {string} json
     * @memberof UiCommandResult
     * @instance
     */
    UiCommandResult.prototype.json = "";

    /**
     * Creates a new UiCommandResult instance using the specified properties.
     * @function create
     * @memberof UiCommandResult
     * @static
     * @param {IUiCommandResult=} [properties] Properties to set
     * @returns {UiCommandResult} UiCommandResult instance
     */
    UiCommandResult.create = function create(properties) {
        return new UiCommandResult(properties);
    };

    /**
     * Encodes the specified UiCommandResult message. Does not implicitly {@link UiCommandResult.verify|verify} messages.
     * @function encode
     * @memberof UiCommandResult
     * @static
     * @param {IUiCommandResult} message UiCommandResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    UiCommandResult.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.requestId != null && Object.hasOwnProperty.call(message, "requestId"))
            writer.uint32(/* id 1, wireType 0 =*/8).uint32(message.requestId);
        if (message.name != null && Object.hasOwnProperty.call(message, "name"))
            writer.uint32(/* id 2, wireType 2 =*/18).string(message.name);
        if (message.ok != null && Object.hasOwnProperty.call(message, "ok"))
            writer.uint32(/* id 3, wireType 0 =*/24).bool(message.ok);
        if (message.code != null && Object.hasOwnProperty.call(message, "code"))
            writer.uint32(/* id 4, wireType 2 =*/34).string(message.code);
        if (message.message != null && Object.hasOwnProperty.call(message, "message"))
            writer.uint32(/* id 5, wireType 2 =*/42).string(message.message);
        if (message.json != null && Object.hasOwnProperty.call(message, "json"))
            writer.uint32(/* id 6, wireType 2 =*/50).string(message.json);
        return writer;
    };

    /**
     * Encodes the specified UiCommandResult message, length delimited. Does not implicitly {@link UiCommandResult.verify|verify} messages.
     * @function encodeDelimited
     * @memberof UiCommandResult
     * @static
     * @param {IUiCommandResult} message UiCommandResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    UiCommandResult.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an UiCommandResult message from the specified reader or buffer.
     * @function decode
     * @memberof UiCommandResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {UiCommandResult} UiCommandResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    UiCommandResult.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.UiCommandResult();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.requestId = reader.uint32();
                    break;
                }
            case 2: {
                    message.name = reader.string();
                    break;
                }
            case 3: {
                    message.ok = reader.bool();
                    break;
                }
            case 4: {
                    message.code = reader.string();
                    break;
                }
            case 5: {
                    message.message = reader.string();
                    break;
                }
            case 6: {
                    message.json = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an UiCommandResult message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof UiCommandResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {UiCommandResult} UiCommandResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    UiCommandResult.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an UiCommandResult message.
     * @function verify
     * @memberof UiCommandResult
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    UiCommandResult.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.requestId != null && message.hasOwnProperty("requestId"))
            if (!$util.isInteger(message.requestId))
                return "requestId: integer expected";
        if (message.name != null && message.hasOwnProperty("name"))
            if (!$util.isString(message.name))
                return "name: string expected";
        if (message.ok != null && message.hasOwnProperty("ok"))
            if (typeof message.ok !== "boolean")
                return "ok: boolean expected";
        if (message.code != null && message.hasOwnProperty("code"))
            if (!$util.isString(message.code))
                return "code: string expected";
        if (message.message != null && message.hasOwnProperty("message"))
            if (!$util.isString(message.message))
                return "message: string expected";
        if (message.json != null && message.hasOwnProperty("json"))
            if (!$util.isString(message.json))
                return "json: string expected";
        return null;
    };

    /**
     * Creates an UiCommandResult message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof UiCommandResult
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {UiCommandResult} UiCommandResult
     */
    UiCommandResult.fromObject = function fromObject(object) {
        if (object instanceof $root.UiCommandResult)
            return object;
        let message = new $root.UiCommandResult();
        if (object.requestId != null)
            message.requestId = object.requestId >>> 0;
        if (object.name != null)
            message.name = String(object.name);
        if (object.ok != null)
            message.ok = Boolean(object.ok);
        if (object.code != null)
            message.code = String(object.code);
        if (object.message != null)
            message.message = String(object.message);
        if (object.json != null)
            message.json = String(object.json);
        return message;
    };

    /**
     * Creates a plain object from an UiCommandResult message. Also converts values to other types if specified.
     * @function toObject
     * @memberof UiCommandResult
     * @static
     * @param {UiCommandResult} message UiCommandResult
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    UiCommandResult.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.requestId = 0;
            object.name = "";
            object.ok = false;
            object.code = "";
            object.message = "";
            object.json = "";
        }
        if (message.requestId != null && message.hasOwnProperty("requestId"))
            object.requestId = message.requestId;
        if (message.name != null && message.hasOwnProperty("name"))
            object.name = message.name;
        if (message.ok != null && message.hasOwnProperty("ok"))
            object.ok = message.ok;
        if (message.code != null && message.hasOwnProperty("code"))
            object.code = message.code;
        if (message.message != null && message.hasOwnProperty("message"))
            object.message = message.message;
        if (message.json != null && message.hasOwnProperty("json"))
            object.json = message.json;
        return object;
    };

    /**
     * Converts this UiCommandResult to JSON.
     * @function toJSON
     * @memberof UiCommandResult
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    UiCommandResult.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for UiCommandResult
     * @function getTypeUrl
     * @memberof UiCommandResult
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    UiCommandResult.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/UiCommandResult";
    };

    return UiCommandResult;
})();

export const AnalogDiagnosticResult = $root.AnalogDiagnosticResult = (() => {

    /**
     * Properties of an AnalogDiagnosticResult.
     * @exports IAnalogDiagnosticResult
     * @interface IAnalogDiagnosticResult
     * @property {boolean|null} [valid] AnalogDiagnosticResult valid
     * @property {boolean|null} [running] AnalogDiagnosticResult running
     * @property {number|null} [durationMs] AnalogDiagnosticResult durationMs
     * @property {number|Long|null} [elapsedUs] AnalogDiagnosticResult elapsedUs
     * @property {number|null} [seqDelta] AnalogDiagnosticResult seqDelta
     * @property {number|null} [missDelta] AnalogDiagnosticResult missDelta
     * @property {number|null} [overflowDelta] AnalogDiagnosticResult overflowDelta
     * @property {number|null} [seq] AnalogDiagnosticResult seq
     * @property {number|null} [ageUs] AnalogDiagnosticResult ageUs
     * @property {number|null} [rateTps] AnalogDiagnosticResult rateTps
     * @property {number|null} [rawAn3] AnalogDiagnosticResult rawAn3
     * @property {number|null} [rawAn5] AnalogDiagnosticResult rawAn5
     * @property {number|null} [rawAn6] AnalogDiagnosticResult rawAn6
     * @property {number|null} [calAn3] AnalogDiagnosticResult calAn3
     * @property {number|null} [calAn5] AnalogDiagnosticResult calAn5
     * @property {number|null} [calAn6] AnalogDiagnosticResult calAn6
     * @property {number|null} [latencyAvgUs] AnalogDiagnosticResult latencyAvgUs
     * @property {number|null} [latencyP95Us] AnalogDiagnosticResult latencyP95Us
     * @property {number|null} [faultCode] AnalogDiagnosticResult faultCode
     * @property {number|null} [timingSamples] AnalogDiagnosticResult timingSamples
     * @property {number|null} [playbackAvgUs] AnalogDiagnosticResult playbackAvgUs
     * @property {number|null} [loopUs] AnalogDiagnosticResult loopUs
     * @property {number|null} [overruns] AnalogDiagnosticResult overruns
     * @property {number|null} [timingFaults] AnalogDiagnosticResult timingFaults
     * @property {string|null} [message] AnalogDiagnosticResult message
     */

    /**
     * Constructs a new AnalogDiagnosticResult.
     * @exports AnalogDiagnosticResult
     * @classdesc Represents an AnalogDiagnosticResult.
     * @implements IAnalogDiagnosticResult
     * @constructor
     * @param {IAnalogDiagnosticResult=} [properties] Properties to set
     */
    function AnalogDiagnosticResult(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AnalogDiagnosticResult valid.
     * @member {boolean} valid
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.valid = false;

    /**
     * AnalogDiagnosticResult running.
     * @member {boolean} running
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.running = false;

    /**
     * AnalogDiagnosticResult durationMs.
     * @member {number} durationMs
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.durationMs = 0;

    /**
     * AnalogDiagnosticResult elapsedUs.
     * @member {number|Long} elapsedUs
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.elapsedUs = $util.Long ? $util.Long.fromBits(0,0,true) : 0;

    /**
     * AnalogDiagnosticResult seqDelta.
     * @member {number} seqDelta
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.seqDelta = 0;

    /**
     * AnalogDiagnosticResult missDelta.
     * @member {number} missDelta
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.missDelta = 0;

    /**
     * AnalogDiagnosticResult overflowDelta.
     * @member {number} overflowDelta
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.overflowDelta = 0;

    /**
     * AnalogDiagnosticResult seq.
     * @member {number} seq
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.seq = 0;

    /**
     * AnalogDiagnosticResult ageUs.
     * @member {number} ageUs
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.ageUs = 0;

    /**
     * AnalogDiagnosticResult rateTps.
     * @member {number} rateTps
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.rateTps = 0;

    /**
     * AnalogDiagnosticResult rawAn3.
     * @member {number} rawAn3
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.rawAn3 = 0;

    /**
     * AnalogDiagnosticResult rawAn5.
     * @member {number} rawAn5
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.rawAn5 = 0;

    /**
     * AnalogDiagnosticResult rawAn6.
     * @member {number} rawAn6
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.rawAn6 = 0;

    /**
     * AnalogDiagnosticResult calAn3.
     * @member {number} calAn3
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.calAn3 = 0;

    /**
     * AnalogDiagnosticResult calAn5.
     * @member {number} calAn5
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.calAn5 = 0;

    /**
     * AnalogDiagnosticResult calAn6.
     * @member {number} calAn6
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.calAn6 = 0;

    /**
     * AnalogDiagnosticResult latencyAvgUs.
     * @member {number} latencyAvgUs
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.latencyAvgUs = 0;

    /**
     * AnalogDiagnosticResult latencyP95Us.
     * @member {number} latencyP95Us
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.latencyP95Us = 0;

    /**
     * AnalogDiagnosticResult faultCode.
     * @member {number} faultCode
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.faultCode = 0;

    /**
     * AnalogDiagnosticResult timingSamples.
     * @member {number} timingSamples
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.timingSamples = 0;

    /**
     * AnalogDiagnosticResult playbackAvgUs.
     * @member {number} playbackAvgUs
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.playbackAvgUs = 0;

    /**
     * AnalogDiagnosticResult loopUs.
     * @member {number} loopUs
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.loopUs = 0;

    /**
     * AnalogDiagnosticResult overruns.
     * @member {number} overruns
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.overruns = 0;

    /**
     * AnalogDiagnosticResult timingFaults.
     * @member {number} timingFaults
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.timingFaults = 0;

    /**
     * AnalogDiagnosticResult message.
     * @member {string} message
     * @memberof AnalogDiagnosticResult
     * @instance
     */
    AnalogDiagnosticResult.prototype.message = "";

    /**
     * Creates a new AnalogDiagnosticResult instance using the specified properties.
     * @function create
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {IAnalogDiagnosticResult=} [properties] Properties to set
     * @returns {AnalogDiagnosticResult} AnalogDiagnosticResult instance
     */
    AnalogDiagnosticResult.create = function create(properties) {
        return new AnalogDiagnosticResult(properties);
    };

    /**
     * Encodes the specified AnalogDiagnosticResult message. Does not implicitly {@link AnalogDiagnosticResult.verify|verify} messages.
     * @function encode
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {IAnalogDiagnosticResult} message AnalogDiagnosticResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogDiagnosticResult.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.valid != null && Object.hasOwnProperty.call(message, "valid"))
            writer.uint32(/* id 1, wireType 0 =*/8).bool(message.valid);
        if (message.running != null && Object.hasOwnProperty.call(message, "running"))
            writer.uint32(/* id 2, wireType 0 =*/16).bool(message.running);
        if (message.durationMs != null && Object.hasOwnProperty.call(message, "durationMs"))
            writer.uint32(/* id 3, wireType 0 =*/24).uint32(message.durationMs);
        if (message.elapsedUs != null && Object.hasOwnProperty.call(message, "elapsedUs"))
            writer.uint32(/* id 4, wireType 0 =*/32).uint64(message.elapsedUs);
        if (message.seqDelta != null && Object.hasOwnProperty.call(message, "seqDelta"))
            writer.uint32(/* id 5, wireType 0 =*/40).uint32(message.seqDelta);
        if (message.missDelta != null && Object.hasOwnProperty.call(message, "missDelta"))
            writer.uint32(/* id 6, wireType 0 =*/48).uint32(message.missDelta);
        if (message.overflowDelta != null && Object.hasOwnProperty.call(message, "overflowDelta"))
            writer.uint32(/* id 7, wireType 0 =*/56).uint32(message.overflowDelta);
        if (message.seq != null && Object.hasOwnProperty.call(message, "seq"))
            writer.uint32(/* id 8, wireType 0 =*/64).uint32(message.seq);
        if (message.ageUs != null && Object.hasOwnProperty.call(message, "ageUs"))
            writer.uint32(/* id 9, wireType 0 =*/72).uint32(message.ageUs);
        if (message.rateTps != null && Object.hasOwnProperty.call(message, "rateTps"))
            writer.uint32(/* id 10, wireType 0 =*/80).uint32(message.rateTps);
        if (message.rawAn3 != null && Object.hasOwnProperty.call(message, "rawAn3"))
            writer.uint32(/* id 11, wireType 0 =*/88).uint32(message.rawAn3);
        if (message.rawAn5 != null && Object.hasOwnProperty.call(message, "rawAn5"))
            writer.uint32(/* id 12, wireType 0 =*/96).uint32(message.rawAn5);
        if (message.rawAn6 != null && Object.hasOwnProperty.call(message, "rawAn6"))
            writer.uint32(/* id 13, wireType 0 =*/104).uint32(message.rawAn6);
        if (message.calAn3 != null && Object.hasOwnProperty.call(message, "calAn3"))
            writer.uint32(/* id 14, wireType 5 =*/117).float(message.calAn3);
        if (message.calAn5 != null && Object.hasOwnProperty.call(message, "calAn5"))
            writer.uint32(/* id 15, wireType 5 =*/125).float(message.calAn5);
        if (message.calAn6 != null && Object.hasOwnProperty.call(message, "calAn6"))
            writer.uint32(/* id 16, wireType 5 =*/133).float(message.calAn6);
        if (message.latencyAvgUs != null && Object.hasOwnProperty.call(message, "latencyAvgUs"))
            writer.uint32(/* id 17, wireType 0 =*/136).uint32(message.latencyAvgUs);
        if (message.latencyP95Us != null && Object.hasOwnProperty.call(message, "latencyP95Us"))
            writer.uint32(/* id 18, wireType 0 =*/144).uint32(message.latencyP95Us);
        if (message.faultCode != null && Object.hasOwnProperty.call(message, "faultCode"))
            writer.uint32(/* id 19, wireType 0 =*/152).uint32(message.faultCode);
        if (message.timingSamples != null && Object.hasOwnProperty.call(message, "timingSamples"))
            writer.uint32(/* id 20, wireType 0 =*/160).uint32(message.timingSamples);
        if (message.playbackAvgUs != null && Object.hasOwnProperty.call(message, "playbackAvgUs"))
            writer.uint32(/* id 21, wireType 5 =*/173).float(message.playbackAvgUs);
        if (message.loopUs != null && Object.hasOwnProperty.call(message, "loopUs"))
            writer.uint32(/* id 22, wireType 5 =*/181).float(message.loopUs);
        if (message.overruns != null && Object.hasOwnProperty.call(message, "overruns"))
            writer.uint32(/* id 23, wireType 0 =*/184).uint32(message.overruns);
        if (message.timingFaults != null && Object.hasOwnProperty.call(message, "timingFaults"))
            writer.uint32(/* id 24, wireType 0 =*/192).uint32(message.timingFaults);
        if (message.message != null && Object.hasOwnProperty.call(message, "message"))
            writer.uint32(/* id 25, wireType 2 =*/202).string(message.message);
        return writer;
    };

    /**
     * Encodes the specified AnalogDiagnosticResult message, length delimited. Does not implicitly {@link AnalogDiagnosticResult.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {IAnalogDiagnosticResult} message AnalogDiagnosticResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogDiagnosticResult.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AnalogDiagnosticResult message from the specified reader or buffer.
     * @function decode
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AnalogDiagnosticResult} AnalogDiagnosticResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogDiagnosticResult.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AnalogDiagnosticResult();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.valid = reader.bool();
                    break;
                }
            case 2: {
                    message.running = reader.bool();
                    break;
                }
            case 3: {
                    message.durationMs = reader.uint32();
                    break;
                }
            case 4: {
                    message.elapsedUs = reader.uint64();
                    break;
                }
            case 5: {
                    message.seqDelta = reader.uint32();
                    break;
                }
            case 6: {
                    message.missDelta = reader.uint32();
                    break;
                }
            case 7: {
                    message.overflowDelta = reader.uint32();
                    break;
                }
            case 8: {
                    message.seq = reader.uint32();
                    break;
                }
            case 9: {
                    message.ageUs = reader.uint32();
                    break;
                }
            case 10: {
                    message.rateTps = reader.uint32();
                    break;
                }
            case 11: {
                    message.rawAn3 = reader.uint32();
                    break;
                }
            case 12: {
                    message.rawAn5 = reader.uint32();
                    break;
                }
            case 13: {
                    message.rawAn6 = reader.uint32();
                    break;
                }
            case 14: {
                    message.calAn3 = reader.float();
                    break;
                }
            case 15: {
                    message.calAn5 = reader.float();
                    break;
                }
            case 16: {
                    message.calAn6 = reader.float();
                    break;
                }
            case 17: {
                    message.latencyAvgUs = reader.uint32();
                    break;
                }
            case 18: {
                    message.latencyP95Us = reader.uint32();
                    break;
                }
            case 19: {
                    message.faultCode = reader.uint32();
                    break;
                }
            case 20: {
                    message.timingSamples = reader.uint32();
                    break;
                }
            case 21: {
                    message.playbackAvgUs = reader.float();
                    break;
                }
            case 22: {
                    message.loopUs = reader.float();
                    break;
                }
            case 23: {
                    message.overruns = reader.uint32();
                    break;
                }
            case 24: {
                    message.timingFaults = reader.uint32();
                    break;
                }
            case 25: {
                    message.message = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AnalogDiagnosticResult message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AnalogDiagnosticResult} AnalogDiagnosticResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogDiagnosticResult.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AnalogDiagnosticResult message.
     * @function verify
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AnalogDiagnosticResult.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.valid != null && message.hasOwnProperty("valid"))
            if (typeof message.valid !== "boolean")
                return "valid: boolean expected";
        if (message.running != null && message.hasOwnProperty("running"))
            if (typeof message.running !== "boolean")
                return "running: boolean expected";
        if (message.durationMs != null && message.hasOwnProperty("durationMs"))
            if (!$util.isInteger(message.durationMs))
                return "durationMs: integer expected";
        if (message.elapsedUs != null && message.hasOwnProperty("elapsedUs"))
            if (!$util.isInteger(message.elapsedUs) && !(message.elapsedUs && $util.isInteger(message.elapsedUs.low) && $util.isInteger(message.elapsedUs.high)))
                return "elapsedUs: integer|Long expected";
        if (message.seqDelta != null && message.hasOwnProperty("seqDelta"))
            if (!$util.isInteger(message.seqDelta))
                return "seqDelta: integer expected";
        if (message.missDelta != null && message.hasOwnProperty("missDelta"))
            if (!$util.isInteger(message.missDelta))
                return "missDelta: integer expected";
        if (message.overflowDelta != null && message.hasOwnProperty("overflowDelta"))
            if (!$util.isInteger(message.overflowDelta))
                return "overflowDelta: integer expected";
        if (message.seq != null && message.hasOwnProperty("seq"))
            if (!$util.isInteger(message.seq))
                return "seq: integer expected";
        if (message.ageUs != null && message.hasOwnProperty("ageUs"))
            if (!$util.isInteger(message.ageUs))
                return "ageUs: integer expected";
        if (message.rateTps != null && message.hasOwnProperty("rateTps"))
            if (!$util.isInteger(message.rateTps))
                return "rateTps: integer expected";
        if (message.rawAn3 != null && message.hasOwnProperty("rawAn3"))
            if (!$util.isInteger(message.rawAn3))
                return "rawAn3: integer expected";
        if (message.rawAn5 != null && message.hasOwnProperty("rawAn5"))
            if (!$util.isInteger(message.rawAn5))
                return "rawAn5: integer expected";
        if (message.rawAn6 != null && message.hasOwnProperty("rawAn6"))
            if (!$util.isInteger(message.rawAn6))
                return "rawAn6: integer expected";
        if (message.calAn3 != null && message.hasOwnProperty("calAn3"))
            if (typeof message.calAn3 !== "number")
                return "calAn3: number expected";
        if (message.calAn5 != null && message.hasOwnProperty("calAn5"))
            if (typeof message.calAn5 !== "number")
                return "calAn5: number expected";
        if (message.calAn6 != null && message.hasOwnProperty("calAn6"))
            if (typeof message.calAn6 !== "number")
                return "calAn6: number expected";
        if (message.latencyAvgUs != null && message.hasOwnProperty("latencyAvgUs"))
            if (!$util.isInteger(message.latencyAvgUs))
                return "latencyAvgUs: integer expected";
        if (message.latencyP95Us != null && message.hasOwnProperty("latencyP95Us"))
            if (!$util.isInteger(message.latencyP95Us))
                return "latencyP95Us: integer expected";
        if (message.faultCode != null && message.hasOwnProperty("faultCode"))
            if (!$util.isInteger(message.faultCode))
                return "faultCode: integer expected";
        if (message.timingSamples != null && message.hasOwnProperty("timingSamples"))
            if (!$util.isInteger(message.timingSamples))
                return "timingSamples: integer expected";
        if (message.playbackAvgUs != null && message.hasOwnProperty("playbackAvgUs"))
            if (typeof message.playbackAvgUs !== "number")
                return "playbackAvgUs: number expected";
        if (message.loopUs != null && message.hasOwnProperty("loopUs"))
            if (typeof message.loopUs !== "number")
                return "loopUs: number expected";
        if (message.overruns != null && message.hasOwnProperty("overruns"))
            if (!$util.isInteger(message.overruns))
                return "overruns: integer expected";
        if (message.timingFaults != null && message.hasOwnProperty("timingFaults"))
            if (!$util.isInteger(message.timingFaults))
                return "timingFaults: integer expected";
        if (message.message != null && message.hasOwnProperty("message"))
            if (!$util.isString(message.message))
                return "message: string expected";
        return null;
    };

    /**
     * Creates an AnalogDiagnosticResult message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AnalogDiagnosticResult} AnalogDiagnosticResult
     */
    AnalogDiagnosticResult.fromObject = function fromObject(object) {
        if (object instanceof $root.AnalogDiagnosticResult)
            return object;
        let message = new $root.AnalogDiagnosticResult();
        if (object.valid != null)
            message.valid = Boolean(object.valid);
        if (object.running != null)
            message.running = Boolean(object.running);
        if (object.durationMs != null)
            message.durationMs = object.durationMs >>> 0;
        if (object.elapsedUs != null)
            if ($util.Long)
                (message.elapsedUs = $util.Long.fromValue(object.elapsedUs)).unsigned = true;
            else if (typeof object.elapsedUs === "string")
                message.elapsedUs = parseInt(object.elapsedUs, 10);
            else if (typeof object.elapsedUs === "number")
                message.elapsedUs = object.elapsedUs;
            else if (typeof object.elapsedUs === "object")
                message.elapsedUs = new $util.LongBits(object.elapsedUs.low >>> 0, object.elapsedUs.high >>> 0).toNumber(true);
        if (object.seqDelta != null)
            message.seqDelta = object.seqDelta >>> 0;
        if (object.missDelta != null)
            message.missDelta = object.missDelta >>> 0;
        if (object.overflowDelta != null)
            message.overflowDelta = object.overflowDelta >>> 0;
        if (object.seq != null)
            message.seq = object.seq >>> 0;
        if (object.ageUs != null)
            message.ageUs = object.ageUs >>> 0;
        if (object.rateTps != null)
            message.rateTps = object.rateTps >>> 0;
        if (object.rawAn3 != null)
            message.rawAn3 = object.rawAn3 >>> 0;
        if (object.rawAn5 != null)
            message.rawAn5 = object.rawAn5 >>> 0;
        if (object.rawAn6 != null)
            message.rawAn6 = object.rawAn6 >>> 0;
        if (object.calAn3 != null)
            message.calAn3 = Number(object.calAn3);
        if (object.calAn5 != null)
            message.calAn5 = Number(object.calAn5);
        if (object.calAn6 != null)
            message.calAn6 = Number(object.calAn6);
        if (object.latencyAvgUs != null)
            message.latencyAvgUs = object.latencyAvgUs >>> 0;
        if (object.latencyP95Us != null)
            message.latencyP95Us = object.latencyP95Us >>> 0;
        if (object.faultCode != null)
            message.faultCode = object.faultCode >>> 0;
        if (object.timingSamples != null)
            message.timingSamples = object.timingSamples >>> 0;
        if (object.playbackAvgUs != null)
            message.playbackAvgUs = Number(object.playbackAvgUs);
        if (object.loopUs != null)
            message.loopUs = Number(object.loopUs);
        if (object.overruns != null)
            message.overruns = object.overruns >>> 0;
        if (object.timingFaults != null)
            message.timingFaults = object.timingFaults >>> 0;
        if (object.message != null)
            message.message = String(object.message);
        return message;
    };

    /**
     * Creates a plain object from an AnalogDiagnosticResult message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {AnalogDiagnosticResult} message AnalogDiagnosticResult
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AnalogDiagnosticResult.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.valid = false;
            object.running = false;
            object.durationMs = 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, true);
                object.elapsedUs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.elapsedUs = options.longs === String ? "0" : 0;
            object.seqDelta = 0;
            object.missDelta = 0;
            object.overflowDelta = 0;
            object.seq = 0;
            object.ageUs = 0;
            object.rateTps = 0;
            object.rawAn3 = 0;
            object.rawAn5 = 0;
            object.rawAn6 = 0;
            object.calAn3 = 0;
            object.calAn5 = 0;
            object.calAn6 = 0;
            object.latencyAvgUs = 0;
            object.latencyP95Us = 0;
            object.faultCode = 0;
            object.timingSamples = 0;
            object.playbackAvgUs = 0;
            object.loopUs = 0;
            object.overruns = 0;
            object.timingFaults = 0;
            object.message = "";
        }
        if (message.valid != null && message.hasOwnProperty("valid"))
            object.valid = message.valid;
        if (message.running != null && message.hasOwnProperty("running"))
            object.running = message.running;
        if (message.durationMs != null && message.hasOwnProperty("durationMs"))
            object.durationMs = message.durationMs;
        if (message.elapsedUs != null && message.hasOwnProperty("elapsedUs"))
            if (typeof message.elapsedUs === "number")
                object.elapsedUs = options.longs === String ? String(message.elapsedUs) : message.elapsedUs;
            else
                object.elapsedUs = options.longs === String ? $util.Long.prototype.toString.call(message.elapsedUs) : options.longs === Number ? new $util.LongBits(message.elapsedUs.low >>> 0, message.elapsedUs.high >>> 0).toNumber(true) : message.elapsedUs;
        if (message.seqDelta != null && message.hasOwnProperty("seqDelta"))
            object.seqDelta = message.seqDelta;
        if (message.missDelta != null && message.hasOwnProperty("missDelta"))
            object.missDelta = message.missDelta;
        if (message.overflowDelta != null && message.hasOwnProperty("overflowDelta"))
            object.overflowDelta = message.overflowDelta;
        if (message.seq != null && message.hasOwnProperty("seq"))
            object.seq = message.seq;
        if (message.ageUs != null && message.hasOwnProperty("ageUs"))
            object.ageUs = message.ageUs;
        if (message.rateTps != null && message.hasOwnProperty("rateTps"))
            object.rateTps = message.rateTps;
        if (message.rawAn3 != null && message.hasOwnProperty("rawAn3"))
            object.rawAn3 = message.rawAn3;
        if (message.rawAn5 != null && message.hasOwnProperty("rawAn5"))
            object.rawAn5 = message.rawAn5;
        if (message.rawAn6 != null && message.hasOwnProperty("rawAn6"))
            object.rawAn6 = message.rawAn6;
        if (message.calAn3 != null && message.hasOwnProperty("calAn3"))
            object.calAn3 = options.json && !isFinite(message.calAn3) ? String(message.calAn3) : message.calAn3;
        if (message.calAn5 != null && message.hasOwnProperty("calAn5"))
            object.calAn5 = options.json && !isFinite(message.calAn5) ? String(message.calAn5) : message.calAn5;
        if (message.calAn6 != null && message.hasOwnProperty("calAn6"))
            object.calAn6 = options.json && !isFinite(message.calAn6) ? String(message.calAn6) : message.calAn6;
        if (message.latencyAvgUs != null && message.hasOwnProperty("latencyAvgUs"))
            object.latencyAvgUs = message.latencyAvgUs;
        if (message.latencyP95Us != null && message.hasOwnProperty("latencyP95Us"))
            object.latencyP95Us = message.latencyP95Us;
        if (message.faultCode != null && message.hasOwnProperty("faultCode"))
            object.faultCode = message.faultCode;
        if (message.timingSamples != null && message.hasOwnProperty("timingSamples"))
            object.timingSamples = message.timingSamples;
        if (message.playbackAvgUs != null && message.hasOwnProperty("playbackAvgUs"))
            object.playbackAvgUs = options.json && !isFinite(message.playbackAvgUs) ? String(message.playbackAvgUs) : message.playbackAvgUs;
        if (message.loopUs != null && message.hasOwnProperty("loopUs"))
            object.loopUs = options.json && !isFinite(message.loopUs) ? String(message.loopUs) : message.loopUs;
        if (message.overruns != null && message.hasOwnProperty("overruns"))
            object.overruns = message.overruns;
        if (message.timingFaults != null && message.hasOwnProperty("timingFaults"))
            object.timingFaults = message.timingFaults;
        if (message.message != null && message.hasOwnProperty("message"))
            object.message = message.message;
        return object;
    };

    /**
     * Converts this AnalogDiagnosticResult to JSON.
     * @function toJSON
     * @memberof AnalogDiagnosticResult
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AnalogDiagnosticResult.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AnalogDiagnosticResult
     * @function getTypeUrl
     * @memberof AnalogDiagnosticResult
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AnalogDiagnosticResult.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AnalogDiagnosticResult";
    };

    return AnalogDiagnosticResult;
})();

export const AnalogConfigCaseResult = $root.AnalogConfigCaseResult = (() => {

    /**
     * Properties of an AnalogConfigCaseResult.
     * @exports IAnalogConfigCaseResult
     * @interface IAnalogConfigCaseResult
     * @property {number|null} [sampleHz] AnalogConfigCaseResult sampleHz
     * @property {number|null} [durationMs] AnalogConfigCaseResult durationMs
     * @property {number|Long|null} [elapsedUs] AnalogConfigCaseResult elapsedUs
     * @property {number|null} [seqDelta] AnalogConfigCaseResult seqDelta
     * @property {number|null} [rateTps] AnalogConfigCaseResult rateTps
     * @property {number|null} [ageUs] AnalogConfigCaseResult ageUs
     * @property {number|null} [missDelta] AnalogConfigCaseResult missDelta
     * @property {number|null} [overflowDelta] AnalogConfigCaseResult overflowDelta
     * @property {number|null} [faultCode] AnalogConfigCaseResult faultCode
     * @property {number|null} [latencyAvgUs] AnalogConfigCaseResult latencyAvgUs
     * @property {number|null} [latencyP95Us] AnalogConfigCaseResult latencyP95Us
     * @property {number|null} [playbackAvgUsX100] AnalogConfigCaseResult playbackAvgUsX100
     * @property {number|null} [loopUsX100] AnalogConfigCaseResult loopUsX100
     * @property {number|null} [overrunsDelta] AnalogConfigCaseResult overrunsDelta
     * @property {number|null} [timingFaultsDelta] AnalogConfigCaseResult timingFaultsDelta
     * @property {number|null} [dmaSamplesDelta] AnalogConfigCaseResult dmaSamplesDelta
     * @property {number|null} [dmaAnomaliesDelta] AnalogConfigCaseResult dmaAnomaliesDelta
     */

    /**
     * Constructs a new AnalogConfigCaseResult.
     * @exports AnalogConfigCaseResult
     * @classdesc Represents an AnalogConfigCaseResult.
     * @implements IAnalogConfigCaseResult
     * @constructor
     * @param {IAnalogConfigCaseResult=} [properties] Properties to set
     */
    function AnalogConfigCaseResult(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AnalogConfigCaseResult sampleHz.
     * @member {number} sampleHz
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.sampleHz = 0;

    /**
     * AnalogConfigCaseResult durationMs.
     * @member {number} durationMs
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.durationMs = 0;

    /**
     * AnalogConfigCaseResult elapsedUs.
     * @member {number|Long} elapsedUs
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.elapsedUs = $util.Long ? $util.Long.fromBits(0,0,true) : 0;

    /**
     * AnalogConfigCaseResult seqDelta.
     * @member {number} seqDelta
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.seqDelta = 0;

    /**
     * AnalogConfigCaseResult rateTps.
     * @member {number} rateTps
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.rateTps = 0;

    /**
     * AnalogConfigCaseResult ageUs.
     * @member {number} ageUs
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.ageUs = 0;

    /**
     * AnalogConfigCaseResult missDelta.
     * @member {number} missDelta
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.missDelta = 0;

    /**
     * AnalogConfigCaseResult overflowDelta.
     * @member {number} overflowDelta
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.overflowDelta = 0;

    /**
     * AnalogConfigCaseResult faultCode.
     * @member {number} faultCode
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.faultCode = 0;

    /**
     * AnalogConfigCaseResult latencyAvgUs.
     * @member {number} latencyAvgUs
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.latencyAvgUs = 0;

    /**
     * AnalogConfigCaseResult latencyP95Us.
     * @member {number} latencyP95Us
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.latencyP95Us = 0;

    /**
     * AnalogConfigCaseResult playbackAvgUsX100.
     * @member {number} playbackAvgUsX100
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.playbackAvgUsX100 = 0;

    /**
     * AnalogConfigCaseResult loopUsX100.
     * @member {number} loopUsX100
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.loopUsX100 = 0;

    /**
     * AnalogConfigCaseResult overrunsDelta.
     * @member {number} overrunsDelta
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.overrunsDelta = 0;

    /**
     * AnalogConfigCaseResult timingFaultsDelta.
     * @member {number} timingFaultsDelta
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.timingFaultsDelta = 0;

    /**
     * AnalogConfigCaseResult dmaSamplesDelta.
     * @member {number} dmaSamplesDelta
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.dmaSamplesDelta = 0;

    /**
     * AnalogConfigCaseResult dmaAnomaliesDelta.
     * @member {number} dmaAnomaliesDelta
     * @memberof AnalogConfigCaseResult
     * @instance
     */
    AnalogConfigCaseResult.prototype.dmaAnomaliesDelta = 0;

    /**
     * Creates a new AnalogConfigCaseResult instance using the specified properties.
     * @function create
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {IAnalogConfigCaseResult=} [properties] Properties to set
     * @returns {AnalogConfigCaseResult} AnalogConfigCaseResult instance
     */
    AnalogConfigCaseResult.create = function create(properties) {
        return new AnalogConfigCaseResult(properties);
    };

    /**
     * Encodes the specified AnalogConfigCaseResult message. Does not implicitly {@link AnalogConfigCaseResult.verify|verify} messages.
     * @function encode
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {IAnalogConfigCaseResult} message AnalogConfigCaseResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogConfigCaseResult.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.sampleHz != null && Object.hasOwnProperty.call(message, "sampleHz"))
            writer.uint32(/* id 1, wireType 0 =*/8).uint32(message.sampleHz);
        if (message.durationMs != null && Object.hasOwnProperty.call(message, "durationMs"))
            writer.uint32(/* id 2, wireType 0 =*/16).uint32(message.durationMs);
        if (message.elapsedUs != null && Object.hasOwnProperty.call(message, "elapsedUs"))
            writer.uint32(/* id 3, wireType 0 =*/24).uint64(message.elapsedUs);
        if (message.seqDelta != null && Object.hasOwnProperty.call(message, "seqDelta"))
            writer.uint32(/* id 4, wireType 0 =*/32).uint32(message.seqDelta);
        if (message.rateTps != null && Object.hasOwnProperty.call(message, "rateTps"))
            writer.uint32(/* id 5, wireType 0 =*/40).uint32(message.rateTps);
        if (message.ageUs != null && Object.hasOwnProperty.call(message, "ageUs"))
            writer.uint32(/* id 6, wireType 0 =*/48).uint32(message.ageUs);
        if (message.missDelta != null && Object.hasOwnProperty.call(message, "missDelta"))
            writer.uint32(/* id 7, wireType 0 =*/56).uint32(message.missDelta);
        if (message.overflowDelta != null && Object.hasOwnProperty.call(message, "overflowDelta"))
            writer.uint32(/* id 8, wireType 0 =*/64).uint32(message.overflowDelta);
        if (message.faultCode != null && Object.hasOwnProperty.call(message, "faultCode"))
            writer.uint32(/* id 9, wireType 0 =*/72).uint32(message.faultCode);
        if (message.latencyAvgUs != null && Object.hasOwnProperty.call(message, "latencyAvgUs"))
            writer.uint32(/* id 10, wireType 0 =*/80).uint32(message.latencyAvgUs);
        if (message.latencyP95Us != null && Object.hasOwnProperty.call(message, "latencyP95Us"))
            writer.uint32(/* id 11, wireType 0 =*/88).uint32(message.latencyP95Us);
        if (message.playbackAvgUsX100 != null && Object.hasOwnProperty.call(message, "playbackAvgUsX100"))
            writer.uint32(/* id 12, wireType 0 =*/96).uint32(message.playbackAvgUsX100);
        if (message.loopUsX100 != null && Object.hasOwnProperty.call(message, "loopUsX100"))
            writer.uint32(/* id 13, wireType 0 =*/104).uint32(message.loopUsX100);
        if (message.overrunsDelta != null && Object.hasOwnProperty.call(message, "overrunsDelta"))
            writer.uint32(/* id 14, wireType 0 =*/112).uint32(message.overrunsDelta);
        if (message.timingFaultsDelta != null && Object.hasOwnProperty.call(message, "timingFaultsDelta"))
            writer.uint32(/* id 15, wireType 0 =*/120).uint32(message.timingFaultsDelta);
        if (message.dmaSamplesDelta != null && Object.hasOwnProperty.call(message, "dmaSamplesDelta"))
            writer.uint32(/* id 16, wireType 0 =*/128).uint32(message.dmaSamplesDelta);
        if (message.dmaAnomaliesDelta != null && Object.hasOwnProperty.call(message, "dmaAnomaliesDelta"))
            writer.uint32(/* id 17, wireType 0 =*/136).uint32(message.dmaAnomaliesDelta);
        return writer;
    };

    /**
     * Encodes the specified AnalogConfigCaseResult message, length delimited. Does not implicitly {@link AnalogConfigCaseResult.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {IAnalogConfigCaseResult} message AnalogConfigCaseResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogConfigCaseResult.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AnalogConfigCaseResult message from the specified reader or buffer.
     * @function decode
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AnalogConfigCaseResult} AnalogConfigCaseResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogConfigCaseResult.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AnalogConfigCaseResult();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.sampleHz = reader.uint32();
                    break;
                }
            case 2: {
                    message.durationMs = reader.uint32();
                    break;
                }
            case 3: {
                    message.elapsedUs = reader.uint64();
                    break;
                }
            case 4: {
                    message.seqDelta = reader.uint32();
                    break;
                }
            case 5: {
                    message.rateTps = reader.uint32();
                    break;
                }
            case 6: {
                    message.ageUs = reader.uint32();
                    break;
                }
            case 7: {
                    message.missDelta = reader.uint32();
                    break;
                }
            case 8: {
                    message.overflowDelta = reader.uint32();
                    break;
                }
            case 9: {
                    message.faultCode = reader.uint32();
                    break;
                }
            case 10: {
                    message.latencyAvgUs = reader.uint32();
                    break;
                }
            case 11: {
                    message.latencyP95Us = reader.uint32();
                    break;
                }
            case 12: {
                    message.playbackAvgUsX100 = reader.uint32();
                    break;
                }
            case 13: {
                    message.loopUsX100 = reader.uint32();
                    break;
                }
            case 14: {
                    message.overrunsDelta = reader.uint32();
                    break;
                }
            case 15: {
                    message.timingFaultsDelta = reader.uint32();
                    break;
                }
            case 16: {
                    message.dmaSamplesDelta = reader.uint32();
                    break;
                }
            case 17: {
                    message.dmaAnomaliesDelta = reader.uint32();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AnalogConfigCaseResult message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AnalogConfigCaseResult} AnalogConfigCaseResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogConfigCaseResult.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AnalogConfigCaseResult message.
     * @function verify
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AnalogConfigCaseResult.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.sampleHz != null && message.hasOwnProperty("sampleHz"))
            if (!$util.isInteger(message.sampleHz))
                return "sampleHz: integer expected";
        if (message.durationMs != null && message.hasOwnProperty("durationMs"))
            if (!$util.isInteger(message.durationMs))
                return "durationMs: integer expected";
        if (message.elapsedUs != null && message.hasOwnProperty("elapsedUs"))
            if (!$util.isInteger(message.elapsedUs) && !(message.elapsedUs && $util.isInteger(message.elapsedUs.low) && $util.isInteger(message.elapsedUs.high)))
                return "elapsedUs: integer|Long expected";
        if (message.seqDelta != null && message.hasOwnProperty("seqDelta"))
            if (!$util.isInteger(message.seqDelta))
                return "seqDelta: integer expected";
        if (message.rateTps != null && message.hasOwnProperty("rateTps"))
            if (!$util.isInteger(message.rateTps))
                return "rateTps: integer expected";
        if (message.ageUs != null && message.hasOwnProperty("ageUs"))
            if (!$util.isInteger(message.ageUs))
                return "ageUs: integer expected";
        if (message.missDelta != null && message.hasOwnProperty("missDelta"))
            if (!$util.isInteger(message.missDelta))
                return "missDelta: integer expected";
        if (message.overflowDelta != null && message.hasOwnProperty("overflowDelta"))
            if (!$util.isInteger(message.overflowDelta))
                return "overflowDelta: integer expected";
        if (message.faultCode != null && message.hasOwnProperty("faultCode"))
            if (!$util.isInteger(message.faultCode))
                return "faultCode: integer expected";
        if (message.latencyAvgUs != null && message.hasOwnProperty("latencyAvgUs"))
            if (!$util.isInteger(message.latencyAvgUs))
                return "latencyAvgUs: integer expected";
        if (message.latencyP95Us != null && message.hasOwnProperty("latencyP95Us"))
            if (!$util.isInteger(message.latencyP95Us))
                return "latencyP95Us: integer expected";
        if (message.playbackAvgUsX100 != null && message.hasOwnProperty("playbackAvgUsX100"))
            if (!$util.isInteger(message.playbackAvgUsX100))
                return "playbackAvgUsX100: integer expected";
        if (message.loopUsX100 != null && message.hasOwnProperty("loopUsX100"))
            if (!$util.isInteger(message.loopUsX100))
                return "loopUsX100: integer expected";
        if (message.overrunsDelta != null && message.hasOwnProperty("overrunsDelta"))
            if (!$util.isInteger(message.overrunsDelta))
                return "overrunsDelta: integer expected";
        if (message.timingFaultsDelta != null && message.hasOwnProperty("timingFaultsDelta"))
            if (!$util.isInteger(message.timingFaultsDelta))
                return "timingFaultsDelta: integer expected";
        if (message.dmaSamplesDelta != null && message.hasOwnProperty("dmaSamplesDelta"))
            if (!$util.isInteger(message.dmaSamplesDelta))
                return "dmaSamplesDelta: integer expected";
        if (message.dmaAnomaliesDelta != null && message.hasOwnProperty("dmaAnomaliesDelta"))
            if (!$util.isInteger(message.dmaAnomaliesDelta))
                return "dmaAnomaliesDelta: integer expected";
        return null;
    };

    /**
     * Creates an AnalogConfigCaseResult message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AnalogConfigCaseResult} AnalogConfigCaseResult
     */
    AnalogConfigCaseResult.fromObject = function fromObject(object) {
        if (object instanceof $root.AnalogConfigCaseResult)
            return object;
        let message = new $root.AnalogConfigCaseResult();
        if (object.sampleHz != null)
            message.sampleHz = object.sampleHz >>> 0;
        if (object.durationMs != null)
            message.durationMs = object.durationMs >>> 0;
        if (object.elapsedUs != null)
            if ($util.Long)
                (message.elapsedUs = $util.Long.fromValue(object.elapsedUs)).unsigned = true;
            else if (typeof object.elapsedUs === "string")
                message.elapsedUs = parseInt(object.elapsedUs, 10);
            else if (typeof object.elapsedUs === "number")
                message.elapsedUs = object.elapsedUs;
            else if (typeof object.elapsedUs === "object")
                message.elapsedUs = new $util.LongBits(object.elapsedUs.low >>> 0, object.elapsedUs.high >>> 0).toNumber(true);
        if (object.seqDelta != null)
            message.seqDelta = object.seqDelta >>> 0;
        if (object.rateTps != null)
            message.rateTps = object.rateTps >>> 0;
        if (object.ageUs != null)
            message.ageUs = object.ageUs >>> 0;
        if (object.missDelta != null)
            message.missDelta = object.missDelta >>> 0;
        if (object.overflowDelta != null)
            message.overflowDelta = object.overflowDelta >>> 0;
        if (object.faultCode != null)
            message.faultCode = object.faultCode >>> 0;
        if (object.latencyAvgUs != null)
            message.latencyAvgUs = object.latencyAvgUs >>> 0;
        if (object.latencyP95Us != null)
            message.latencyP95Us = object.latencyP95Us >>> 0;
        if (object.playbackAvgUsX100 != null)
            message.playbackAvgUsX100 = object.playbackAvgUsX100 >>> 0;
        if (object.loopUsX100 != null)
            message.loopUsX100 = object.loopUsX100 >>> 0;
        if (object.overrunsDelta != null)
            message.overrunsDelta = object.overrunsDelta >>> 0;
        if (object.timingFaultsDelta != null)
            message.timingFaultsDelta = object.timingFaultsDelta >>> 0;
        if (object.dmaSamplesDelta != null)
            message.dmaSamplesDelta = object.dmaSamplesDelta >>> 0;
        if (object.dmaAnomaliesDelta != null)
            message.dmaAnomaliesDelta = object.dmaAnomaliesDelta >>> 0;
        return message;
    };

    /**
     * Creates a plain object from an AnalogConfigCaseResult message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {AnalogConfigCaseResult} message AnalogConfigCaseResult
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AnalogConfigCaseResult.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.defaults) {
            object.sampleHz = 0;
            object.durationMs = 0;
            if ($util.Long) {
                let long = new $util.Long(0, 0, true);
                object.elapsedUs = options.longs === String ? long.toString() : options.longs === Number ? long.toNumber() : long;
            } else
                object.elapsedUs = options.longs === String ? "0" : 0;
            object.seqDelta = 0;
            object.rateTps = 0;
            object.ageUs = 0;
            object.missDelta = 0;
            object.overflowDelta = 0;
            object.faultCode = 0;
            object.latencyAvgUs = 0;
            object.latencyP95Us = 0;
            object.playbackAvgUsX100 = 0;
            object.loopUsX100 = 0;
            object.overrunsDelta = 0;
            object.timingFaultsDelta = 0;
            object.dmaSamplesDelta = 0;
            object.dmaAnomaliesDelta = 0;
        }
        if (message.sampleHz != null && message.hasOwnProperty("sampleHz"))
            object.sampleHz = message.sampleHz;
        if (message.durationMs != null && message.hasOwnProperty("durationMs"))
            object.durationMs = message.durationMs;
        if (message.elapsedUs != null && message.hasOwnProperty("elapsedUs"))
            if (typeof message.elapsedUs === "number")
                object.elapsedUs = options.longs === String ? String(message.elapsedUs) : message.elapsedUs;
            else
                object.elapsedUs = options.longs === String ? $util.Long.prototype.toString.call(message.elapsedUs) : options.longs === Number ? new $util.LongBits(message.elapsedUs.low >>> 0, message.elapsedUs.high >>> 0).toNumber(true) : message.elapsedUs;
        if (message.seqDelta != null && message.hasOwnProperty("seqDelta"))
            object.seqDelta = message.seqDelta;
        if (message.rateTps != null && message.hasOwnProperty("rateTps"))
            object.rateTps = message.rateTps;
        if (message.ageUs != null && message.hasOwnProperty("ageUs"))
            object.ageUs = message.ageUs;
        if (message.missDelta != null && message.hasOwnProperty("missDelta"))
            object.missDelta = message.missDelta;
        if (message.overflowDelta != null && message.hasOwnProperty("overflowDelta"))
            object.overflowDelta = message.overflowDelta;
        if (message.faultCode != null && message.hasOwnProperty("faultCode"))
            object.faultCode = message.faultCode;
        if (message.latencyAvgUs != null && message.hasOwnProperty("latencyAvgUs"))
            object.latencyAvgUs = message.latencyAvgUs;
        if (message.latencyP95Us != null && message.hasOwnProperty("latencyP95Us"))
            object.latencyP95Us = message.latencyP95Us;
        if (message.playbackAvgUsX100 != null && message.hasOwnProperty("playbackAvgUsX100"))
            object.playbackAvgUsX100 = message.playbackAvgUsX100;
        if (message.loopUsX100 != null && message.hasOwnProperty("loopUsX100"))
            object.loopUsX100 = message.loopUsX100;
        if (message.overrunsDelta != null && message.hasOwnProperty("overrunsDelta"))
            object.overrunsDelta = message.overrunsDelta;
        if (message.timingFaultsDelta != null && message.hasOwnProperty("timingFaultsDelta"))
            object.timingFaultsDelta = message.timingFaultsDelta;
        if (message.dmaSamplesDelta != null && message.hasOwnProperty("dmaSamplesDelta"))
            object.dmaSamplesDelta = message.dmaSamplesDelta;
        if (message.dmaAnomaliesDelta != null && message.hasOwnProperty("dmaAnomaliesDelta"))
            object.dmaAnomaliesDelta = message.dmaAnomaliesDelta;
        return object;
    };

    /**
     * Converts this AnalogConfigCaseResult to JSON.
     * @function toJSON
     * @memberof AnalogConfigCaseResult
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AnalogConfigCaseResult.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AnalogConfigCaseResult
     * @function getTypeUrl
     * @memberof AnalogConfigCaseResult
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AnalogConfigCaseResult.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AnalogConfigCaseResult";
    };

    return AnalogConfigCaseResult;
})();

export const AnalogConfigTestResult = $root.AnalogConfigTestResult = (() => {

    /**
     * Properties of an AnalogConfigTestResult.
     * @exports IAnalogConfigTestResult
     * @interface IAnalogConfigTestResult
     * @property {boolean|null} [valid] AnalogConfigTestResult valid
     * @property {boolean|null} [running] AnalogConfigTestResult running
     * @property {number|null} [caseCount] AnalogConfigTestResult caseCount
     * @property {Array.<IAnalogConfigCaseResult>|null} [cases] AnalogConfigTestResult cases
     * @property {string|null} [message] AnalogConfigTestResult message
     */

    /**
     * Constructs a new AnalogConfigTestResult.
     * @exports AnalogConfigTestResult
     * @classdesc Represents an AnalogConfigTestResult.
     * @implements IAnalogConfigTestResult
     * @constructor
     * @param {IAnalogConfigTestResult=} [properties] Properties to set
     */
    function AnalogConfigTestResult(properties) {
        this.cases = [];
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * AnalogConfigTestResult valid.
     * @member {boolean} valid
     * @memberof AnalogConfigTestResult
     * @instance
     */
    AnalogConfigTestResult.prototype.valid = false;

    /**
     * AnalogConfigTestResult running.
     * @member {boolean} running
     * @memberof AnalogConfigTestResult
     * @instance
     */
    AnalogConfigTestResult.prototype.running = false;

    /**
     * AnalogConfigTestResult caseCount.
     * @member {number} caseCount
     * @memberof AnalogConfigTestResult
     * @instance
     */
    AnalogConfigTestResult.prototype.caseCount = 0;

    /**
     * AnalogConfigTestResult cases.
     * @member {Array.<IAnalogConfigCaseResult>} cases
     * @memberof AnalogConfigTestResult
     * @instance
     */
    AnalogConfigTestResult.prototype.cases = $util.emptyArray;

    /**
     * AnalogConfigTestResult message.
     * @member {string} message
     * @memberof AnalogConfigTestResult
     * @instance
     */
    AnalogConfigTestResult.prototype.message = "";

    /**
     * Creates a new AnalogConfigTestResult instance using the specified properties.
     * @function create
     * @memberof AnalogConfigTestResult
     * @static
     * @param {IAnalogConfigTestResult=} [properties] Properties to set
     * @returns {AnalogConfigTestResult} AnalogConfigTestResult instance
     */
    AnalogConfigTestResult.create = function create(properties) {
        return new AnalogConfigTestResult(properties);
    };

    /**
     * Encodes the specified AnalogConfigTestResult message. Does not implicitly {@link AnalogConfigTestResult.verify|verify} messages.
     * @function encode
     * @memberof AnalogConfigTestResult
     * @static
     * @param {IAnalogConfigTestResult} message AnalogConfigTestResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogConfigTestResult.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.valid != null && Object.hasOwnProperty.call(message, "valid"))
            writer.uint32(/* id 1, wireType 0 =*/8).bool(message.valid);
        if (message.running != null && Object.hasOwnProperty.call(message, "running"))
            writer.uint32(/* id 2, wireType 0 =*/16).bool(message.running);
        if (message.caseCount != null && Object.hasOwnProperty.call(message, "caseCount"))
            writer.uint32(/* id 3, wireType 0 =*/24).uint32(message.caseCount);
        if (message.cases != null && message.cases.length)
            for (let i = 0; i < message.cases.length; ++i)
                $root.AnalogConfigCaseResult.encode(message.cases[i], writer.uint32(/* id 4, wireType 2 =*/34).fork()).ldelim();
        if (message.message != null && Object.hasOwnProperty.call(message, "message"))
            writer.uint32(/* id 5, wireType 2 =*/42).string(message.message);
        return writer;
    };

    /**
     * Encodes the specified AnalogConfigTestResult message, length delimited. Does not implicitly {@link AnalogConfigTestResult.verify|verify} messages.
     * @function encodeDelimited
     * @memberof AnalogConfigTestResult
     * @static
     * @param {IAnalogConfigTestResult} message AnalogConfigTestResult message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    AnalogConfigTestResult.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes an AnalogConfigTestResult message from the specified reader or buffer.
     * @function decode
     * @memberof AnalogConfigTestResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {AnalogConfigTestResult} AnalogConfigTestResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogConfigTestResult.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.AnalogConfigTestResult();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.valid = reader.bool();
                    break;
                }
            case 2: {
                    message.running = reader.bool();
                    break;
                }
            case 3: {
                    message.caseCount = reader.uint32();
                    break;
                }
            case 4: {
                    if (!(message.cases && message.cases.length))
                        message.cases = [];
                    message.cases.push($root.AnalogConfigCaseResult.decode(reader, reader.uint32()));
                    break;
                }
            case 5: {
                    message.message = reader.string();
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes an AnalogConfigTestResult message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof AnalogConfigTestResult
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {AnalogConfigTestResult} AnalogConfigTestResult
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    AnalogConfigTestResult.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies an AnalogConfigTestResult message.
     * @function verify
     * @memberof AnalogConfigTestResult
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    AnalogConfigTestResult.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        if (message.valid != null && message.hasOwnProperty("valid"))
            if (typeof message.valid !== "boolean")
                return "valid: boolean expected";
        if (message.running != null && message.hasOwnProperty("running"))
            if (typeof message.running !== "boolean")
                return "running: boolean expected";
        if (message.caseCount != null && message.hasOwnProperty("caseCount"))
            if (!$util.isInteger(message.caseCount))
                return "caseCount: integer expected";
        if (message.cases != null && message.hasOwnProperty("cases")) {
            if (!Array.isArray(message.cases))
                return "cases: array expected";
            for (let i = 0; i < message.cases.length; ++i) {
                let error = $root.AnalogConfigCaseResult.verify(message.cases[i]);
                if (error)
                    return "cases." + error;
            }
        }
        if (message.message != null && message.hasOwnProperty("message"))
            if (!$util.isString(message.message))
                return "message: string expected";
        return null;
    };

    /**
     * Creates an AnalogConfigTestResult message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof AnalogConfigTestResult
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {AnalogConfigTestResult} AnalogConfigTestResult
     */
    AnalogConfigTestResult.fromObject = function fromObject(object) {
        if (object instanceof $root.AnalogConfigTestResult)
            return object;
        let message = new $root.AnalogConfigTestResult();
        if (object.valid != null)
            message.valid = Boolean(object.valid);
        if (object.running != null)
            message.running = Boolean(object.running);
        if (object.caseCount != null)
            message.caseCount = object.caseCount >>> 0;
        if (object.cases) {
            if (!Array.isArray(object.cases))
                throw TypeError(".AnalogConfigTestResult.cases: array expected");
            message.cases = [];
            for (let i = 0; i < object.cases.length; ++i) {
                if (typeof object.cases[i] !== "object")
                    throw TypeError(".AnalogConfigTestResult.cases: object expected");
                message.cases[i] = $root.AnalogConfigCaseResult.fromObject(object.cases[i]);
            }
        }
        if (object.message != null)
            message.message = String(object.message);
        return message;
    };

    /**
     * Creates a plain object from an AnalogConfigTestResult message. Also converts values to other types if specified.
     * @function toObject
     * @memberof AnalogConfigTestResult
     * @static
     * @param {AnalogConfigTestResult} message AnalogConfigTestResult
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    AnalogConfigTestResult.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (options.arrays || options.defaults)
            object.cases = [];
        if (options.defaults) {
            object.valid = false;
            object.running = false;
            object.caseCount = 0;
            object.message = "";
        }
        if (message.valid != null && message.hasOwnProperty("valid"))
            object.valid = message.valid;
        if (message.running != null && message.hasOwnProperty("running"))
            object.running = message.running;
        if (message.caseCount != null && message.hasOwnProperty("caseCount"))
            object.caseCount = message.caseCount;
        if (message.cases && message.cases.length) {
            object.cases = [];
            for (let j = 0; j < message.cases.length; ++j)
                object.cases[j] = $root.AnalogConfigCaseResult.toObject(message.cases[j], options);
        }
        if (message.message != null && message.hasOwnProperty("message"))
            object.message = message.message;
        return object;
    };

    /**
     * Converts this AnalogConfigTestResult to JSON.
     * @function toJSON
     * @memberof AnalogConfigTestResult
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    AnalogConfigTestResult.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for AnalogConfigTestResult
     * @function getTypeUrl
     * @memberof AnalogConfigTestResult
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    AnalogConfigTestResult.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/AnalogConfigTestResult";
    };

    return AnalogConfigTestResult;
})();

export const BlePacket = $root.BlePacket = (() => {

    /**
     * Properties of a BlePacket.
     * @exports IBlePacket
     * @interface IBlePacket
     * @property {ITelemetry|null} [telemetry] BlePacket telemetry
     * @property {ISystemStatus|null} [status] BlePacket status
     * @property {ILogMessage|null} [log] BlePacket log
     * @property {IOtaStatus|null} [otaStatus] BlePacket otaStatus
     * @property {IUiCommandResult|null} [commandResult] BlePacket commandResult
     * @property {IAnalogDiagnosticResult|null} [analogDiagnosticResult] BlePacket analogDiagnosticResult
     * @property {IAnalogConfigTestResult|null} [analogConfigTestResult] BlePacket analogConfigTestResult
     */

    /**
     * Constructs a new BlePacket.
     * @exports BlePacket
     * @classdesc Represents a BlePacket.
     * @implements IBlePacket
     * @constructor
     * @param {IBlePacket=} [properties] Properties to set
     */
    function BlePacket(properties) {
        if (properties)
            for (let keys = Object.keys(properties), i = 0; i < keys.length; ++i)
                if (properties[keys[i]] != null)
                    this[keys[i]] = properties[keys[i]];
    }

    /**
     * BlePacket telemetry.
     * @member {ITelemetry|null|undefined} telemetry
     * @memberof BlePacket
     * @instance
     */
    BlePacket.prototype.telemetry = null;

    /**
     * BlePacket status.
     * @member {ISystemStatus|null|undefined} status
     * @memberof BlePacket
     * @instance
     */
    BlePacket.prototype.status = null;

    /**
     * BlePacket log.
     * @member {ILogMessage|null|undefined} log
     * @memberof BlePacket
     * @instance
     */
    BlePacket.prototype.log = null;

    /**
     * BlePacket otaStatus.
     * @member {IOtaStatus|null|undefined} otaStatus
     * @memberof BlePacket
     * @instance
     */
    BlePacket.prototype.otaStatus = null;

    /**
     * BlePacket commandResult.
     * @member {IUiCommandResult|null|undefined} commandResult
     * @memberof BlePacket
     * @instance
     */
    BlePacket.prototype.commandResult = null;

    /**
     * BlePacket analogDiagnosticResult.
     * @member {IAnalogDiagnosticResult|null|undefined} analogDiagnosticResult
     * @memberof BlePacket
     * @instance
     */
    BlePacket.prototype.analogDiagnosticResult = null;

    /**
     * BlePacket analogConfigTestResult.
     * @member {IAnalogConfigTestResult|null|undefined} analogConfigTestResult
     * @memberof BlePacket
     * @instance
     */
    BlePacket.prototype.analogConfigTestResult = null;

    // OneOf field names bound to virtual getters and setters
    let $oneOfFields;

    /**
     * BlePacket payload.
     * @member {"telemetry"|"status"|"log"|"otaStatus"|"commandResult"|"analogDiagnosticResult"|"analogConfigTestResult"|undefined} payload
     * @memberof BlePacket
     * @instance
     */
    Object.defineProperty(BlePacket.prototype, "payload", {
        get: $util.oneOfGetter($oneOfFields = ["telemetry", "status", "log", "otaStatus", "commandResult", "analogDiagnosticResult", "analogConfigTestResult"]),
        set: $util.oneOfSetter($oneOfFields)
    });

    /**
     * Creates a new BlePacket instance using the specified properties.
     * @function create
     * @memberof BlePacket
     * @static
     * @param {IBlePacket=} [properties] Properties to set
     * @returns {BlePacket} BlePacket instance
     */
    BlePacket.create = function create(properties) {
        return new BlePacket(properties);
    };

    /**
     * Encodes the specified BlePacket message. Does not implicitly {@link BlePacket.verify|verify} messages.
     * @function encode
     * @memberof BlePacket
     * @static
     * @param {IBlePacket} message BlePacket message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    BlePacket.encode = function encode(message, writer) {
        if (!writer)
            writer = $Writer.create();
        if (message.telemetry != null && Object.hasOwnProperty.call(message, "telemetry"))
            $root.Telemetry.encode(message.telemetry, writer.uint32(/* id 1, wireType 2 =*/10).fork()).ldelim();
        if (message.status != null && Object.hasOwnProperty.call(message, "status"))
            $root.SystemStatus.encode(message.status, writer.uint32(/* id 2, wireType 2 =*/18).fork()).ldelim();
        if (message.log != null && Object.hasOwnProperty.call(message, "log"))
            $root.LogMessage.encode(message.log, writer.uint32(/* id 3, wireType 2 =*/26).fork()).ldelim();
        if (message.otaStatus != null && Object.hasOwnProperty.call(message, "otaStatus"))
            $root.OtaStatus.encode(message.otaStatus, writer.uint32(/* id 4, wireType 2 =*/34).fork()).ldelim();
        if (message.commandResult != null && Object.hasOwnProperty.call(message, "commandResult"))
            $root.UiCommandResult.encode(message.commandResult, writer.uint32(/* id 5, wireType 2 =*/42).fork()).ldelim();
        if (message.analogDiagnosticResult != null && Object.hasOwnProperty.call(message, "analogDiagnosticResult"))
            $root.AnalogDiagnosticResult.encode(message.analogDiagnosticResult, writer.uint32(/* id 6, wireType 2 =*/50).fork()).ldelim();
        if (message.analogConfigTestResult != null && Object.hasOwnProperty.call(message, "analogConfigTestResult"))
            $root.AnalogConfigTestResult.encode(message.analogConfigTestResult, writer.uint32(/* id 7, wireType 2 =*/58).fork()).ldelim();
        return writer;
    };

    /**
     * Encodes the specified BlePacket message, length delimited. Does not implicitly {@link BlePacket.verify|verify} messages.
     * @function encodeDelimited
     * @memberof BlePacket
     * @static
     * @param {IBlePacket} message BlePacket message or plain object to encode
     * @param {$protobuf.Writer} [writer] Writer to encode to
     * @returns {$protobuf.Writer} Writer
     */
    BlePacket.encodeDelimited = function encodeDelimited(message, writer) {
        return this.encode(message, writer).ldelim();
    };

    /**
     * Decodes a BlePacket message from the specified reader or buffer.
     * @function decode
     * @memberof BlePacket
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @param {number} [length] Message length if known beforehand
     * @returns {BlePacket} BlePacket
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    BlePacket.decode = function decode(reader, length, error) {
        if (!(reader instanceof $Reader))
            reader = $Reader.create(reader);
        let end = length === undefined ? reader.len : reader.pos + length, message = new $root.BlePacket();
        while (reader.pos < end) {
            let tag = reader.uint32();
            if (tag === error)
                break;
            switch (tag >>> 3) {
            case 1: {
                    message.telemetry = $root.Telemetry.decode(reader, reader.uint32());
                    break;
                }
            case 2: {
                    message.status = $root.SystemStatus.decode(reader, reader.uint32());
                    break;
                }
            case 3: {
                    message.log = $root.LogMessage.decode(reader, reader.uint32());
                    break;
                }
            case 4: {
                    message.otaStatus = $root.OtaStatus.decode(reader, reader.uint32());
                    break;
                }
            case 5: {
                    message.commandResult = $root.UiCommandResult.decode(reader, reader.uint32());
                    break;
                }
            case 6: {
                    message.analogDiagnosticResult = $root.AnalogDiagnosticResult.decode(reader, reader.uint32());
                    break;
                }
            case 7: {
                    message.analogConfigTestResult = $root.AnalogConfigTestResult.decode(reader, reader.uint32());
                    break;
                }
            default:
                reader.skipType(tag & 7);
                break;
            }
        }
        return message;
    };

    /**
     * Decodes a BlePacket message from the specified reader or buffer, length delimited.
     * @function decodeDelimited
     * @memberof BlePacket
     * @static
     * @param {$protobuf.Reader|Uint8Array} reader Reader or buffer to decode from
     * @returns {BlePacket} BlePacket
     * @throws {Error} If the payload is not a reader or valid buffer
     * @throws {$protobuf.util.ProtocolError} If required fields are missing
     */
    BlePacket.decodeDelimited = function decodeDelimited(reader) {
        if (!(reader instanceof $Reader))
            reader = new $Reader(reader);
        return this.decode(reader, reader.uint32());
    };

    /**
     * Verifies a BlePacket message.
     * @function verify
     * @memberof BlePacket
     * @static
     * @param {Object.<string,*>} message Plain object to verify
     * @returns {string|null} `null` if valid, otherwise the reason why it is not
     */
    BlePacket.verify = function verify(message) {
        if (typeof message !== "object" || message === null)
            return "object expected";
        let properties = {};
        if (message.telemetry != null && message.hasOwnProperty("telemetry")) {
            properties.payload = 1;
            {
                let error = $root.Telemetry.verify(message.telemetry);
                if (error)
                    return "telemetry." + error;
            }
        }
        if (message.status != null && message.hasOwnProperty("status")) {
            if (properties.payload === 1)
                return "payload: multiple values";
            properties.payload = 1;
            {
                let error = $root.SystemStatus.verify(message.status);
                if (error)
                    return "status." + error;
            }
        }
        if (message.log != null && message.hasOwnProperty("log")) {
            if (properties.payload === 1)
                return "payload: multiple values";
            properties.payload = 1;
            {
                let error = $root.LogMessage.verify(message.log);
                if (error)
                    return "log." + error;
            }
        }
        if (message.otaStatus != null && message.hasOwnProperty("otaStatus")) {
            if (properties.payload === 1)
                return "payload: multiple values";
            properties.payload = 1;
            {
                let error = $root.OtaStatus.verify(message.otaStatus);
                if (error)
                    return "otaStatus." + error;
            }
        }
        if (message.commandResult != null && message.hasOwnProperty("commandResult")) {
            if (properties.payload === 1)
                return "payload: multiple values";
            properties.payload = 1;
            {
                let error = $root.UiCommandResult.verify(message.commandResult);
                if (error)
                    return "commandResult." + error;
            }
        }
        if (message.analogDiagnosticResult != null && message.hasOwnProperty("analogDiagnosticResult")) {
            if (properties.payload === 1)
                return "payload: multiple values";
            properties.payload = 1;
            {
                let error = $root.AnalogDiagnosticResult.verify(message.analogDiagnosticResult);
                if (error)
                    return "analogDiagnosticResult." + error;
            }
        }
        if (message.analogConfigTestResult != null && message.hasOwnProperty("analogConfigTestResult")) {
            if (properties.payload === 1)
                return "payload: multiple values";
            properties.payload = 1;
            {
                let error = $root.AnalogConfigTestResult.verify(message.analogConfigTestResult);
                if (error)
                    return "analogConfigTestResult." + error;
            }
        }
        return null;
    };

    /**
     * Creates a BlePacket message from a plain object. Also converts values to their respective internal types.
     * @function fromObject
     * @memberof BlePacket
     * @static
     * @param {Object.<string,*>} object Plain object
     * @returns {BlePacket} BlePacket
     */
    BlePacket.fromObject = function fromObject(object) {
        if (object instanceof $root.BlePacket)
            return object;
        let message = new $root.BlePacket();
        if (object.telemetry != null) {
            if (typeof object.telemetry !== "object")
                throw TypeError(".BlePacket.telemetry: object expected");
            message.telemetry = $root.Telemetry.fromObject(object.telemetry);
        }
        if (object.status != null) {
            if (typeof object.status !== "object")
                throw TypeError(".BlePacket.status: object expected");
            message.status = $root.SystemStatus.fromObject(object.status);
        }
        if (object.log != null) {
            if (typeof object.log !== "object")
                throw TypeError(".BlePacket.log: object expected");
            message.log = $root.LogMessage.fromObject(object.log);
        }
        if (object.otaStatus != null) {
            if (typeof object.otaStatus !== "object")
                throw TypeError(".BlePacket.otaStatus: object expected");
            message.otaStatus = $root.OtaStatus.fromObject(object.otaStatus);
        }
        if (object.commandResult != null) {
            if (typeof object.commandResult !== "object")
                throw TypeError(".BlePacket.commandResult: object expected");
            message.commandResult = $root.UiCommandResult.fromObject(object.commandResult);
        }
        if (object.analogDiagnosticResult != null) {
            if (typeof object.analogDiagnosticResult !== "object")
                throw TypeError(".BlePacket.analogDiagnosticResult: object expected");
            message.analogDiagnosticResult = $root.AnalogDiagnosticResult.fromObject(object.analogDiagnosticResult);
        }
        if (object.analogConfigTestResult != null) {
            if (typeof object.analogConfigTestResult !== "object")
                throw TypeError(".BlePacket.analogConfigTestResult: object expected");
            message.analogConfigTestResult = $root.AnalogConfigTestResult.fromObject(object.analogConfigTestResult);
        }
        return message;
    };

    /**
     * Creates a plain object from a BlePacket message. Also converts values to other types if specified.
     * @function toObject
     * @memberof BlePacket
     * @static
     * @param {BlePacket} message BlePacket
     * @param {$protobuf.IConversionOptions} [options] Conversion options
     * @returns {Object.<string,*>} Plain object
     */
    BlePacket.toObject = function toObject(message, options) {
        if (!options)
            options = {};
        let object = {};
        if (message.telemetry != null && message.hasOwnProperty("telemetry")) {
            object.telemetry = $root.Telemetry.toObject(message.telemetry, options);
            if (options.oneofs)
                object.payload = "telemetry";
        }
        if (message.status != null && message.hasOwnProperty("status")) {
            object.status = $root.SystemStatus.toObject(message.status, options);
            if (options.oneofs)
                object.payload = "status";
        }
        if (message.log != null && message.hasOwnProperty("log")) {
            object.log = $root.LogMessage.toObject(message.log, options);
            if (options.oneofs)
                object.payload = "log";
        }
        if (message.otaStatus != null && message.hasOwnProperty("otaStatus")) {
            object.otaStatus = $root.OtaStatus.toObject(message.otaStatus, options);
            if (options.oneofs)
                object.payload = "otaStatus";
        }
        if (message.commandResult != null && message.hasOwnProperty("commandResult")) {
            object.commandResult = $root.UiCommandResult.toObject(message.commandResult, options);
            if (options.oneofs)
                object.payload = "commandResult";
        }
        if (message.analogDiagnosticResult != null && message.hasOwnProperty("analogDiagnosticResult")) {
            object.analogDiagnosticResult = $root.AnalogDiagnosticResult.toObject(message.analogDiagnosticResult, options);
            if (options.oneofs)
                object.payload = "analogDiagnosticResult";
        }
        if (message.analogConfigTestResult != null && message.hasOwnProperty("analogConfigTestResult")) {
            object.analogConfigTestResult = $root.AnalogConfigTestResult.toObject(message.analogConfigTestResult, options);
            if (options.oneofs)
                object.payload = "analogConfigTestResult";
        }
        return object;
    };

    /**
     * Converts this BlePacket to JSON.
     * @function toJSON
     * @memberof BlePacket
     * @instance
     * @returns {Object.<string,*>} JSON object
     */
    BlePacket.prototype.toJSON = function toJSON() {
        return this.constructor.toObject(this, $protobuf.util.toJSONOptions);
    };

    /**
     * Gets the default type url for BlePacket
     * @function getTypeUrl
     * @memberof BlePacket
     * @static
     * @param {string} [typeUrlPrefix] your custom typeUrlPrefix(default "type.googleapis.com")
     * @returns {string} The default type url
     */
    BlePacket.getTypeUrl = function getTypeUrl(typeUrlPrefix) {
        if (typeUrlPrefix === undefined) {
            typeUrlPrefix = "type.googleapis.com";
        }
        return typeUrlPrefix + "/BlePacket";
    };

    return BlePacket;
})();

export { $root as default };
