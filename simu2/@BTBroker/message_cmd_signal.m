function message_cmd_signal(self, time_ms, mode)
    
    command = Helpers.signal_create(time_ms, ...
                                    mode);
    
    self.message(command);
end