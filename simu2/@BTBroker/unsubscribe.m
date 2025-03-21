function unsubscribe(self)

    % unsubscribing with ESP32
    unsubscribe(self.chart_list);
    self.chart_list.DataAvailableFcn = [];
end