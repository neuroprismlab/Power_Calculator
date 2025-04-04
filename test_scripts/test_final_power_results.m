function test_final_power_results()
%% test_final_power_results
% Validates the final power calculation results by checking that the computed 
% true positive rate (TPR) values match the expected ground-truth.
%
% This function iterates over all power result files in the designated directory
% (./power_calculator_results/power_calculation/syn_power/), loads each file, 
% and performs assertions based on the expected number of elements:
%   - For edge-level methods (expected TPR length = 10):
%       * The first 5 indices should have a TPR of 25.
%       * The next 5 indices should have a TPR of 0.
%   - For network-level methods (expected TPR length = 4):
%       * The first 2 indices should have a TPR of 25.
%       * The next 2 indices should have a TPR of 0.
%
% It also checks that no unexpected indices show nonzero power values.
%
% Outputs:
%   - None (errors are thrown if any assertion fails).
%
% Dependencies:
%   - MATLAB built-in functions: dir, load, setdiff.
%
% Notes:
%   - Assumes each power result file contains a structure \texttt{power_data} with a field \texttt{tpr}.
%   - This function is intended for internal validation of power calculation outputs.

    % Directory containing the power result files
    power_results_dir = './power_calculator_results/power_calculation/syn_power/';

    % List all power result files
    files = dir(fullfile(power_results_dir, '*.mat'));
    
    % If no files were found, output an error
    if isempty(files)
        error('No power calculation result files found.');
    end

    % Loop through each power result file
    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        loaded_data = load(file_path); % Load power data
        
        % Extract power_data
        power_data = loaded_data.power_data; 

        % Determine number of elements (edge-level vs network-level)
        num_elements = length(power_data.tpr);

        % Define expected positive indices based on known structure
        if num_elements == 10  % Edge-level method (5 indices at 25%)
            gt_pos_indices = 1:5;
            gt_neg_indices = 6:10;
        elseif num_elements == 4  % Network-level method (2 indices at 25%)
            gt_pos_indices = 1:2;
            gt_neg_indices = 3:4;
        else
            error('Unexpected tpr length in power_data. Check ground truth dimensions.');
        end
        
        % Retrieve computed power values
        computed_tpr = power_data.tpr;

        % **Assertion 1: Power values at expected positive locations should be 25%**
        assert(all(abs(computed_tpr(gt_pos_indices) - 25) < 1e-5), ...
            sprintf('Mismatch in power values for positive indices in test: %s', files(i).name));

        assert(all(abs(computed_tpr(gt_neg_indices) - 0) < 1e-5), ...
            sprintf('Mismatch in power values for negative indices in test: %s', files(i).name));

        % **Assertion 2: No power detected outside of expected true positive locations**
        false_positive_indices = setdiff(1:length(computed_tpr), [gt_pos_indices, gt_neg_indices]);
        assert(all(computed_tpr(false_positive_indices) == 0), ...
            sprintf('False positives detected in test: %s', files(i).name));
    end

end

