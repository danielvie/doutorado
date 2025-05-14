classdef BTBroker < handle
    properties
        name;
        service_uuid;
        characteristic_uuid;
        device;
        chart_list;
        simulation;
        verbose;
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
            
            % prepare flags
            self.verbose = false;
        end
        
        print(self);
        
        res = is_connected(self);
        
        % .. config
        connect(self);
        disconnect(self);
        subscribe(self);
        unsubscribe(self);

        % .. message commands
        message(self, msg);
        message_cmd_start(self);
        message_cmd_stop(self);
        message_cmd_cycles_nrun(self, value);
        message_cmd_signal(self, time_us, mode);
        
        % .. message handlers
        message_handle_event(self, src, event);
        message_handle_process(self, msg);

        % .. setters
        set_verbose(self, value);
        set_simulation(self);

        % .. automation
        start(self); % self.message("START");
        stop(self); % self.message("STOP");

        % .. aliases
        s(self, alpha); % self.simulation.set_alpha_and_mpc_cached(alpha)
        sa(self, alpha); % self.start()
        so(self, alpha); % self.stop()
        x(self); % self.stop()
        
    end
end