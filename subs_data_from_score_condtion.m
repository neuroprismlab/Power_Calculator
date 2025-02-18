function [X, Y, RP] = subs_data_from_score_condition(RP,  TestData, BrainData, test_name)
    
    test_score_set = get_test_score_set(TestData);
    RP.test_name = test_name;

    switch RP.test_type

        case 't2'
            
            %% FIX THIS - match subject indexing is NOT CORRECT - GET SUBJECT IDS before INDEX
            %% NOT CORRECT FABRICIO - FIX IT - DON'T FORGET 
            ref_cond = TestData.reference_condition;
    
            index_cond_1 = strcmp(TestData.score, test_score_set{1});
            index_cond_2 = strcmp(TestData.score, test_score_set{2});
    
            sub_ids_cond1 = BrainData.(ref_cond).sub_ids(index_cond_1);
            sub_ids_cond2 = BrainData.(ref_cond).sub_ids(index_cond_2);
            
            data_index_cond1 = ismember(BrainData.(ref_cond).sub_ids, sub_ids_cond1);
            data_index_cond2 = ismember(BrainData.(ref_cond).sub_ids, sub_ids_cond2);
    
            Yc1 = BrainData.(ref_cond).data(:, data_index_cond1);
            Yc2 = BrainData.(ref_cond).data(:, data_index_cond2);
        
            Y = [Yc1, Yc2];
    
             % Get the number of subjects for each condition
            n_subs_1 = length(data_index_cond1);
            n_subs_2 = length(data_index_cond2);

            X = zeros(n_subs_1 + n_subs_2, 2);
            X(1:n_subs_1, 1) = 1;                   % Condition 1
            X(n_subs_1+1:n_subs_1+n_subs_2, 2) = 1; % Condition 2

            RP.n_subs_1 = n_subs_1;
            RP.n_subs_2 = n_subs_2;
            RP.n_subs = n_subs_1 + n_subs_2;

        case 'r'

            ref_cond = TestData.reference_condition;
            
            % Remove nan values and extract Y
            valid_idx = ~isnan(TestData.score);
            
            X = TestData.score(valid_idx);
            
            % Retrieve X values from BrainData
            sub_ids = TestData.sub_ids(valid_idx);
            data_indexes = ismember(BrainData.(ref_cond).sub_ids, sub_ids);
            Y = BrainData.(ref_cond).data(:, data_indexes);      
              
            % Get sub numbers
            RP.n_subs_1 = length(sub_ids);
            RP.n_subs_2 = length(sub_ids);
            RP.n_subs = length(sub_ids);

    end 


end
