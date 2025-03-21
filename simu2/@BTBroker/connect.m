function connect(self)
    self.device = ble(self.name);
    self.chart_list = characteristic(self.device, self.service_uuid, self.characteristic_uuid);
    
    fprintf("connected!\n");
end