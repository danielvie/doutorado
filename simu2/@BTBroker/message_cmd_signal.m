function message_cmd_signal(self, time_us, mode)
    
    command = Helpers.signal_create(time_us, ...
                                    mode);
    
    self.message(command);
end