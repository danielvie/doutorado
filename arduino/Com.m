classdef Com
    properties
        port;
        baudrate;
        serial;
    end
    methods
        function o = Com(port, baudrate)
            o.port = port;
            o.baudrate = baudrate;
            
            serial = serialport(port, baudrate);
            o.serial = serial;
        end
        
        % function serial_obj = serial(o)
        %     serial_obj = serialport(o.port, o.baudrate);
        % end

        function setDelayInterval(o, interval)
            % Convert the interval to a string and send it over serial
            fprintf(o.serial, '%d', interval);
        end
        
        function listen(o)
            serial_ = o.serial;

            keepRunning = 1;
            while keepRunning
                % Check if there is data available to read
                if serial_.NumBytesAvailable > 0
                    analogValue = readline(serial_);
                    fprintf('serial msg: %s\n', analogValue);
                end
                pause(0.1); % Small delay to prevent overwhelming the serial port
            end
        end
        
        function toggleSerial(o)
            % Convert the interval to a string and send it over serial
            fprintf(o.serial, 'toggle');
        end
        
        function send(o, value)
            fprintf(o.serial, value);
        end
        
        function sendModes(o, time, mode)
            if nargin == 1
                time = [1, 2, 4];
                mode = [8, 9, 0];
            end

            % convert arrays to strings
            time_str = sprintf('%d,', time);
            mode_str = sprintf('%d,', mode);

            % concatenate strings
            result = strcat(time_str, ";", mode_str, ";");

            % remove trailing commas
            result = strrep(result, ",;", ";");
            
            fprintf("sending modes: ""%s""\n", result);
            o.send(result);
        end
    end
end