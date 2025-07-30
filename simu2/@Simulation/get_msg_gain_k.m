function msg_gain_k = get_msg_gain_k(self)
    gain_k = self.m_config.mpc.K;

    sout_elements = arrayfun(@num2str, gain_k, 'UniformOutput', false);
    sout = strjoin(sout_elements, ',');

    [m,n] = size(gain_k);
    msg_gain_k = sprintf("MATRIX:%d;%d;%s;", m,n,sout);
end