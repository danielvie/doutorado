// Copyright 2025 ITA (Instituto Tecnologico de Aeronautica). Licensed under the MIT license.
//
// UUID for the ESP32 BLE service
const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

// UUID for the characteristic used for data communication
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

// Module-level variables to maintain the Bluetooth connection state
let g_bluetooth_device: any = null; // Reference to the connected Bluetooth device
let g_gattServer = null; // The GATT server of the connected device
let g_characteristic: any = null; // The characteristic used for communication
let g_paired_device: any = null; // Stores the device reference after first successful pairing

// Function reference for status updates to the UI
let g_fn_update_status: any = null; // Will be set to a callback function from the UI component
// let g_fn_ble_status: any = null; // Will be set to a callback function from the UI component
let g_fn_set_app_status_message: any = null; // Will be set to a callback function from the UI component
let g_fn_probe: any = null;

// Attempts to reconnect to a previously paired device
async function ble_reconnect_to_paired_device() {
    if (!g_paired_device) {
        return false; // No paired device available
    }

    try {
        ble_update_status("Attempting to reconnect to paired device...");
        
        // Use the stored device reference to reconnect
        g_bluetooth_device = g_paired_device;
        
        // Connect to the device's GATT server
        g_gattServer = await g_bluetooth_device.gatt.connect();

        // Get the service we're interested in
        const service = await g_gattServer.getPrimaryService(SERVICE_UUID);

        // Get the characteristic we'll use for reading/writing data
        g_characteristic = await service.getCharacteristic(CHARACTERISTIC_UUID);

        // Update UI with connection status
        ble_update_status("Reconnected to ESP32");
        
        // Automatically start listening for notifications when connected
        if (g_fn_probe) {
            await ble_start_notifications();
        }
        
        return true; // Success
    } catch (error: any) {
        ble_update_status(`Reconnection failed: ${error.message}`, true);
        ble_reset_connection();
        return false; // Failed
    }
}

// Initiates a Bluetooth connection to an ESP32 device
export async function ble_connect_device() {
    try {
        // Access the Web Bluetooth API through navigator
        let navigator_object: any = window.navigator;

        // Open the device picker dialog, filtering for our specific service
        g_bluetooth_device = await navigator_object.bluetooth.requestDevice({
            // acceptAllDevices: true,
            // optionalServices: [SERVICE_UUID]
            filters: [{ services: [SERVICE_UUID] }],
        });

        // Store the device reference for future automatic reconnections
        g_paired_device = g_bluetooth_device;

        // Set up a disconnect handler
        g_bluetooth_device.addEventListener(
            "gattserverdisconnected",
            ble_handle_disconnect,
        );

        // Connect to the device's GATT server
        g_gattServer = await g_bluetooth_device.gatt.connect();

        // Get the service we're interested in
        const service = await g_gattServer.getPrimaryService(SERVICE_UUID);

        // Get the characteristic we'll use for reading/writing data
        g_characteristic = await service.getCharacteristic(CHARACTERISTIC_UUID);

        // Update UI with connection status
        ble_update_status("Connected to ESP32");
        
        // Automatically start listening for notifications when connected
        if (g_fn_probe) {
            await ble_start_notifications();
        }
    } catch (error: any) {
        // Handle any errors during the connection process
        ble_update_status(`Connection failed: ${error.message}`, true);
        ble_reset_connection();
    }
}

// Manually disconnects from the currently connected ESP32 device
export async function ble_disconnect_device() {
    if (g_bluetooth_device && g_bluetooth_device.gatt.connected) {
        await g_bluetooth_device.gatt.disconnect();
    }
    ble_reset_connection();
    ble_update_status("Manually disconnected");
}

// Clears the paired device reference (forces dialog on next connection)
export function ble_clear_paired_device() {
    g_paired_device = null;
    ble_update_status("Paired device reference cleared");
}

// Event handler for when the device disconnects
function ble_handle_disconnect() {
    ble_update_status("Disconnected from ESP32", true);
    ble_reset_connection();
}

// Resets all connection-related variables to their initial state
function ble_reset_connection() {
    g_bluetooth_device = null;
    g_gattServer = null;
    g_characteristic = null;
    // Note: We keep g_paired_device for automatic reconnection unless manually cleared
}

// Sets the callback function used to update the UI with status messages
export function ble_set_update_status(update_status_fun: CallableFunction) {
    g_fn_update_status = update_status_fun;
}

export function ble_app_set_status_msg(set_status_msg: CallableFunction) {
    g_fn_set_app_status_message = set_status_msg;
}

// Updates the UI with a status message
function ble_update_status(message: string, _isError: boolean = false) {
    if (g_fn_update_status) {
        g_fn_update_status(message, _isError);
    }
}

// Sends a command to the ESP32 device via Bluetooth
export async function ble_send_command(command: string) {
    // Check if we're connected, try to reconnect if not
    if (!ble_is_connected()) {
        ble_update_status("Not connected, attempting to reconnect...", true);
        
        // First try to reconnect to a previously paired device
        const reconnectSuccess = await ble_reconnect_to_paired_device();
        
        // If automatic reconnection failed, show the device picker dialog
        if (!reconnectSuccess) {
            ble_update_status("Automatic reconnection failed, please select device...");
            await ble_connect_device();
        }
        
        if (!ble_is_connected()) {
            ble_update_status(`Failed to reconnect, cannot send command:'${command}'`, true);
            return;
        }
    }

    console.log(`command: ${command}`)

    // Normalize the command (trim whitespace and convert to uppercase)
    const comm = command.trim().toUpperCase();
    if (!comm) {
        ble_update_status("Please enter a command", true);
        return;
    }

    try {
        // Convert the string to bytes using TextEncoder
        const encoder = new TextEncoder();
        const data = encoder.encode(comm);

        // Send the data to the device via the Bluetooth characteristic
        await g_characteristic.writeValue(data);
        ble_update_status(`Sent command: ${comm}`);
    } catch (error: any) {
        // Handle any errors during sending
        ble_update_status(`Send failed: ${error.message}`, true);
        ble_reset_connection();
    }
}

// Checks if a Bluetooth connection is currently established
export function ble_is_connected() {
    return g_bluetooth_device && g_bluetooth_device.gatt && g_bluetooth_device.gatt.connected;
}

export function ble_set_fn_probe(fn_probe: CallableFunction) {
    g_fn_probe = fn_probe;
}

// Starts listening for notifications from the BLE device
export async function ble_start_notifications() {
    if (!g_characteristic) {
        ble_update_status("No characteristic available", true);
        return;
    }

    try {
        // Enable notifications for our characteristic
        await g_characteristic.startNotifications();

        // Add an event listener for incoming notifications
        g_characteristic.addEventListener(
            "characteristicvaluechanged",
            (event: any) => {
                // Get the raw data from the event
                const value = event.target.value;

                // Convert the binary data to text
                const decoder = new TextDecoder();
                let message = decoder.decode(value);
                
                if (message.includes('LOG') || message.includes('STATUS')) {
                    console.log(message)
                    g_fn_set_app_status_message(message);
                    return;
                }

                // Parse the message using regex to extract key:value pairs
                // Expected format is like "an3:1.23 an5:4.56 an6:7.89"
                const regex = /(\w+):([\d.]+)/g;
                const parsed_data: Record<string, string> = {};
                // console.log(parsed_data)
                let match;
                let has_match = false;


                // Extract all key-value pairs from the message
                while ((match = regex.exec(message)) !== null) {
                    has_match = true;
                    const key = match[1];
                    const value = match[2];
                    parsed_data[key] = value;
                }

                // If we found at least one key-value pair, create the result object
                if (has_match) {
                    const results = {
                        an3: parsed_data["an3"] || "0", // Default to "0" if not present
                        an5: parsed_data["an5"] || "0",
                        an6: parsed_data["an6"] || "0",
                    };
                    g_fn_probe(results); // Call the probe callback with new data
                }
            },
        );
        ble_update_status("Started listening for notifications");
    } catch (err: any) {
        ble_update_status(`Failed to start notifications: ${err.message}`, true);
    }
}