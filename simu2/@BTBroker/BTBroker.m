classdef BTBroker < handle
    properties
        name;
        service_uuid;
        characteristic_uuid;
        device;
        chart_list;
        simulation;
    end
    
    methods
        % .. constructor
        function self = BTBroker(name, service_uuid, characteristic_uuid)
            self.name = name;
            self.service_uuid = service_uuid;
            self.characteristic_uuid = characteristic_uuid;
            
            % prepare connection
            self.connect();
            self.subscribe();
            
            % prepare model
        end
        
        print(self);
        
        connect(self);
        disconnect(self);
        res = is_connected(self);
        message(self, msg);
        subscribe(self);
        unsubscribe(self);
        
        message_handle_event(self, src, event);
        message_handle_process(self, msg);

        message_cmd_start(self);
        message_cmd_stop(self);
        message_cmd_cycles_nrun(self, value);
        message_cmd_signal(self, time_ms, mode);
        
        set_simulation(self);
    end
end