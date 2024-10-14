import socket
from time import sleep

# Get-PnpDevice -Class Bluetooth | Select-Object -Property FriendlyName, InstanceId
target = "1C:69:20:31:FE:62"
port = 1
server = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)

def loop():
    ADDR = ['D4', 'D5', 'D6']
    for _ in range(20):
        for d in ADDR:
            # Send data to ESP32
            print(f'send command to {d}')
            server.send(d.encode('utf-8'));
            
            # Read data from ESP32
            sleep(0.001);
    
    server.send(b'0');

def prompt():
    command = ''
    while command != '0':
        command = input("> ").strip()
        if 'd' in command:
            print('send D4')
            server.send(b'D4')
        elif 'f' in command:
            print('send D5')
            server.send(b'D5')
        elif 'g' in command:
            print('send D6')
            server.send(b'D6')
    server.send(b'0')

def main():
    try:
        server.connect((target, port))
        print(f'connected to {target}')
        
        # send data to device
        # loop()
        prompt()
        # server.send(b'D5')
        # print("data sent: 'D4")
    finally:
        server.close()
        print('connection closed')


if __name__ == '__main__':
    main()
