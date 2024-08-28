
comPort = "COM10"; % Replace with your Arduino's COM port
baudRate = 9600;

if ~exist('o', 'var')
    o = Com(comPort, baudRate);
    mode = 0;
end

% o = Com("COM5", 9600);

% o.listenSerial();

mode = 1;
disp("mode");
disp(mode);

if mode == 0
    o.sendModes([0, 3000, 5000, 6000, 7000, 9000, 10000], [0, 1, 0, 1, 0, 1, 0]); 
    mode = 1;
elseif mode == 1 
    N = 100;
    time = -ones(1, N);
    mode = -ones(1, N);

    for i = 1:N
        time(i) = 100*i;
        mode(i) = mod(i,2);
    end

    o.sendModes(time, mode); 
    mode = 2;
elseif mode == 2
    o.sendModes([0, 5000], [0, 1]); 
    mode = 3;
else
    o.sendModes([0, 5000], [1, 1]); 
    mode = 0;
end

o.listen();