import asyncio
from bleak import BleakClient, BleakScanner

# UUIDs (must match the ones in ESP32 code)
SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8"

async def find_esp32():
    print("Scanning for ESP32 Signal Controller...")
    devices = await BleakScanner.discover()
    for device in devices:
        if device.name and "ESP32 Signal Controller" in device.name:
            return device.address
    return None

async def send_command(address, command):
    async with BleakClient(address) as client:
        print(f"Connected to ESP32: {address}")
        
        # Convert string to bytes
        command_bytes = command.encode()
        
        # Send command
        await client.write_gatt_char(CHARACTERISTIC_UUID, command_bytes)
        print(f"Sent command: {command}")

async def main():
    # Find ESP32
    esp32_address = await find_esp32()
    
    if not esp32_address:
        print("ESP32 device not found!")
        return
    
    while True:
        print("\nCommands:")
        print("1. Start signals")
        print("2. Stop signals")
        print("3. Exit")
        
        choice = input("Enter choice (1-3): ")
        
        if choice == "1":
            await send_command(esp32_address, "START")
        elif choice == "2":
            await send_command(esp32_address, "STOP")
        elif choice == "3":
            print("Exiting...")
            break
        else:
            print("Invalid choice!")

if __name__ == "__main__":
    # Install required package: pip install bleak
    asyncio.run(main())