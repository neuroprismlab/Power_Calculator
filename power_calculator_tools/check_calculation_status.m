function existing_repetitions = check_calculation_status(RP)
%% check_calculation_status
% **Description**
% Checks which statistical methods already have repetitions computed and saved to disk.
% It returns a struct mapping each method to the number of repetitions available 
% in the corresponding result file.
%
% **Inputs**
% - `RP` (struct): Configuration structure containing:
%   * `save_directory` – path to the directory with output files.
%   * `data_set` – name of the dataset.
%   * `test_name` – label of the statistical test.
%   * `test_type` – type of test ('t', 't2', etc.).
%   * `n_subs_subset` – number of subjects for current subsample.
%   * `testing` – logical flag for test/debug mode.
%   * `all_cluster_stat_types` – list of method names to check.
%   * `omnibus_type` – string used for omnibus method labeling (only used when method is 'Omnibus').
%
% **Outputs**
% - `existing_repetitions` (struct): Map from method name to the number of valid repetitions.
%
% **Workflow**
% 1. Loop over all cluster stat types.
% 2. For each method:
%    - Use `create_and_check_rep_file` to get the expected result file path.
%    - If the file exists, load it and inspect the `brain_data.pvals_all` field.
%    - Count the number of valid repetitions as columns with non-NaN values.
%    - If file is missing or malformed, default to 0 repetitions.
%
% **Dependencies**
% - `create_and_check_rep_file.m`
%
% **Notes**
% - If a method class is improperly named or missing, a warning is issued and zero repetitions are assumed.
%
% **Author**: Fabricio Cravo  
% **Date**: March 2025

    % Initialize outputs
    num_methods = length(RP.all_full_stat_type_names);
    existing_repetitions = struct();

    % Iterate through all methods and check existing repetitions
    for stat_id = 1:num_methods
        stat_type = RP.all_full_stat_type_names{stat_id};
       
        % Get the filename using create_and_check_rep_file
        [existence, file_path] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                           RP.test_type, stat_type, RP.n_subs_subset, ...
                                                           RP.testing);

        if existence
            try
                % Load the saved file
                loaded_data = load(file_path, 'brain_data');
                
                % Check how many repetitions exist
                if isfield(loaded_data, 'brain_data') && isfield(loaded_data.brain_data, 'pvals_all')
                    % Count only columns that contain at least one non-NaN value
                    valid_reps = sum(any(~isnan(loaded_data.brain_data.pvals_all), 1));
                    existing_repetitions.(stat_type) = valid_reps;
                else
                    existing_repetitions.(stat_type) = 0; % File exists but no repetitions found
                end

            catch
                warning('Error loading %s. Assuming 0 repetitions.', file_path);
                existing_repetitions.(stat_type) = 0;
            end
        else
            existing_repetitions.(stat_type) = 0; % File does not exist
        end
    end
end