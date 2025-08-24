/**
 * UUID for the ESP32 BLE service
 * This is a custom UUID that must match the one configured in the ESP32 firmware
 */
const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";

/**
 * UUID for the characteristic used for data communication
 * This is a custom UUID that must match the one configured in the ESP32 firmware
 */
const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

// Module-level variables to maintain the Bluetooth connection state
let g_bluetoothDevice: any = null; // Reference to the connected Bluetooth device
let g_gattServer = null; // The GATT server of the connected device
let g_characteristic: any = null; // The characteristic used for communication

// Function reference for status updates to the UI
let g_fn_UpdateStatus: any = null; // Will be set to a callback function from the UI component
let g_is_listening = false; // Flag to track if we're currently listening for notifications

/**
 * Initiates a Bluetooth connection to an ESP32 device
 *
 * This function triggers the browser's Bluetooth device picker and establishes
 * a connection with the ESP32 device that advertises our service UUID.
 * Once connected, it sets up event listeners and gets the GATT characteristic
 * used for communication.
 *
 * @returns {Promise<void>} A promise that resolves when connection is established
 */
export async function ble_connect_device() {
    try {
        // Access the Web Bluetooth API through navigator
        let navigatorObject: any = window.navigator;

        // Open the device picker dialog, filtering for our specific service
        g_bluetoothDevice = await navigatorObject.bluetooth.requestDevice({
            filters: [{ services: [SERVICE_UUID] }],
        });

        // Set up a disconnect handler
        g_bluetoothDevice.addEventListener(
            "gattserverdisconnected",
            ble_handle_disconnect,
        );

        // Connect to the device's GATT server
        g_gattServer = await g_bluetoothDevice.gatt.connect();

        // Get the service we're interested in
        const service = await g_gattServer.getPrimaryService(SERVICE_UUID);

        // Get the characteristic we'll use for reading/writing data
        g_characteristic = await service.getCharacteristic(CHARACTERISTIC_UUID);

        // Update UI with connection status
        ble_update_status("Connected to ESP32");
    } catch (error: any) {
        // Handle any errors during the connection process
        ble_update_status(`Connection failed: ${error.message}`, true);
        ble_reset_connection();
    }
}

/**
 * Manually disconnects from the currently connected ESP32 device
 *
 * @returns {Promise<void>} A promise that resolves when disconnection is complete
 */
export async function ble_disconnect_device() {
    if (g_bluetoothDevice && g_bluetoothDevice.gatt.connected) {
        await g_bluetoothDevice.gatt.disconnect();
    }
    ble_reset_connection();
    ble_update_status("Manually disconnected");
}

/**
 * Event handler for when the device disconnects
 * This will be called automatically when the device disconnects unexpectedly
 */
function ble_handle_disconnect() {
    ble_update_status("Disconnected from ESP32", true);
    ble_reset_connection();
}

/**
 * Resets all connection-related variables to their initial state
 * Called after a disconnect (manual or automatic)
 */
function ble_reset_connection() {
    g_bluetoothDevice = null;
    g_gattServer = null;
    g_characteristic = null;
    g_is_listening = false; // Reset listening state on disconnect
}

/**
 * Sets the callback function used to update the UI with status messages
 * This should be called by the UI component that displays status messages
 *
 * @param update_status_fun - Function that accepts a message string and error flag
 */
export function ble_set_update_status(update_status_fun: CallableFunction) {
    g_fn_UpdateStatus = update_status_fun;
}

/**
 * Updates the UI with a status message
 *
 * @param message - The status message to display
 * @param _isError - Whether this is an error message (for styling)
 */
function ble_update_status(message: string, _isError: boolean = false) {
    if (g_fn_UpdateStatus) {
        g_fn_UpdateStatus(message, _isError);
    }
}

/**
 * Sends a command to the ESP32 device via Bluetooth
 *
 * Will attempt to reconnect if the device is currently disconnected.
 * Commands are automatically trimmed and converted to uppercase.
 *
 * @param command - The command string to send to the device
 * @returns {Promise<void>} A promise that resolves when the command is sent
 */
export async function ble_send_command(command: string) {
    // Check if we're connected, try to reconnect if not
    if (!ble_is_connected()) {
        ble_update_status("Not connected, attempting to reconnect...", true);
        await ble_connect_device();
        if (!ble_is_connected()) {
            ble_update_status(
                `Failed to reconnect, cannot send command: '${command}'`,
                true,
            );
            return;
        }
    }

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

/**
 * Checks if a Bluetooth connection is currently established
 *
 * @returns {boolean} True if connected, false otherwise
 */
export function ble_is_connected() {
    return g_bluetoothDevice && g_bluetoothDevice.gatt.connected;
}

/**
 * Toggles the notification listening state
 *
 * When enabled, the device will send notification data that will be
 * processed and sent to the provided callback function.
 *
 * @param fn_probe - Callback function that will receive the parsed sensor data
 * @returns {boolean} The new listening state (true = listening, false = not listening)
 */
export function ble_toggle_listening(fn_probe: CallableFunction): boolean {
    // Can't listen if not connected
    if (!ble_is_connected()) {
        ble_update_status("Cannot toggle listening: not connected", true);
        return false;
    }

    // Toggle the state
    g_is_listening = !g_is_listening;

    // Start or stop notifications based on the new state
    if (g_is_listening) {
        ble_start_notifications(fn_probe);
    } else {
        ble_stop_notifications();
    }

    return g_is_listening;
}

/**
 * Starts listening for notifications from the BLE device
 *
 * This sets up an event listener for incoming data, parses it,
 * and passes the parsed sensor values to the provided callback.
 *
 * @param fn_probe - Callback function that will receive the parsed sensor data
 */
async function ble_start_notifications(fn_probe: CallableFunction) {
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
                    return;
                }

                // message = message.replace(/\ncontrol\:.*/g, "")
                // console.log(message)

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
                    fn_probe(results); // Call the probe callback with new data
                }
            },
        );
        ble_update_status("Started listening for notifications");
    } catch (err: any) {
        ble_update_status(`Failed to start notifications: ${err.message}`, true);
        g_is_listening = false;
    }
}

/**
 * Stops listening for notifications from the BLE device
 *
 * Note that this doesn't remove the event listener, just stops the notifications.
 * The listener will be re-triggered if notifications restart.
 */
async function ble_stop_notifications() {
    if (!g_characteristic) return;

    try {
        // Disable notifications from the characteristic
        await g_characteristic.stopNotifications();
        // Note: Event listener remains attached; it will be re-triggered if notifications restart
        ble_update_status("Stopped listening for notifications");
    } catch (err: any) {
        ble_update_status(`Failed to stop notifications: ${err.message}`, true);
    }
}
