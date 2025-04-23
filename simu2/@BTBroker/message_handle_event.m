function message_handle_event(self, src, ~)
    message = char(read(src));
    
    if self.verbose
        disp(['Received message: ', message]);
    end
    
    self.message_handle_process(message);
end