function message_cmd_signal(self, time_us, mode)
    
    command = Utils.signal_create(time_us, ...
                                    mode);
    
    self.message(command);
end