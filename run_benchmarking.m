function run_benchmarking(RP, Y, X)
% Do NBS-based method benchmarking (cNBS, TFCE, etc)
%
% main outputs:
% edge_stats_all: mean and sd of edge_stats_all
% cluster_stats_all: mean and sd of cluster_stats_all
% pvals_all: total # positives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

%% Setup
% make sure config files in NBS_benchmarking are correct

% setparams_bench;
    
    %% This line is temporary for testing
    %disp('Temporary assigment still here')
    %RP.all_cluster_stat_types = {'#Parametric_Bonferroni', 'Parametric_FDR', 'Size', 'TFCE', ...
    %'#Constrained', 'Constrained_FWER', '#Omnibus'};
    
    for id_nsub_list=1:length(RP.list_of_nsubset)
        RP.n_subs_subset = RP.list_of_nsubset{id_nsub_list};
        RP = set_n_subs_subset(RP);

        [RP.node_nets, RP.trilmask_net, RP.edge_groups] = ...
                extract_atlas_related_parameters(RP, Y);
        
        %% Prepare for GLM precomputation
        [UI, RP] = setup_benchmarking(RP);
        ids_sampled = draw_repetition_ids(RP);
        [GLM_stats, STATS, All_GLM] = precompute_glm_data(X, Y, RP, UI, ids_sampled);

        %% Get some of the statical result data
        [edge_stats_all, edge_stats_all_neg, cluster_stats_all, cluster_stats_all_neg] = ...
            extrac_cell_glm_stats(GLM_stats);

        if RP.ground_truth
            create_gt_files(GLM_stats, RP)
            continue;
        end

        for stat_id=1:length(RP.all_cluster_stat_types)
            RP.cluster_stat_type = RP.all_cluster_stat_types{stat_id};
            
            tic
            
            % If omnibus, we'll loop through all the specified omnibus types
            if ~strcmp(RP.cluster_stat_type, 'Omnibus')
                loop_omnibus_types = {NaN};
            else
                loop_omnibus_types = RP.all_omnibus_types;
            end
            
            for omnibus_id=1:length(loop_omnibus_types) 
                RP.omnibus_type = loop_omnibus_types{omnibus_id};
                 
                if ~isnan(RP.omnibus_type)
                    RP.omnibus_str = RP.omnibus_type;
                else 
                    RP.omnibus_str = 'nobus'; 
                end
           

                %% Create_file_name
                [existence, output_dir] = create_and_check_rep_file(RP.save_directory, RP.data_set, RP.test_name, ...
                                                                    RP.test_type, RP.cluster_stat_type, ...
                                                                    RP.omnibus_str, RP.n_subs_subset, ...
                                                                    RP.testing, RP.ground_truth);

                %% Get complete stats for downstream
                STATS.statistic_type = RP.cluster_stat_type;
                STATS.omnibus_type = RP.omnibus_type;
                
                if existence && RP.recalculate == 0
                    fprintf('Skipping %s \n', output_dir)
                    continue 
                else
                    fprintf('Calculating %s \n', output_dir)
                end
    
                FWER = 0;
                FWER_neg = 0;
               
                % Instantiate method class dynamically
                method_instance = feval(RP.cluster_stat_type);
                
                % Determine level from method instance
                switch method_instance.level
                    case "whole_brain"
                        pvals_all = zeros(1, RP.n_repetitions);
                        pvals_all_neg = zeros(1, RP.n_repetitions);
                
                    case "network"
                        pvals_all = zeros(length(unique(UI.edge_groups.ui)) - 1, RP.n_repetitions);
                        pvals_all_neg = zeros(length(unique(UI.edge_groups.ui)) - 1, RP.n_repetitions);
                
                    case "edge"
                        pvals_all = zeros(RP.n_var, RP.n_repetitions);
                        pvals_all_neg = zeros(RP.n_var, RP.n_repetitions);
                
                    otherwise
                        error("Unknown statistic level: %s", method_instance.level);
                end
                
                            
                if RP.testing
                    fprintf('\n*** TESTING MODE ***\n\n')
                end
                
                % fprintf(['Starting benchmarking - ', RP.task1, '_v_', RP.task2, '::',
                % UI.statistic_type.ui, RP.omnibus_str, '.\n']);
               
                %% Run NBS repetitions
                
                % This is really annoying because if you change one - you
                % need to mimmic and change bellow
                % For whoever fix this - create function with signature
                % with everything and encapsulate 
                
                % Create parallel constants to avoid unnecessary duplication
                if ~RP.parallel
                    for i_rep = 1:RP.n_repetitions
                        % Encapsulation of the most computationally intensive loop
                        [pvals_all_rep, pvals_all_neg_rep] = pf_repetition_loop(i_rep, STATS, ...
                            GLM_stats{i_rep}, All_GLM{i_rep}, RP);
                
                        pvals_all(:, i_rep) = pvals_all_rep;
                        pvals_all_neg(:, i_rep) = pvals_all_neg_rep;
                    end
                else
                    parfor i_rep = 1:RP.n_repetitions
                        % Encapsulation of the most computationally intensive loop
                        [pvals_all_rep, pvals_all_neg_rep] =  pf_repetition_loop(i_rep, STATS, ...
                            GLM_stats{i_rep}, All_GLM{i_rep}, RP);
              
                
                        pvals_all(:, i_rep) = pvals_all_rep;
                        pvals_all_neg(:, i_rep) = pvals_all_neg_rep;
                    end
                end
                
                % An NaN for network-level in the edge case
                %if strcmp(RP.stat_level, 'edge')
                %    cluster_stats_all = NaN;
                %    cluster_stats_all_neg = NaN;
                %end
                
                %if contains(UI.statistic_type.ui,'Constrained') || strcmp(UI.statistic_type.ui,'SEA') ...
                %    || strcmp(UI.statistic_type.ui,'Omnibus')
                %    cluster_stats_all = squeeze(cluster_stats_all);
                %    cluster_stats_all_neg = squeeze(cluster_stats_all_neg);
                %end
                
                run_time = toc;          

                %% Save
                
                if false
                    if strcmp(UI.statistic_type.ui,'Size')
                        size_str = ['_',UI.size.ui];
                    else
                        size_str = '';
                    end
                    
                    if testing
                        test_str = '_testing';
                    else 
                        test_str='';
                    end
                    
                    if do_TPR 
                        TPR_str = '';
                    else 
                        TPR_str = '_shuffled_for_FPR'; 
                    end
                    
                    if use_both_tasks
                        condition_str = [rep_params.task1,'_v_',rep_params.task2];
                    else 
                        condition_str = rep_params.task1;
                    end
                end        
                
                brain_data = add_brain_data_to_repetition_data('edge_stats_all', edge_stats_all, ...
                    'edge_stats_all_neg', edge_stats_all_neg, ...
                    'cluster_stats_all', cluster_stats_all, 'cluster_stats_all_neg', cluster_stats_all_neg, ...
                    'pvals_all', pvals_all, 'pvals_all_neg', pvals_all_neg, ...
                    'FWER', FWER, 'FWER_neg', FWER_neg);

                meta_data = add_meta_data_to_repetition_data('dataset', RP.data_set_base, ...
                                                 'map', RP.data_set_map, 'test', RP.test_type, ...
                                                 'test_components', strsplit(RP.test_name, '_'), ...
                                                 'omnibus', RP.omnibus_str, 'subject_number', RP.n_subs_subset, ...
                                                 'testing_code', RP.testing, 'test_type', RP.cluster_stat_type, ...
                                                 'rep_parameters', RP, 'date', datetime("today"), ...
                                                 'run_time', run_time);

                fprintf('###### Saving results in %s ######### \n', output_dir)
                save(output_dir, 'brain_data', 'meta_data');
        
            end

        end

    end

end