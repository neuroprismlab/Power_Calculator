function [data_set_name, data_set_base, data_set_map] = get_data_set_name(Dataset)
    
    data_set_base = Dataset.study_info.dataset;
    data_set_map =  Dataset.study_info.map;
    data_set_name = strcat(Dataset.study_info.dataset, '_', Dataset.study_info.map);
    
end