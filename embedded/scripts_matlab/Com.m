classdef Com
    properties
        port;
        baudrate;
        serial;
    end

    methods (Static)
        function dtk = calcQuadprog(v)
            % v: variaveis no instante de execucao do mpc_dualmode_switching

            ek     = v.ek;
            H      = v.cfg.mpc.H;
            Hf     = v.cfg.mpc.Hf;
            Phi1Np = v.cfg.mpc.Phi1Np;
            Qbar   = v.cfg.mpc.Qbar;
            Rbar   = v.cfg.mpc.Rbar;
            Lbar   = v.cfg.mpc.Lbar;
            cbar   = v.cfg.mpc.cbar;
            Pf     = v.cfg.mpc.Pf;
            Sf     = v.cfg.mpc.Sf;
            bf     = v.cfg.mpc.bf;
            PhiNp  = v.cfg.mpc.PhiNp;
            p      = v.cfg.mpc.p;

            % imprimindo valores usados:
            disp("ek: ");
            disp(ek);
            disp("H: ");
            disp(H);
            disp("Hf: ");
            disp(Hf);
            disp("Phi1Np: ");
            disp(Phi1Np);
            disp("Qbar: ");
            disp(Qbar);
            disp("Rbar: ");
            disp(Rbar);
            disp("Lbar: ");
            disp(Lbar);
            disp("cbar: ");
            disp(cbar);
            disp("Pf: ");
            disp(Pf);
            disp("Sf: ");
            disp(Sf);
            disp("bf: ");
            disp(bf);
            disp("PhiNp: ");
            disp(PhiNp);
            disp("p: ");
            disp(p);


            % [dtk, ~, ~] = mpc.mpc_dualmode_switching(ek,H,Hf,Phi1Np,Qbar,Rbar,Lbar,cbar,Pf,Sf,bf,PhiNp,p);
            H_qp = 2*(H'*Qbar*H + Rbar + Hf'*Pf*Hf);
            H_qp = (H_qp + H_qp')/2; % Simetrizacao

            fu   = Phi1Np*ek;
            f_qp = 2*(H'*Qbar*fu + Hf'*Pf*PhiNp*ek);

            A_qp = [-Lbar;
                    Sf*Hf];
            b_qp = [-cbar;
                    bf - Sf*PhiNp*ek];

            Aeq_qp = [];
            beq_qp = [];
            lb_qp  = [];
            ub_qp  = [];

            % quadprog(H,f,A,b,Aeq,beq,lb,ub,x0,options)
            % min 0.5 x^T H x + f^T; such that
            %    A.x <= b,
            %    Aeq.x == b,
            %    lb <= x <= ub,

            options = optimoptions('quadprog', 'Algorithm', 'active-set');
            
            x0  = zeros(size(f_qp, 1), 1);
            [Dtk, ~, ~] = quadprog(H_qp,f_qp,A_qp,b_qp,Aeq_qp,beq_qp,lb_qp,ub_qp,x0,options);

            dtk =  Dtk(1:p);
        end
    end


    methods
        function o = Com(port, baudrate)
            o.port = port;
            o.baudrate = baudrate;
            
            serial = serialport(port, baudrate);
            o.serial = serial;
        end
        
        % function serial_obj = serial(o)
        %     serial_obj = serialport(o.port, o.baudrate);
        % end

        function setDelayInterval(o, interval)
            % Convert the interval to a string and send it over serial
            fprintf(o.serial, '%d', interval);
        end
        
        function listen(o)
            serial_ = o.serial;

            keepRunning = 1;
            while keepRunning
                % Check if there is data available to read
                if serial_.NumBytesAvailable > 0
                    analogValue = readline(serial_);
                    fprintf('%s', analogValue);
                end
                pause(0.1); % Small delay to prevent overwhelming the serial port
            end
        end
        
        function toggleSerial(o)
            % Convert the interval to a string and send it over serial
            fprintf(o.serial, 'toggle');
        end
        
        function send(o, value)
            fprintf(o.serial, value);
        end
        
        
        function sendModes(o, time, mode)
            if nargin == 1
                time = [1, 2, 4];
                mode = [8, 9, 0];
            end

            % convert arrays to strings
            time_str = sprintf('%d,', time);
            mode_str = sprintf('%d,', mode);

            % concatenate strings
            result = strcat(time_str, ";", mode_str, ";");

            % remove trailing commas
            result = strrep(result, ",;", ";");
            
            fprintf("sending modes: ""%s""\n", result);
            o.send(result);
        end
    end
end