function get_last_calc(self, n_chunk)
    if nargin == 1
        n_chunk = 1;
    end

    cmd = sprintf("LOG_LAST_CALC:%d", n_chunk);
    self.msg(cmd);
    fprintf("command: %s\n", cmd);
end