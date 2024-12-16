% write a matlab script

clear all;
clc;
close all;

ledPin = 'D13';
time_sec = 0.2;

% use the matlab support package for arduino
port = "COM6";
board = 'Nano33IoT';

a = arduino(port, board);

% write a small for loop 
for k = 1:10
  a.writeDigitalPin(ledPin, 0);
  pause(time_sec);

  a.writeDigitalPin(ledPin, 1);
  pause(time_sec);
end