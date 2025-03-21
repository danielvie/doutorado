classdef BTBroker < handle
    properties
        name;
        service_uuid;
        characteristic_uuid;
        device;
        chart_list;
    end
    
    methods
        % .. constructor
        function self = BTBroker(name, service_uuid, characteristic_uuid)
            self.name = name;
            self.service_uuid = service_uuid;
            self.characteristic_uuid = characteristic_uuid;
            
            self.connect();
            self.subscribe();
        end
        
        print(self);
        
        connect(self);
        disconnect(self);
        res = is_connected(self);
        message(self, msg);
        subscribe(self);
        unsubscribe(self);
        
        message_handle_event(self, src, event);
        message_process(self, msg);

    end
end