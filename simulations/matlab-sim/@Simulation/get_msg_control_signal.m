function msg_control_signal = get_msg_control_signal(self)
    % get_msg_control_signal - Delegates to Hardware.format_control_message
    msg_control_signal = Hardware.format_control_message(self.m_config);
end