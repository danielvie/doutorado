% clear previous connection
clear arduinoSerial;

% Define the COM port and baud rate
comPort = 'COM5'; % Replace with your Arduino's COM port
baudRate = 9600;

% Create a serial object
arduinoSerial = serialport(comPort, baudRate);

% Open the serial connection
fopen(arduinoSerial);

% Example usage: Change the delay interval to 500 ms
changeDelayInterval(arduinoSerial, 5000);

% Continuously read and display the analog value from the Arduino
disp('Reading analog values from Arduino:');
while true
    if arduinoSerial.NumBytesAvailable > 0
        analogValue = readline(arduinoSerial);
        fprintf('Analog Value: %s\n', analogValue);
    end
    pause(0.1); % Small delay to prevent overwhelming the serial port
end

% Close the serial connection
clear arduinoSerial;

% Function to change the delay interval
function changeDelayInterval(serialObj, interval)
    % Convert the interval to a string and send it over serial
    writeline(serialObj, num2str(interval));
end