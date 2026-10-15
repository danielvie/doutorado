function comparison = export_mpc_comparison(paths,b,model,controller,response)
%EXPORT_MPC_COMPARISON Adopt checked 1x evidence and matched host measurements.
% Reuses saved MPC solves; never solves a QP or reruns the timing benchmark.
study_root = fullfile(paths.root,'studies','mpc-comparison');
source = fullfile(study_root,'results','error-scale-1x','study.mat');
saved = load(source,'study');
comparison = paper.mpc_comparison_data(saved.study,b,model,controller,response);
folder = fullfile(study_root,'results','matched-timing');
environment = jsondecode(fileread(fullfile(folder,'environment.json')));
measured_sources = {fullfile(study_root,'benchmark_matched_timing.m'), ...
    fullfile(paths.root,'scripts','condition_dwell_times.m'), ...
    fullfile(paths.simulation,'+Mpc','solve.m'),source};
% The solver-runtime hash remains in the study's environment record. It need
% not match a different MATLAB installation merely importing past timings.
for k = 1:numel(measured_sources)
    index = k; if k == 4, index = 5; end
    assert(strcmp(sha256(measured_sources{k}),environment.source_hashes(index).sha256), ...
        'Measured controller or study changed; rerun task mpc-comparison:matched-timing.');
end
samples = readtable(fullfile(folder,'samples.csv'),'TextType','string');
summary = readtable(fullfile(folder,'summary.csv'),'TextType','string');
methods = ["daniel","mpc-5"];
for j = 1:2
    s = samples(samples.method==methods(j),:);
    t = summary(summary.method==methods(j),:);
    assert(height(t)==1 && height(s)==environment.measured_calls_per_controller);
    assert(t.count==height(s) && sum(s.order_in_pair==1)==sum(s.order_in_pair==2));
    values = [median(s.seconds),prctile(s.seconds,95)]*1e6;
    assert(max(abs(values-[t.median_us,t.p95_us])) < 1e-8);
    comparison.timing_median_us(j) = t.median_us;
    comparison.timing_p95_us(j) = t.p95_us;
end
comparison.timing_samples = environment.measured_calls_per_controller;
comparison.timing_warmup = environment.warmup_calls_per_controller;
comparison.timing_states = numel(unique(samples.state_id));
comparison.timing_release = environment.matlab_release;
comparison.timing_scope = 'Matched desktop state-to-validated-schedule calls; zero-plan QP initialization.';
for directory = {paths.results,fullfile(paths.output,'latex')}
    if ~isfolder(directory{1}), mkdir(directory{1}); end
end
save(fullfile(paths.results,'mpc_comparison.mat'),'comparison');
rows = table(comparison.cycle,comparison.time_ms,comparison.error(:,1), ...
    comparison.error(:,2),[min(comparison.mpc_dwell,[],1)';NaN]*1e6, ...
    'VariableNames',{'cycle','time_ms','conditioned_error','mpc_error','mpc_minimum_dwell_us'});
writetable(rows,fullfile(paths.results,'mpc_comparison.csv'));
fid = fopen(fullfile(paths.output,'latex','mpc_metrics.tex'),'w'); assert(fid~=-1);
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'%% Generated from checked 1x MPC evidence and matched host timing.\n');
macro(fid,'MpcHorizon',comparison.horizon,'%d');
macro(fid,'ProposedEvaluationCost',comparison.cost(1),'%.5f');
macro(fid,'MpcEvaluationCost',comparison.cost(2),'%.5f');
macro(fid,'MpcCostReduction',100*(1-comparison.cost(2)/comparison.cost(1)),'%.1f');
macro(fid,'MpcSettlingCycle',comparison.threshold_cycle(2),'%d');
macro(fid,'MpcSettlingMilliseconds',comparison.threshold_cycle(2)*b.period*1e3,'%.3f');
macro(fid,'ProposedMatchedMedianUs',comparison.timing_median_us(1),'%.2f');
macro(fid,'MpcMatchedMedianUs',comparison.timing_median_us(2),'%.2f');
macro(fid,'ProposedMatchedPninetyfiveUs',comparison.timing_p95_us(1),'%.2f');
macro(fid,'MpcMatchedPninetyfiveUs',comparison.timing_p95_us(2),'%.2f');
macro(fid,'MatchedTimingSamples',comparison.timing_samples,'%d');
macro(fid,'MatchedTimingWarmup',comparison.timing_warmup,'%d');
macro(fid,'MatchedTimingStates',comparison.timing_states,'%d');
fprintf(fid,'\\newcommand{\\MatchedTimingMatlabRelease}{%s}\n',comparison.timing_release);
end

function macro(fid,name,value,format)
fprintf(fid,'\\newcommand{\\%s}{%s}\n',name,sprintf(format,value));
end

function value = sha256(filename)
fid = fopen(filename,'rb'); assert(fid~=-1);
cleanup = onCleanup(@() fclose(fid));
digest = java.security.MessageDigest.getInstance('SHA-256');
digest.update(fread(fid,Inf,'*uint8'));
value = lower(reshape(dec2hex(typecast(digest.digest(),'uint8'),2)',1,[]));
end
