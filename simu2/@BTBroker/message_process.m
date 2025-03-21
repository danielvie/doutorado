function message_process(self, msg)
    % parsing message
    tokens = regexp(msg, '(\w+):([\d.]+)', 'tokens');
    parsed_data = struct();
    for i = 1:length(tokens)
        key = tokens{i}{1};
        value = str2double(tokens{i}{2});
        parsed_data.(key) = value;
    end
    
    disp(parsed_data);
    

    v_c1 = parsed_data.an4;
    v_c2 = parsed_data.an5;
    i_l  = parsed_data.an6 / 22; % tensao / resistencia resistor
    state = [v_c1; v_c2; i_l;];

    % xtarget = [1.6667; 3.3391; 0.0583];

    tic;
    Ts = self.simulation.signal_process(state);
    toc
    
    disp('Ts:');
    disp(Ts);
end
