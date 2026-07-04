function msg(self, msg)
    
    % formated message
    if isstring(msg) == false
        fmt_msg = uint8(msg); 
    else
        fmt_msg = uint8(msg.char); 
    end

    if self.is_connected() == false
        fprintf("device is NOT connected!!\n");
        return;
    end

    % send message
    write(self.chart_list, uint8(fmt_msg));
    
    if self.verbose
        fprintf("command:= %s\n", msg);
    end
end