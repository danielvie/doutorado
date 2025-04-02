function time_us = get_time_us(self)
    time_us = arrayfun(@round, diff(self.config.Ts*1e6));
end