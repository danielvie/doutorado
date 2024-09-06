
comPort = "COM11"; % Replace with your Arduino's COM port
baudRate = 115200;

% ref:  
N = 2000;
ref = "";
for i = 1:N
    ref = ref + num2str(i*1000) + ",";
end
ref = regexprep(ref, ",$", ";");

for i = 1:N
    ref = ref + num2str(i) + ",";
end
ref = regexprep(ref, ",$", ";");

disp(ref);
fprintf("(nro de elementos: %d)\n", strlength(ref));
fprintf("\n");

if ~exist('o', 'var')
    o = Com(comPort, baudRate);
    mode = 0;
end

%msg = join(repmat("a", 1,100), "");
% disp(msg);

%o.send(ref);
%o.send("100");

% o.sendModes( ...
%     [0, 100, 500, 1000, 2000, 3000, 6000, 40000], ...
%     [1,   0,   1,    0,    1,    0,    1,     0]);

o.listen();