function [success, trackerHandler] = releaseTracker(trackerHandler)
%RELEASETRACKER Release all tracker resources and unload library
%   [success, trackerHandler] = releaseTracker(trackerHandler) properly releases 
%   resources, clears MATLAB objects referencing the library, and unloads the 
%   library. Returns true if successful, and the updated tracker handle.

    success = false;
    
    % Validate input
    if nargin < 1 || isempty(trackerHandler) || ~isfield(trackerHandler, 'libName')
        error('releaseTracker:invalidInput', 'Invalid tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    MAX_ATTEMPTS = 3;
    RETRY_DELAY = 0.5;
    
    % Early return if library not loaded
    if ~libisloaded(LIB_NAME)
        fprintf('[%s] Library not loaded - nothing to release\n', LIB_NAME);
        success = true;
        return;
    end
    
    %% Release tracker resources
    pause(1.0); % Allow recording to stop
    
    for attempt = 1:MAX_ATTEMPTS
        try
            releaseStatus = calllib(LIB_NAME, 'pupil_io_release');
            if releaseStatus == 0
                fprintf('[%s] Successfully released internal resources\n', LIB_NAME);
                break;
            else
                fprintf('[%s] Release failed with code %d (attempt %d)\n', ...
                        LIB_NAME, releaseStatus, attempt);
            end
        catch ME
            fprintf('[%s] Release error on attempt %d: %s\n', ...
                    LIB_NAME, attempt, ME.message);
        end
        if attempt < MAX_ATTEMPTS
            pause(RETRY_DELAY);
        end
    end

    %% Clear outstanding MATLAB objects referencing the library
    fprintf('[%s] Clearing outstanding MATLAB objects...\n', LIB_NAME);
    trackerHandler = clearOutstandingObjects(trackerHandler, LIB_NAME);
    
    %% Unload library
    try
        unloadlibrary(LIB_NAME);
        fprintf('[%s] Library unloaded successfully\n', LIB_NAME);
        
        pause(1.0);
        
        % Update tracker state
        if isfield(trackerHandler, 'isInitialized')
            trackerHandler.isInitialized = false;
        end
        
        success = true;
        
    catch ME
        fprintf('[%s] Unload error: %s\n', LIB_NAME, getReport(ME, 'extended'));
        
        % Emergency cleanup attempt
        try
            if libisloaded(LIB_NAME)
                evalin('caller', 'clear(''libpointer'', ''libstruct'')');
                unloadlibrary(LIB_NAME);
                fprintf('[%s] Emergency unload succeeded after clearing objects\n', LIB_NAME);
                success = true;
            end
        catch
            fprintf('[%s] FATAL: Library could not be unloaded. Please restart MATLAB.\n', LIB_NAME);
        end
    end
end

%% Helper function
function obj = clearOutstandingObjects(obj, libName)
% Recursively clear all libpointer/libstruct fields from a struct or cell
    
    if isstruct(obj)
        fnames = fieldnames(obj);
        for i = 1:length(fnames)
            field = fnames{i};
            value = obj.(field);
            if isa(value, 'libpointer') || isa(value, 'libstruct')
                fprintf('[%s] Clearing field ''%s''\n', libName, field);
                obj.(field) = [];
            elseif isstruct(value) || iscell(value)
                obj.(field) = clearOutstandingObjects(value, libName);
            end
        end
    elseif iscell(obj)
        for i = 1:numel(obj)
            obj{i} = clearOutstandingObjects(obj{i}, libName);
        end
    end
end
