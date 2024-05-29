function [Omega,dtSwitch] = industrial_solution(alpha,nSwitches,T)

    % Inputs:
    % alpha: Duty cyle in the interval (0, 1)
    % nSwitches: Number of switch cells
    % T: Period of the entire switching cycle
    %
    % Outputs:
    % Omega: Mode sequence
    % dtSwitch: Time intervals between the successive switching instants

    % Step 1: Define t0,i ; ton,i ; toff,i and initial state of the ith switch
    % cell

    t0 = zeros(1,nSwitches); ton = t0; toff = t0; % Size initialization
    initialState = zeros(1,nSwitches);
    for i = 1:nSwitches
        %     t0(i) = (nSwitches-i)*T/nSwitches;
        t0(i) = (i-1)*T/nSwitches;
        toff(i) = mod( t0(i) + alpha*T/2, T );
        ton(i) = mod( t0(i) + T - alpha*T/2 , T );
        % Note that ton(i) is never equal to toff(i) with 0 < alpha < 1
        if ton(i) < toff(i)
            initialState(i) = 0;
        else
            initialState(i) = 1;
        end
    end

    % Step 2: Obtain switching times
    [tSwitch,indexSort] = sort([ton toff]);
    aux = 1:nSwitches;
    SwitchIdUnsorted = [aux aux];
    SwitchId = SwitchIdUnsorted(indexSort);

    % Step 3: Obtain mode sequence in binary coding form
    % Note that the final state is equal to the initial state
    OmegaBin{1} = initialState;
    for i = 1:(2*nSwitches)-1
        % Open or close the switch corresponding to the ith switching time
        previousState = OmegaBin{i};
        SwitchToChange = SwitchId(i);
        newState = previousState;
        newState(SwitchToChange) = 1 - previousState(SwitchToChange);
        OmegaBin{i+1} = newState;
    end

    % Step 4: Convert the mode sequence to decimal form
    for i = 1:2*nSwitches
        Omega(i) = 1 + bin2dec(num2str(OmegaBin{i}));
        [OmegaBin{i} Omega(i)]
    end

    % Step 5: Convert tSwitch to dtSwitch assuming that the final switching
    % time will be shifted to t = T;
    dtSwitch = diff([0 tSwitch]);
    dtSwitch(1) = dtSwitch(1) + T - tSwitch(end);
end