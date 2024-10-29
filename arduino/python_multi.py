import threading
import time

test = 'dfasdfasdf'

# a simple function to be run by threads
def task(name, delay, repeat):
    for i in range(repeat):
        time.sleep(delay)
        print(f"task {name}: {i + 1}")
    
# create threads
thread1 = threading.Thread(target=task, args=("A", 1, 5))
thread2 = threading.Thread(target=task, args=("B", 2, 3))

# start threads
thread1.start()
thread2.start()

# wait for all threads to complete
thread1.join()
thread2.join()

print("all threads finished")