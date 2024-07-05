% Define the COM port and baud rate
comPort = '/dev/cu.usbmodem2101'; % Replace with your Arduino's COM port
baudRate = 9600;

% Create a serial object
arduinoSerial = serialport(comPort, baudRate);

% Open the serial connection
fopen(arduinoSerial);

% Example usage: Change the delay interval to 500 ms
changeDelayInterval(arduinoSerial, 100);

% Close the serial connection
clear arduinoSerial;

% Function to change the delay interval
function changeDelayInterval(serialObj, interval)
    % Convert the interval to a string and send it over serial
    fprintf(serialObj, '%d', interval);
end