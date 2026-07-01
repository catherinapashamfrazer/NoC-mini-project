function test_plot_noc_performance()
baseDir = fileparts(mfilename('fullpath'));
fixtureCsv = fullfile(baseDir, 'testdata', 'noc_results_sample.csv');
tmpDir = tempname;
mkdir(tmpDir);
copyfile(fixtureCsv, tmpDir);
cleanup = onCleanup(@() rmdir(tmpDir, 's'));

resultsFile = fullfile(tmpDir, 'noc_results_sample.csv');
summary = plot_noc_performance(resultsFile);

assert(summary.rows == 4);
assert(isequal(summary.traffic(:).', [10 20 30 40]));
assert(isequal(summary.latency(:).', [4.2 5.1 6.7 8.8]));
assert(isequal(summary.throughput(:).', [0.08 0.14 0.19 0.23]));
assert(isequal(summary.loss(:).', [0 1 2 3]));
assert(isequal(summary.utilization(:).', [0.25 0.35 0.44 0.52]));
assert(exist(summary.exportPath, 'file') == 2);

if ~isempty(summary.figure)
    close(summary.figure);
end

disp('test_plot_noc_performance passed');
end
