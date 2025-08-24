function [b1, b2, b3, b4] = get_mode_bin(self)
    mode = self.m_config.Omega-1;
    
    len = numel(mode);
    b1  = zeros(1, len);
    b2  = zeros(1, len);
    b3  = zeros(1, len);
    b4  = zeros(1, len);

    for i = 1:len
        bin = dec2bin(mode(i), 4);
        b1(i) = str2double(bin(1));
        b2(i) = str2double(bin(2));
        b3(i) = str2double(bin(3));
        b4(i) = str2double(bin(4));
    end
end