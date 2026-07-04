function subscribe(self)
    % subscribing with ESP32
    subscribe(self.chart_list);
    
    self.chart_list.DataAvailableFcn = @(src, event) self.msg_handle_event(src, event);
end