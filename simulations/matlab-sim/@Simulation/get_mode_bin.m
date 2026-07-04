function [d1, d2, d3, d4] = get_mode_bin(self)
    % get_mode_bin - Delegates to Hardware.mode_to_binary
    [d1, d2, d3] = Hardware.mode_to_binary(self.m_config.Omega);
    d4 = zeros(1, numel(self.m_config.Omega)); % unused, kept for backward compat
end