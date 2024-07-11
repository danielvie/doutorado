% clear previous connection
clear arduinoSerial;

% Define the COM port and baud rate
comPort = 'COM5'; % Replace with your Arduino's COM port
baudRate = 9600;

% Create a serial object
arduinoSerial = serialport(comPort, baudRate);

% Open the serial connection
fopen(arduinoSerial);


% send two vectors to the arduino
timeVector = [100, 200, 300, 400];
intVector = [1, 2, 3, 4];
sendVectors(arduinoSerial, timeVector, intVector);


% Example usage: Change the delay interval to 500 ms
% changeDelayInterval(arduinoSerial, 5000);

% Continuously read and display the analog value from the Arduino
listenSerial(arduinoSerial, 0.1);

% Close the serial connection
clear arduinoSerial;

% Function to change the delay interval
function changeDelayInterval(serialObj, interval)
    % Convert the interval to a string and send it over serial
    writeline(serialObj, num2str(interval));
end

function listenSerial(arduinoSerial, period_sec)
    disp('Reading analog values from Arduino:');
    while true
        if arduinoSerial.NumBytesAvailable > 0
            analogValue = readline(arduinoSerial);
            fprintf('Analog Value: %s\n', analogValue);
        end
        pause(period_sec); % Small delay to prevent overwhelming the serial port
    end
end

function sendVectors(serialObj, timeVector, intVector)
    % convert the vectors to comma-separated strings
    % 100,200,300,400;1,2,3,4
    timeStr = strjoin(string(timeVector), ",");
    intStr = strjoin(string(intVector), ",");

    % concatenate the strings with a semicolon separator
    dataStr = strcat(timeStr, ";", intStr);

    % send string
    writeline(serialObj, dataStr);
end
