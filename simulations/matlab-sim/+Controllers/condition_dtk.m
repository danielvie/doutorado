function dtk_out = condition_dtk(time_increment, control_dtk, min_gap)
    % condition_dtk - Scale dtk to respect minimum dwell time.
    %
    % Computes a scaling factor alpha in [0, 1] such that applying
    % alpha * dtk to the nominal switching times does not violate
    % the minimum gap constraint.
    %
    % This is used by the Proportional controller. The MPC controller
    % handles constraints internally via its QP formulation.
    %
    % Inputs:
    %   time_increment - Nominal time intervals [N x 1] (microseconds)
    %   control_dtk    - Control deviations [N-1 x 1] (microseconds)
    %   min_gap        - Minimum allowed gap (microseconds, scalar)
    %
    % Outputs:
    %   dtk_out - Conditioned control deviations [N-1 x 1]

    % Build cumulative time reference
    time_reference = Utils.time_array_from_diff(time_increment);

    % Augment dtk with zeros at boundaries
    time_control_aug = [0; control_dtk(:); 0];

    % Existing gaps in reference
    gaps_time_ref = diff(time_reference(:));

    % How dtk affects the gaps
    gap_change = diff(time_control_aug);

    % Compute maximum safe scaling alpha
    alpha = 1.0;
    shrinking = gap_change < 0;

    if any(shrinking)
        numerator = min_gap - gaps_time_ref(shrinking);
        denominator = gap_change(shrinking);
        limit = min(numerator ./ denominator);
        alpha = max(0, min(1, limit));
    end

    dtk_out = alpha * control_dtk(:);
end
