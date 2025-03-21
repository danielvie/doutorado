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
    disp(['a6 - a5: ', num2str(parsed_data.an6-parsed_data.an5)]);
    
    % state = [parsed_data.an4; parsed_data.an5; parsed_data.an6;];

    state = [1.6759
    3.3386
    0.0627];
    % xtarget = [1.6667; 3.3391; 0.0583];

    tic;
    Ts = self.simulation.signal_process(state);
    toc
    
    disp('Ts:');
    disp(Ts);
end
