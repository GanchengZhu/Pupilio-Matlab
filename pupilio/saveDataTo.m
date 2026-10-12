function success = saveDataTo(trackerHandler, filePath)
%SAVEDATATO Save recorded eye tracking data to file
%   success = saveDataTo(trackerHandler, filePath)
%
%   Input:
%       trackerHandler - Struct returned by initializeTracker
%       filePath     - Full path for output data file (string/char)
%   Output:
%       success      - True if data was successfully saved (logical)
%
%   Example:
%       % Save to timestamped file in data directory
%       outputFile = fullfile('data', sprintf('eyedata_%s.dat', datestr(now,'yyyymmdd_HHMMSS')));
%       success = saveDataTo(tracker, outputFile);
%       if success
%           disp(['Data saved to: ' outputFile]);
%       end

    % Initialize output
    success = false;
    
    % Validate input
    if nargin < 2 || isempty(filePath)
        error('Both trackerHandler and filePath must be provided');
    end
    
    if ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    % Use libName from trackerHandler
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        % Verify directory exists or create it
        [fileDir, fileName, fileExt] = fileparts(filePath);
        if ~isempty(fileDir)
            if ~exist(fileDir, 'dir')
                fprintf('Creating output directory: %s\n', fileDir);
                mkdir(fileDir);
                % Verify creation was successful
                if ~exist(fileDir, 'dir')
                    error('Failed to create directory: %s', fileDir);
                end
            end
        end
        
        % Build full file path with extension if needed
        if isempty(fileExt)
            filePath = fullfile(fileDir, [fileName, '.csv']);
            fprintf('No extension provided, defaulting to .csv: %s\n', filePath);
        end
        
        % Convert to char array and ensure null termination for DLL
        filePathNull = [char(filePath), char(0)];
        
        % Check if DLL is loaded
        if ~libisloaded(LIB_NAME)
            error('Library %s is not loaded', LIB_NAME);
        end
        
        % Call the DLL function
        % fprintf('Saving data to: %s\n', filePath);
        status = calllib(LIB_NAME, 'pupil_io_save_data_to', filePathNull);
        
        % Check result
        if status == SUCCESS_CODE
            success = true;
            
            % Verify file was actually created (check original path, not null-terminated)
            if exist(filePath, 'file')
                fprintf('[PupilioET] Data successfully saved to: %s\n', filePath);
            else
                warning('[PupilioET] Command succeeded (status %d) but output file not found at: %s', status, filePath);
                % The file might be saved with a different name or location
                % Try to find recently created files in the directory
                if ~isempty(fileDir) && exist(fileDir, 'dir')
                    files = dir(fileDir);
                    fprintf('Files in directory:\n');
                    for i = 1:length(files)
                        if ~files(i).isdir
                            fprintf('  - %s (modified: %s)\n', files(i).name, datestr(files(i).datenum));
                        end
                    end
                end
                success = false;
            end
        else
            fprintf('Data save failed with status: %d\n', status);
            
            % Provide more detailed error information
            if status == -1
                fprintf('Error: Invalid file path or unable to create file\n');
            elseif status == -2
                fprintf('Error: No data available to save (sampling not started or no data collected)\n');
            elseif status == -3
                fprintf('Error: File write error (permission denied or disk full)\n');
            else
                fprintf('Error: Unknown error code %d\n', status);
            end
        end
        
    catch ME
        fprintf('Error saving eye tracking data: %s\n', ME.message);
        fprintf('Error details:\n');
        fprintf('  - File path: %s\n', filePath);
        fprintf('  - Library: %s\n', LIB_NAME);
        
        % Provide specific suggestions for common errors
        if contains(ME.message, 'permission') || contains(ME.message, 'Permission')
            fprintf('> Check write permissions for target directory: %s\n', fileDir);
        elseif contains(ME.message, 'invalid path') || contains(ME.message, 'Invalid')
            fprintf('> Ensure path uses correct filesystem separators\n');
            fprintf('> Try using fullfile() to build path: %s\n', fullfile(fileDir, fileName));
        elseif contains(ME.message, 'loaded')
            fprintf('> Library %s is not loaded. Please initialize tracker first.\n', LIB_NAME);
        end
    end
end