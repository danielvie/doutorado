function print(self)
    fprintf('ESP32 connection:\n\n');
    fprintf('name: %s\n', self.name);
    fprintf('service_uuid: %s\n', self.service_uuid);
    fprintf('characteristic_uuid: %s\n', self.characteristic_uuid);
    fprintf('\n');
end