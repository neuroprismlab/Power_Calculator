function Params = create_output_directory(Params)

    if ~exist(Params.save_directory, 'dir') % Check if the directory does not exist
        mkdir(Params.save_directory);       % Create the directory
    end

    Params.save_directory = [Params.save_directory, Params.data_set, '/'];

    if ~exist(Params.save_directory, 'dir') % Check if the directory does not exist
        mkdir(Params.save_directory);       % Create the directory
    end

end