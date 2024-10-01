% Set the ESP32 Bluetooth device name and channel (default is 1)
bt = bluetooth("ESP32_BT", 1);


for i = 1:5
    % Send data to ESP32
    msg = sprintf('Hello ESP32, this is a message from MATLAB!!!!! iataaaaaa!!! (%d)\n', i);
    write(bt, msg, 'string');
    
    % Read data from ESP32
    % data = read(bt, 20, 'string');  % Read 20 characters
    data = readline(bt); 
    disp(data);
    pause(0.5);
end





% Close the connection when done
clear bt;
