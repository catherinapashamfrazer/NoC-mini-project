function summary = plot_noc_performance(resultsSource)
%PLOT_NOC_PERFORMANCE Plot NoC metrics from a CSV file or a table.

if nargin < 1 || isempty(resultsSource)
    resultsSource = 'noc_results.csv';
end

[data, exportPath] = load_results(resultsSource);

traffic = required_column(data, {'traffic', 'traffic_percent', 'offered_load', 'load'});
latency = required_column(data, {'latency', 'avg_latency', 'avg_latency_cycles', 'latency_cycles'});
throughput = required_column(data, {'throughput', 'throughput_packets_per_cycle', 'throughput_pkts_per_cycle', 'throughput_ppc'});
loss = optional_column(data, {'packet_loss', 'packet_loss_percent', 'drop_rate', 'loss_percent'});
sent = optional_column(data, {'packets_sent', 'sent_packets', 'tx_packets'});
delivered = optional_column(data, {'packets_delivered', 'delivered_packets', 'rx_packets'});
utilization = optional_column(data, {'utilization', 'link_utilization', 'channel_utilization'});

fig = figure('Color', 'w', 'Name', 'NoC Performance Summary', 'Visible', 'off');

subplot(2, 2, 1);
plot(traffic, latency, '-o', 'LineWidth', 1.5, 'MarkerSize', 5);
grid on; xlabel('Traffic'); ylabel('Latency'); title('Latency vs Traffic');

subplot(2, 2, 2);
plot(traffic, throughput, '-s', 'LineWidth', 1.5, 'MarkerSize', 5);
grid on; xlabel('Traffic'); ylabel('Throughput'); title('Throughput Trend');

subplot(2, 2, 3);
if ~isempty(loss)
    plot(traffic, loss, '-^', 'LineWidth', 1.5, 'MarkerSize', 5);
    ylabel('Loss / Drop Rate');
elseif ~isempty(sent) && ~isempty(delivered)
    bar(traffic, [sent(:), delivered(:)], 'grouped');
    ylabel('Packet Count');
    legend({'Sent', 'Delivered'}, 'Location', 'best');
else
    axis off;
    text(0.5, 0.5, 'No packet-loss or count columns found', 'HorizontalAlignment', 'center');
end
grid on; xlabel('Traffic'); title('Auxiliary Performance');

subplot(2, 2, 4);
if ~isempty(utilization)
    plot(traffic, utilization, '-d', 'LineWidth', 1.5, 'MarkerSize', 5);
    grid on; xlabel('Traffic'); ylabel('Utilization'); title('Link Utilization');
else
    axis off;
    text(0.5, 0.5, 'Optional utilization column not found', 'HorizontalAlignment', 'center');
end

summary = struct(...
    'rows', height(data), ...
    'traffic', traffic, ...
    'latency', latency, ...
    'throughput', throughput, ...
    'loss', loss, ...
    'sent', sent, ...
    'delivered', delivered, ...
    'utilization', utilization, ...
    'exportPath', exportPath, ...
    'figure', fig);

if exist('exportgraphics', 'file') == 2
    try
        exportgraphics(fig, exportPath, 'Resolution', 200);
    catch
        print(fig, exportPath, '-dpng', '-r200');
    end
else
    print(fig, exportPath, '-dpng', '-r200');
end

end

function [data, exportPath] = load_results(resultsSource)
if isa(resultsSource, 'table')
    data = resultsSource;
    exportPath = fullfile(pwd, 'noc_performance_summary.png');
    return;
end

resultsFile = char(resultsSource);
resultsDir = fileparts(resultsFile);
if isempty(resultsDir)
    resultsDir = pwd;
end
exportPath = fullfile(resultsDir, 'noc_performance_summary.png');

if exist(resultsFile, 'file')
    data = readtable(resultsFile);
else
    warning('Results file "%s" not found. Using built-in demo data.', resultsFile);
    data = table(...
        [10; 20; 30; 40], ...
        [4.2; 5.1; 6.7; 8.8], ...
        [0.08; 0.14; 0.19; 0.23], ...
        [0; 0; 1; 1], ...
        [0.25; 0.40; 0.55; 0.68], ...
        'VariableNames', {'traffic_percent', 'avg_latency_cycles', 'throughput_packets_per_cycle', 'packet_loss_percent', 'utilization'});
end
end

function values = required_column(data, candidates)
values = optional_column(data, candidates);
if isempty(values)
    error('Missing required column. Expected one of: %s', strjoin(candidates, ', '));
end
end

function values = optional_column(data, candidates)
values = [];
names = normalize_names(data.Properties.VariableNames);
for index = 1:numel(candidates)
    candidate = normalize_names(candidates{index});
    match = find(strcmp(names, candidate), 1);
    if ~isempty(match)
        values = data{:, match};
        return;
    end
end
end

function names = normalize_names(names)
if ischar(names)
    names = cellstr(names);
elseif ~iscell(names)
    names = cellstr(names);
end
names = cellfun(@lower, names, 'UniformOutput', false);
names = regexprep(names, '[^a-z0-9]+', '_');
end