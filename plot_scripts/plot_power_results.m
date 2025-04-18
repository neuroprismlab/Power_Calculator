    function plot_power_results(dataset_or_directory)
    
    files = data_set_or_directory_mat_file_loading(dataset_or_directory, 'sub_directory', '/power_calculation/');

    % Initialize structure to store power results
    power_results = struct();
    unique_subject_numbers = [];   

    % Process each file
    for i = 1:numel(files)
        file_path = fullfile(files(i).folder, files(i).name);
        data = load(file_path);

        if ~isfield(data, 'meta_data') || ~isfield(data.meta_data, 'subject_number')
            warning('Skipping file (missing meta_data): %s', files(i).name);
            continue;
        end

        % Extract subject number from meta_data
        n_subjects = data.meta_data.subject_number;

        % Keep track of unique subject numbers
        if ~ismember(n_subjects, unique_subject_numbers)
            unique_subject_numbers = [unique_subject_numbers, n_subjects]; %#ok<AGROW>
        end

        % Extract subject number
        n_subjects = data.meta_data.subject_number;

        % Track unique subject numbers
        if ~ismember(n_subjects, unique_subject_numbers)
            unique_subject_numbers = [unique_subject_numbers, n_subjects];
        end

        % Use method list from metadata
        method_list = data.meta_data.method_list;

        for m = 1:length(method_list)
            method_name = method_list{m};

            % Check if method exists in file
            if ~isfield(data, method_name)
                warning('Method "%s" missing in file %s. Skipping...', method_name, files(i).name);
                continue;
            end

            method_data = data.(method_name);

            % Skip if TPR field is missing
            if ~isfield(method_data, 'tpr')
                continue;
            end

            % Extract and flatten TPR values
            tpr_values = method_data.tpr(:);

            % Derive task component info
            test_components = get_test_components_from_meta_data(data.meta_data.test_components);

            % Define path: power_results.method.n_<subjects>.task_type = mean(tpr)
            field_path = {method_name, sprintf('n_%d', n_subjects), test_components};

            % Store result
            power_results = setfield(power_results, field_path{:}, mean(tpr_values));
        end
    
    end
    
    % Check if we have results
    if isempty(fieldnames(power_results))
        error('No valid power results found.');
    end

    % Sort subject numbers and methods
    unique_subject_numbers = sort(unique_subject_numbers);
    subject_labels = arrayfun(@(x) sprintf('nsub %d', x), unique_subject_numbers, 'UniformOutput', false);
    num_subjects = numel(unique_subject_numbers);
    method_names = fieldnames(power_results);
    plot_method_names = strrep(method_names, '_', ' ');
    num_methods = numel(method_names);

    % Generate a figure with subplots (one per subject number)
    num_subplots = numel(unique_subject_numbers);
    figure;
    set(gcf, 'Position', [100, 100, 200 * num_subplots, 500]); % Adjust figure size


    % Collect power data
    for i = 1:num_subjects
        n_subjects = unique_subject_numbers(i);
        for j = 1:num_methods
            method_name = method_names{j};
            
            if isfield(power_results.(method_name), sprintf('n_%d', n_subjects))
                % Extract all task-specific power values
                task_values = struct2cell(power_results.(method_name).(sprintf('n_%d', n_subjects)));
    
                % Convert to array
                all_task_values = cell2mat(task_values);
                
                % Compute mean and standard error
                mean_power(i, j) = mean(all_task_values);
                error_power(i, j) = std(all_task_values) / sqrt(length(all_task_values));
            end
        end
    end

    % Create figure
    figure;
    hold on;
    
    % Define colors for each method
    colors = lines(num_methods);
    
    % Create grouped bar plot
    bar_handle = bar(subject_labels, mean_power, 'grouped');
    
    % Apply colors and add error bars
    for j = 1:num_methods
        bar_handle(j).FaceColor = colors(j, :); % Assign color per method
        x_positions = bar_handle(j).XEndPoints; 
        errorbar(x_positions, mean_power(:, j), error_power(:, j), 'k.', 'LineWidth', 1.5);
    end
    
    % Formatting
    xlabel('Number of Subjects');
    ylabel('Average Power (%)');
    ylim([0, 100]);
    legend(plot_method_names, 'Location', 'northwest', 'Interpreter', 'none', 'FontSize', 12);
    grid on;
    hold off;
    
    dataset_or_directory = strrep(dataset_or_directory, '_', ' ');
    % Main title
    sgtitle(sprintf('Power Calculation Results for %s', dataset_or_directory), ...
        'FontSize', 16, 'FontWeight', 'bold');

end

