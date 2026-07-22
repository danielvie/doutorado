% t - Task runner for common simulation workflows
%
% Usage:
%   t <task>
%   t <task> <name>
%
% Tasks:
%   run <name>      - Run simulation: lab, patino1, patino2, integrador,
%                     linearization_comparison
%   projection <name> - Run projection: patino1, patino2, integrador, automate
%   test            - Run test suite
%   demo <name>     - Run demo: projection, broker, feasibility
%   clean           - Clean generated files
%   docs            - Open documentation
%
% Examples:
%   t run patino2
%   t run patino1
%   t run lab
%   t run linearization_comparison
%   t test
%   t demo projection
%   t projection patino1
%   t projection automate

function t(task, varargin)
    if nargin < 1
        help t;
        return;
    end

    switch lower(task)
        case 'run'
            if nargin < 2
                fprintf(['Available runs: lab, patino1, patino2, ', ...
                    'integrador, linearization_comparison\n']);
            else
                run_simulation(varargin{1});
            end

        case 'test'
            run_tests();

        case 'demo'
            if nargin < 2
                fprintf('Available demos: projection, broker, feasibility (alias for projection)\n');
            else
                run_demo(varargin{1});
            end

        case 'projection'
            if nargin < 2
                fprintf('Available projections: patino1, patino2, integrador, automate\n');
            else
                run_projection(varargin{1});
            end

        case 'clean'
            clean_files();

        case 'docs'
            open_docs();

        otherwise
            fprintf('Unknown task: %s\n', task);
            help t;
    end
end

function run_simulation(name)
    switch lower(name)
        case {'lab', 'lab_circuit', 'default'}
            Runner.Scripts.run();
        case 'patino1'
            Runner.Scripts.run_patino1();
        case 'patino2'
            Runner.Scripts.run_patino2();
        case 'linearization_comparison'
            Runner.Experiments.compare_patino2_linearizations();
        case {'integrador', 'double_integrator'}
            Runner.Scripts.run_integrador_duplo();
        otherwise
            fprintf('Run "%s" not found.\n', name);
            fprintf(['Available runs: lab, patino1, patino2, ', ...
                'integrador, linearization_comparison\n']);
    end
end

function run_projection(name)
    switch lower(name)
        case 'patino1'
            Runner.Experiments.z_projection_patino1();
        case 'patino2'
            Runner.Experiments.z_projection_patino2();
        case {'integrador', 'double_integrator'}
            Runner.Experiments.z_projection_double_integrator();
        otherwise
            fprintf('Projection "%s" not found.\n', name);
            fprintf('Available projections: patino1, patino2, integrador\n');
    end
end

function run_tests()
    fprintf('Running test suite...\n');
    Runner.Tests.check_constraints_patino1();
    Runner.Tests.check_diff();
    Runner.Tests.check_dtk_sign();
    Runner.Tests.check_exitflag();
    Runner.Tests.check_matrices();
    Runner.Tests.check_prop();
    Runner.Tests.check_values();
    Runner.Tests.test_basic();
    Runner.Tests.test_dlqr_behavior();
    Runner.Tests.test_domain_model();
    Runner.Tests.test_industrial_solution();
    Runner.Tests.test_mpc_on();
    Runner.Tests.test_run_flow();
    Runner.Tests.test_patino_params();
    Runner.Tests.test_status();
    Runner.Tests.test_who();
    fprintf('Tests complete.\n');
end

function run_demo(name)
    switch lower(name)
        case 'projection'
            Runner.Demos.z_demo_projection();
        case 'broker'
            Runner.Demos.z_broker();
        case 'feasibility'
            Runner.Demos.z_demo_projection();
        otherwise
            fprintf('Demo "%s" not found.\n', name);
    end
end

function clean_files()
    fprintf('Cleaning generated files...\n');
    if exist('outputs', 'dir')
        files = dir('outputs/*.mat');
        for i = 1:length(files)
            delete(fullfile('outputs', files(i).name));
        end
        fprintf('  Cleaned outputs/\n');
    end
    fprintf('Done.\n');
end

function open_docs()
    doc_path = fullfile(pwd, 'DOCS', 'GETTING_STARTED.md');
    fprintf('Documentation: %s\n', doc_path);
    if ispc
        winopen(doc_path);
    elseif ismac
        system(['open "' doc_path '"']);
    else
        system(['xdg-open "' doc_path '"']);
    end
end
