% const SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
% const CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

% use `blelist` to list the bluetooth devices

SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

name = "ESP32 Signal Controller";

device = ble(name);

%%
charList = characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID);

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('SIGNAL:50,30;7,0'));

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('STOP'));

%%
write(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID), uint8('START'));

%%
data = read(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID))

%%
while true
    value = char(read(characteristic(device, SERVICE_UUID, CHARACTERISTIC_UUID)));
    disp(value);
    pause(0.1);
end
