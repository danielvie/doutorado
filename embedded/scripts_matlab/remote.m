
comPort = "COM5"; % Replace with your Arduino's COM port
baudRate = 9600;

main(comPort, baudRate);

function main(comPort, baudRate)
    % Create a serial object
    arduinoSerial = serialport(comPort, baudRate);

    % Example usage: Change the delay interval to 500 ms
    changeDelayInterval(arduinoSerial, 100);
end

% Function to change the delay interval
function changeDelayInterval(serialObj, interval)
    % Convert the interval to a string and send it over serial
    fprintf(serialObj, '%d', interval);
end
