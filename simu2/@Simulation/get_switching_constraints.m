function c = get_switching_constraints(self)

    cfg = self.m_config;

    N  = numel(cfg.Omega);

    Ts  = cfg.Ts;
    dtr = diff(Ts);

    % constraint time
    c_time = self.m_config.c_time;
    c_time_numel = numel(c_time);

    c = zeros(N, 1);
    for i= 1:N
        c_time_i = rem(i-1, c_time_numel) + 1;
        c(i) = -dtr(i) + c_time(c_time_i);
    end

    % c = [
    %     -dtr(1) + t_min;
    %     -dtr(2) + t_min;
    %     -dtr(3) + t_min;
    %     -dtr(4) + t_min;
    %     -dtr(5) + t_min;
    %     -dtr(6) + t_min;
    %     -dtr(7) + t_min;
    %     -dtr(8) + t_min;
    %     -dtr(9) + t_min;
    % ]; % dimensao: Nx1
    
    % print c if no output argument
    if nargout == 0
        fprintf('c:\n');
        disp(c);
    end

end
