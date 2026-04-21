% t - Task runner for common simulation workflows
%
% Usage: t <task>
%
% Tasks:
%   play            - Run main simulation (LAB_CIRCUIT)
%   play_patino1    - Run Patino 1 benchmark
%   play_patino2    - Run Patino 2 benchmark
%   play_integrador - Run double integrator example
%   test            - Run test suite
%   demo            - Run interactive demos
%   clean           - Clean generated files
%   docs            - Open documentation
%
% Examples:
%   t play
%   t test
%   t demo projection

function t(task, varargin)
    if nargin < 1
        help t;
        return;
    end

    switch lower(task)
        case 'play'
            play();

        case 'play_patino1'
            z_run.Scripts.play_patino1();

        case 'play_patino2'
            z_run.Scripts.play_patino2();

        case 'play_integrador'
            z_run.Scripts.play_integrador_duplo();

        case 'test'
            run_tests();

        case 'demo'
            if nargin < 2
                fprintf('Available demos: projection, broker, feasibility\n');
            else
                run_demo(varargin{1});
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
