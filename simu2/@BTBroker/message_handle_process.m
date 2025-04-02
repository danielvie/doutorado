function message_handle_process(self, msg)
    % parsing message
    tokens = regexp(msg, '(\w+):([\d.]+)', 'tokens');
    parsed_data = struct();
    for i = 1:length(tokens)
        key = tokens{i}{1};
        value = str2double(tokens{i}{2});
        parsed_data.(key) = value;
    end
    
    disp(parsed_data);
    

    v_c1 = parsed_data.an6;
    v_c2 = parsed_data.an5;
    i_l  = parsed_data.an3 / 22; % tensao / resistencia resistor
    state = [v_c1; v_c2; i_l;];
    disp("state:");
    disp(state);
    % xtarget = [1.6667; 3.3391; 0.0583];

    tic;
    
    Ts_sec = self.simulation.signal_process(state);
    Ts_us  = Ts_sec*1e6;
    toc
    
    disp('Ts_us:');
    disp(Ts_us);

    time_us = Ts_us;
    mode = self.config.Omega - 1; % '-1' corrects idx for esp32

    command = Helpers.signal_create(time_us, mode);
    fprintf('command: %f\n', command);
    self.message(command);

end
