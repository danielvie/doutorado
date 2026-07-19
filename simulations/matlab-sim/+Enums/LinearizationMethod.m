classdef LinearizationMethod
    enumeration
        SWITCHING_TIME      % Direct sensitivity to interior switching times
        AUGMENTED_DURATION  % Homogeneous-state sensitivity to interval durations
    end
end
