function applied_boundary_times = compute_ts_from_dtk( ...
    self, nominal_boundary_times, switching_offsets)
    % Shift nominal interior boundary times without changing the cycle period.

    applied_boundary_times = nominal_boundary_times;

    % applied_boundary_times = self.quantizacao( ...
    %     applied_boundary_times, Enums.QuantType.Sim);

    for j = 1:numel(switching_offsets)
        applied_boundary_times(j + 1) = ...
            applied_boundary_times(j + 1) + switching_offsets(j);
    end
end
