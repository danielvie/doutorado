import random
import socket
import threading
from time import perf_counter, sleep
import msvcrt
import statistics

# Get-PnpDevice -Class Bluetooth | Select-Object -Property FriendlyName, InstanceId
target = "1C:69:20:31:FE:62"
port = 1
server = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_RFCOMM)

start_time = perf_counter()
time_list = []

def prompt():
    global start_time
    key = ''
    while key != 'q':
        # command = input("> ").strip()
        key = msvcrt.getch().decode('utf-8')
        if key == 'd':
            # print('send D4')
            server.send(b'D4')
            start_time = perf_counter()
        elif key == 'f':
            # print('send D5')
            server.send(b'D5')
            start_time = perf_counter()
        elif key == 'g':
            # print('send D6')
            server.send(b'D6')
            start_time = perf_counter()
        elif key == 'b':
            # print('send D6')
            server.send(b'0')
            start_time = perf_counter()

def random_messages():
    global start_time
    keys = ['D4', 'D5', 'D6']
    
    for i in range(1000):
        print(f'{i:04d} of 1000')
        key = random.choice(keys)
        
        server.send(key.encode('utf-8'))
        start_time = perf_counter()
        sleep(0.1)
    
    # stats()
    
def stats():
    print('='*30)
    print('STATS:')
    print(f'max: {max(time_list):0.5f} sec')
    print(f'min: {min(time_list):0.5f} sec')
    print('')
    print(f'mean: {statistics.mean(time_list):0.5f} sec')
    print(f'dev : {statistics.stdev(time_list):0.5f} sec')

def listen():
    global start_time
    global time_list
    try:
        while True:
            data = server.recv(1024)
            if data:
                now = perf_counter()
                elapsed_time = now - start_time
                print('==============================')
                print(f'my time: {elapsed_time:.7f} seconds')
                incoming = data.decode("utf-8")
                print(incoming)
                time_list.append(elapsed_time)
            else:
                break
    except Exception as e:
        print(f"error in receiving data: {e}")

def main():
    global time_list
    try:
        server.connect((target, port))
        print(f'connected to {target}')
        
        # start listening thread
        listen_thread = threading.Thread(target=listen, daemon=True)
        listen_thread.start()
        
        # run prompt function
        prompt()
        # random_messages()
    finally:
        server.send(b'0')
        server.close()
        print('connection closed')
        
        stats()
        # print(f'max: {max(time_list)}')
        # print(f'min: {min(time_list)}')

        # for t in time_list:
        #     print(t)

        # print('')
        # print(f'max: {max(time_list)}')
        # print(f'min: {min(time_list)}')
        # print('')
        # print(f'mean: {statistics.mean(time_list)}')
        # print(f'dev : {statistics.stdev(time_list)}')

if __name__ == '__main__':
    main()
