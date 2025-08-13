classdef BTBroker < handle
    properties
        name;
        service_uuid;
        characteristic_uuid;
        device;
        chart_list;
        simulation;
        verbose;
        control_on;
    end
    
    methods (Static)
        [name, service_uuid, characteristic_uuid] = get_default_config();
    end
    
    methods
        % .. constructor
        function self = BTBroker(name, service_uuid, characteristic_uuid)
            
            if nargin == 0
                [name, service_uuid, characteristic_uuid] = self.get_default_config();
            end
            
            self.name = name;
            self.service_uuid = service_uuid;
            self.characteristic_uuid = characteristic_uuid;
            self.control_on = true;
            
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
        msg(self, msg);
        msg_start(self);
        msg_stop(self);
        
        % .. message handlers
        msg_handle_event(self, src, event);
        msg_handle_process(self, msg);

        % .. setters
        set_cycles_nrun(self, value);
        set_signal(self, time_us, mode);
        set_simulation(self);
        set_verbose(self, value);
        set_control_on(self);
        set_control_off(self);

        % alias
        set_verbose_on(self);
        set_verbose_off(self);

        % .. getters
        get_signal(self);
        get_status(self);
        get_last_calc(self, n_chunk);

        % .. automation
        start(self); % self.msg("START");
        stop(self); % self.msg("STOP");

        % .. aliases
        s(self, alpha); % self.simulation.set_alpha_and_mpc_cached(alpha)
        ss(self, alpha); % set simulation with complete message from alpha
        sa(self, alpha); % self.start()
        so(self, alpha); % self.stop()
        x(self); % self.stop()
        st(self); % self.get_status()
        
        v_on(self); % self.verbose_on
        v_off(self); % self.verbose_off

        tg_a(self); % toggle set A
        tg_b(self); % toggle set B
        
        last(self, n_chunk); % self.get_last_calc
        
    end
end