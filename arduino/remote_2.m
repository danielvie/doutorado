
comPort = "COM5"; % Replace with your Arduino's COM port
baudRate = 9600;

o = Com(comPort, baudRate);

% o = Com("COM5", 9600);

% o.listenSerial();