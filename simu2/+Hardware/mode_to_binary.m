function [b1, b2, b3] = mode_to_binary(Omega)
    % mode_to_binary - Convert mode sequence to binary switch states.
    %
    % Inputs:
    %   Omega - Mode index sequence (1-indexed, MATLAB convention)
    %
    % Outputs:
    %   b1, b2, b3 - Binary state of each switching cell

    mode = Omega - 1;  % convert to 0-indexed

    len = numel(mode);
    b1  = zeros(1, len);
    b2  = zeros(1, len);
    b3  = zeros(1, len);

    for i = 1:len
        bin = dec2bin(mode(i), 3);
        b1(i) = str2double(bin(1));
        b2(i) = str2double(bin(2));
        b3(i) = str2double(bin(3));
    end
end
