function set_cycles_nrun(self, value)
    if isnumeric(value)
        value = num2str(value);
    end
    value_ = eval(value);
    command = sprintf("CYCLE_NRUN:%d", value_);
    self.msg(command);
end