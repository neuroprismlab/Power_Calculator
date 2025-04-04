function generate_synthetic_gt_data()
%% generate_synthetic_gt_data
% Generates synthetic ground truth data for power calculation testing.
%
% This function creates and saves synthetic data representing ground-truth
% outcomes for both edge-level and network-level tests. It simulates true
% positive and negative effects by assigning nonzero edge and cluster statistics
% to fixed percentages of edges and networks. The resulting data is saved in a 
% designated output directory.
%
% Outputs:
%   - No direct output; the synthetic ground truth data is saved as a MATLAB file
%     in the './power_calculator_results/ground_truth/syn_power/' directory.
%
% Workflow:
%   1. Define the output directory and ensure it exists.
%   2. Set fixed numbers of edges and networks for synthetic testing.
%   3. Calculate split points corresponding to 25% and 50% of edges/networks.
%   4. Construct a meta_data structure with fixed parameters (e.g., dataset, map, test type).
%   5. For edge-level ground truth:
%      - Assign positive true positives to the first 25% of edges.
%      - Assign negative true positives to the next 25% of edges.
%      - Set the negative edge statistics as the negative of the positive ones.
%   6. For network-level ground truth:
%      - Similarly, assign positive and negative true positives based on split points.
%   7. Update meta_data for the edge-level test and generate a filename using
%      name_file_from_meta_data.
%   8. Save the brain_data and meta_data structures to the specified output directory.
%
% Dependencies:
%   - name_file_from_meta_data.m

    % Directory where synthetic ground truth files will be saved
    output_dir = './power_calculator_results/ground_truth/syn_power/';
    
    % Ensure directory exists
    if ~exist(output_dir, 'dir')
        mkdir(output_dir);
    end

    % Set fixed number of edges and networks (same as the test data)
    num_edges = 10;   % Example: 100 edges for edge-level tests
    num_networks = 4; % Example: 10 networks for network-level tests

    % Define split points for assigning 25% and 25%-50% ranges
    split_25_edges = round(0.25 * num_edges);
    split_50_edges = round(0.50 * num_edges);
    split_25_networks = round(0.25 * num_networks);
    split_50_networks = round(0.50 * num_networks);

    % Common metadata fields for both edge and network level tests
    meta_data = struct();
    meta_data.dataset = 'syn';
    meta_data.map = 'power';
    meta_data.test = 'synthetic';  % Placeholder test type
    meta_data.test_components = {'REST', 'TASK'};
    meta_data.statistic_level = 'whole_brain';
    meta_data.subject_number = 40; % Fixed subject number for testing
    meta_data.testing_code = 1; % Indicator for test mode
    meta_data.run_time = rand() * 10; % Fake runtime
    meta_data.date = '1990-04-27';

    % ----- Edge-Level Ground Truth -----
    brain_data = struct();
    brain_data.edge_stats_all = zeros(num_edges, 1);
    brain_data.edge_stats_all_neg = zeros(num_edges, 1);

    % Assign 25% of edges as positive true positives
    brain_data.edge_stats_all(1:split_25_edges) = abs(randn(split_25_edges, 1)) + 1e-5;
    % Assign next 25% of edges as negative true positives
    brain_data.edge_stats_all(split_25_edges+1:split_50_edges) = ...
        -abs(randn(split_50_edges - split_25_edges, 1)) - 1e-5;

    % ----- Network-Level Ground Truth -----
    brain_data.cluster_stats_all = zeros(num_networks, 1);
    brain_data.cluster_stats_all_neg = zeros(num_networks, 1);

     % ----- Network-Level GT Fix -----
     % Assign 25% of networks as positive true positives
    brain_data.cluster_stats_all(1:split_25_networks) = abs(randn(split_25_networks, 1)) + 1e-5;
     % Assign next 25% of networks as negative true positives
    brain_data.cluster_stats_all(split_25_networks+1:split_50_networks) = ...
        -abs(randn(split_50_networks - split_25_networks, 1)) - 1e-5;

    % Set `edge_stats_all_neg` explicitly to match but with reversed sign
    brain_data.edge_stats_all_neg = -brain_data.edge_stats_all;


    % Update meta_data for edge-level test
    meta_data.significance_method = 'Ground_Truth'; % Edge-level method

    % Save edge-level ground truth
    filename_edge = name_file_from_meta_data(meta_data);
    full_file = ['./power_calculator_results/ground_truth/syn_power/', filename_edge];
    save(full_file, 'brain_data', 'meta_data');

end