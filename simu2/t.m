% t - Task runner for common simulation workflows
%
% Usage:
%   t <task>
%   t <task> <name>
%
% Tasks:
%   play <name>     - Run play script: lab, patino1, patino2, integrador
%   projection <name> - Run projection: patino1, patino2, integrador, automate
%   test            - Run test suite
%   demo <name>     - Run demo: projection, broker, feasibility
%   clean           - Clean generated files
%   docs            - Open documentation
%
% Examples:
%   t play lab
%   t play patino1
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
        case 'play'
            if nargin < 2
                fprintf('Available plays: lab, patino1, patino2, integrador\n');
            else
                run_play(varargin{1});
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

function run_play(name)
    switch lower(name)
        case {'lab', 'lab_circuit', 'default'}
            z_run.Scripts.play();
        case 'patino1'
            z_run.Scripts.play_patino1();
        case 'patino2'
            z_run.Scripts.play_patino2();
        case {'integrador', 'double_integrator'}
            z_run.Scripts.play_integrador_duplo();
        otherwise
            fprintf('Play "%s" not found.\n', name);
            fprintf('Available plays: lab, patino1, patino2, integrador\n');
    end
end

function run_projection(name)
    switch lower(name)
        case 'patino1'
            z_run.Experiments.z_projection_patino1();
        case 'patino2'
            z_run.Experiments.z_projection_patino2();
        case {'integrador', 'double_integrator'}
            z_run.Experiments.z_projection_double_integrator();
        otherwise
            fprintf('Projection "%s" not found.\n', name);
            fprintf('Available projections: patino1, patino2, integrador\n');
    end
end

function run_tests()
    fprintf('Running test suite...\n');
    z_run.Tests.check_constraints_patino1();
    z_run.Tests.check_diff();
    z_run.Tests.check_dtk_sign();
    z_run.Tests.check_exitflag();
    z_run.Tests.check_matrices();
    z_run.Tests.check_prop();
    z_run.Tests.check_values();
    z_run.Tests.test_basic();
    z_run.Tests.test_dlqr_behavior();
    z_run.Tests.test_industrial_solution();
    z_run.Tests.test_mpc_on();
    z_run.Tests.test_patino_params();
    z_run.Tests.test_status();
    z_run.Tests.test_who();
    fprintf('Tests complete.\n');
end

function run_demo(name)
    switch lower(name)
        case 'projection'
            z_run.Demos.z_demo_projection();
        case 'broker'
            z_run.Demos.z_broker();
        case 'feasibility'
            z_run.Demos.z_demo_projection();
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
