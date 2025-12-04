function [control_dtk_prime, time_prime] = condition_dtk_signal(time_increment, control_dtk, min_gap)
    % time_increment: Increment array [N-1 x 1]
    % control_dtk: Diff array [N-2 x 1]
    % min_gap: Scalar minimum gap required

    % time_reference: Reference array [N x 1]
    time_reference = Utils.time_array_from_diff(time_increment);

    % 1. Create the "Augmented" control_dtk that aligns with time_reference
    time_control_aug = [0; control_dtk(:); 0]; 
    
    % 2. Calculate the existing gaps in time_reference
    gaps_time_ref = diff(time_reference(:));
    
    % 3. Calculate how control_dtk affects the gaps
    gap_change = diff(time_control_aug);
    
    % We only care when gap_change is negative (shrinking the gap).
    % When gap_change < 0, dividing flips the inequality:
    % alpha <= (min_gap - gaps_time_ref) / gap_change
    alpha = 1.0; % Start assuming we can apply 100% of control_dtk
    
    % Find indices where control_dtk is trying to shrink the gap
    shrinking_indices = gap_change < 0;
    
    if any(shrinking_indices)
        % Calculate limits for these specific gaps
        numerator = min_gap - gaps_time_ref(shrinking_indices);
        denominator = gap_change(shrinking_indices);
        
        max_possible_alphas = numerator ./ denominator;
        
        % The strict limit is the minimum of all allowed alphas
        limit = min(max_possible_alphas);
        
        % We clamp alpha between 0 and 1. 
        % (If limit < 0, it means even 0% of control_dtk isn't enough, 
        % likely meaning original time_reference violated constraints).
        alpha = max(0, min(1, limit));
    end
    
    % 4. Apply the conditioned control 
    time_prime = time_reference(:) + alpha * time_control_aug;
    control_dtk_prime = alpha*time_control_aug(2:end-1);
end
    