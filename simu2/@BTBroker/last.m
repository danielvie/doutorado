function last(self, n_chunk)
    if nargin == 1
        n_chunk = 1;
    end
    self.get_last_calc(n_chunk)
end