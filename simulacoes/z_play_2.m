
function z_play_2()
    % creating `sim` object

    modes = [1, 2, 1, 5, 1, 3];

    nmodes = numel(modes);
    di4 = zeros(1, nmodes);
    di5 = di4;
    di6 = di4;

    for i = 1:nmodes
        % read mode from omega
        m = modes(i);
        
        % convert value to bin
        bin = dec2bin(m, 3);
        
        % insert value into outputs
        di6(i) = str2double(bin(1));
        di5(i) = str2double(bin(2));
        di4(i) = str2double(bin(3));
    end

    disp(di6);
    disp(di5);
    disp(di4);
    
    % negate the values
    di6_ = 1-di6;
    di5_ = 1-di5;
    di4_ = 1-di4;

    disp('===================');
    disp(di6_);
    disp(di5_);
    disp(di4_);

    % constructing signal for esp32
    fprintf("const uint32_t modes_di6[] = {\n  ");
    for i = 1:nmodes
        fprintf("%d, ", di6_(i));
    end
    fprintf("\n};\n\n");

    % constructing signal for esp32
    fprintf("const uint32_t modes_di5[] = {\n  ");
    for i = 1:nmodes
        fprintf("%d, ", di5_(i));
    end
    fprintf("\n};\n\n");

    % constructing signal for esp32
    fprintf("const uint32_t modes_di4[] = {\n  ");
    for i = 1:nmodes
        fprintf("%d, ", di4_(i));
    end
    fprintf("\n};\n\n");

end
