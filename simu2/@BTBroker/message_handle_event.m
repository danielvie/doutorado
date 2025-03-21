function message_handle_event(self, src, ~)

    message = char(read(src));
    disp(['Received message: ', message]);
    
    self.message_handle_process(message);
end