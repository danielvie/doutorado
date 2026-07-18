classdef StateMode
    % Prediction-model structure. Names retained for compatibility.
    enumeration
        ORIGINAL  % Immediate held-input block model
        AUGMENTED % Experimental one-block-delay model
    end
end
