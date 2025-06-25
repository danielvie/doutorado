function msg_handle_event(self, src, ~)
    message = char(read(src));
    
    if self.verbose
        disp(['Received message: ', message]);
    end
    
    self.msg_handle_process(message);
end