import asyncio
from bleak import BleakClient, BleakScanner
import sys

# UUID definitions (must match ESP32)
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
CHAR_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

async def main():
    try:
        # Scan for BLE devices
        print("Scanning for ESP32_BLINK...")
        device = await BleakScanner.find_device_by_name("ESP32_BLINK")
        
        if device is None:
            print("Could not find ESP32_BLINK device!")
            return

        async with BleakClient(device) as client:
            print("Connected to ESP32!")
            print("Available commands:")
            print('1. Type "START" to begin LED blinking')
            print('2. Type "STOP" to stop LED blinking')
            print('3. Type "INTERVAL" followed by milliseconds (e.g., "INTERVAL 1000")')
            print('4. Type "EXIT" to quit\n')

            while True:
                # Get command from user
                cmd = input("Enter command: ").upper()

                # Process command
                if cmd.startswith("INTERVAL"):
                    # Parse interval command
                    parts = cmd.split()
                    if len(parts) == 2:
                        try:
                            interval = int(parts[1])
                            if interval > 0:
                                await client.write_gatt_char(CHAR_UUID, f"INTERVAL:{interval}".encode('ascii'))
                                print(f"Set blink interval to {interval} ms")
                            else:
                                print("Invalid interval value!")
                        except ValueError:
                            print("Invalid interval value!")
                    else:
                        print('Invalid command format! Use "INTERVAL 1000"')
                
                else:
                    if cmd == "START":
                        await client.write_gatt_char(CHAR_UUID, b"START")
                        print("Started LED blinking")
                    
                    elif cmd == "STOP":
                        await client.write_gatt_char(CHAR_UUID, b"STOP")
                        print("Stopped LED blinking")
                    
                    elif cmd == "EXIT":
                        print("Disconnecting...")
                        break
                    
                    else:
                        print("Invalid command!")

    except Exception as e:
        print(f"Error: {str(e)}")

    print("Program ended")

if __name__ == "__main__":
    # Run the async main function
    asyncio.run(main())