function msg_handle_process(self, msg)

    if self.control_on == false 
        % Early return if there is no control
        return;
    end 

    persistent dtk_prev
    if isempty(dtk_prev)
        dtk_prev = zeros([numel(self.simulation.m_config.Omega)-1, 1]);
    end

    % parsing message
    tokens = regexp(msg, '(\w+):([\d.]+)', 'tokens');
    parsed_data = struct();
    for i = 1:length(tokens)
        key = tokens{i}{1};
        value = str2double(tokens{i}{2});
        parsed_data.(key) = value;
    end

    if ~isfield(parsed_data, 'an6')
        % if parse is not successfull, then return
        return
    end
    
    if self.verbose
        disp('Parsed data:');
        disp(parsed_data);
    end
    
    % v_c1 -> a5
    % v_c2 -> a6
    % v_i  -> a3

    v_c1 = parsed_data.an5;
    v_c2 = parsed_data.an6;
    i_l  = parsed_data.an3 / 22; % tensao / resistencia resistor
    
    % ajustando escala do divisor de tensao (* 10/6)
    v_c2 = v_c2*10/6;
    v_c1 = v_c1*10/6;
    i_l  = i_l*10/6;
    
    % montando vetor de estados
    state = [v_c1; v_c2; i_l;];

    if self.verbose
        disp('Received state:');
        disp(state);
    end
    % xtarget = [1.6667; 3.3391; 0.0583];

    [time_us, dtk] = self.simulation.signal_process(state, dtk_prev);
    
    % save last `dtk`
    dtk_prev = dtk;

    % construct signal message command
    mode = self.simulation.get_mode();
    command = Utils.signal_create(time_us, mode);
    
    % send message to ESP32
    if self.verbose
        disp('Sending command:');
        disp(command);
    end
    self.msg(command);

end
