import asyncio
import platform
from bleak import BleakClient, BleakScanner

SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

async def find_esp32():
    print("Scanning for ESP32 Signal Controller...")
    
    # macOS specific scanner configuration
    if platform.system() == 'Darwin':  # Darwin is macOS
        scanner = BleakScanner(adapter='BluetoothAdapter')
        # Scan with extended timeout and additional parameters for macOS
        devices = await scanner.discover(timeout=10.0, return_adv=True)
        print("\nDiscovered devices:")
        for device, adv_data in devices.values():
            print(f"Name: {device.name}, Address: {device.address}")
        
        for device, adv_data in devices.values():
            if device.name and "ESP32" in device.name:
                return device.address
    else:
        # Original Windows code
        devices = await BleakScanner.discover()
        for device in devices:
            if device.name and "ESP32 Signal Controller" in device.name:
                return device.address
    
    return None

async def send_command(client, command) -> bool:
    # Add retry logic and longer timeout for macOS
    try:
        # Convert string to bytes
        command_bytes = command.encode()
        
        # Send command
        await client.write_gatt_char(CHARACTERISTIC_UUID, command_bytes)
        print(f"Sent command: {command}")
    except Exception as e:
        print(f"Error during connection/communication: {str(e)}")
        return False
    return True

async def main():
    # Find ESP32
    esp32_address = await find_esp32()
    
    if not esp32_address:
        print("ESP32 device not found!")
        return
    
    try:
        # establish a persistent connection
        async with BleakClient(esp32_address, timeout=20.0) as client:
            while True:
                print("\nCommands:")
                print("a. Start signals")
                print("s. LOW")
                print("d. HIGH")
                print("q. Exit")
                
                choice = input("Enter choice (a,s,d,q): ")
                
                if choice == "a":
                    await send_command(client, "START")
                elif choice == "s":
                    await send_command(client, "STOP")
                elif choice == "d":
                    await send_command(client, "HIGH")
                elif choice == "q":
                    print("Exiting...")
                    break
                else:
                    print("Invalid choice!")
    except Exception as e:
        print(f"Connection error: {str(e)}")

if __name__ == "__main__":
    # Install required package: pip install bleak
    asyncio.run(main())