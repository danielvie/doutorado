function set_signal(self, time_us, mode)
    
    command = Utils.signal_create(time_us, ...
                                    mode);
    
    self.msg(command);
    fprintf("command:= %s", command);
end