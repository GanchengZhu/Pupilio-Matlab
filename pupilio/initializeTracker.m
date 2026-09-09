function [success, trackerHandler] = initializeTracker(config)
    success = false;
    [libFolder, ~, ~] = fileparts(mfilename('fullpath'));
    pathDll = fullfile(libFolder, 'lib', 'PupilioET.dll');
    pathHeader = fullfile(libFolder, 'lib', 'PupilioET.h');
    
    trackerHandler = struct(...
        'config', config, ...
        'libName', 'PupilioET', ...
        'caliPoints', zeros(config.cali_mode*2, 1, 'single'), ...
        'isInitialized', false, ...
        'libPath', pathDll);
    LIB_NAME = 'PupilioET';
    SUCCESS_CODE = 0;
    
    if nargin < 1 || isempty(config)
        config = DefaultConfig();
        fprintf('Using default configuration\n');
    elseif ~isa(config, 'DefaultConfig')
        error('initializeTracker:invalidConfig', 'Configuration must be a DefaultConfig object');
    end

    % ===== Load DLL =====
    try
        if ~exist(pathDll, 'file')
            error('initializeTracker:missingDLL', 'Library not found at: %s', pathDll);
        end
        
        if ~exist(pathHeader, 'file')
            error('initializeTracker:missingHeader', 'Header not found at: %s', pathHeader);
        end
        
        if ~libisloaded(LIB_NAME)
            loadlibrary(pathDll, pathHeader);
            fprintf('[%s] Library loaded successfully\n', LIB_NAME);
        end
    catch ME
        fprintf('[%s] Load error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;
    end
    
    % ===== Configure parameters =====
    try
        calllib(LIB_NAME, 'pupil_io_set_look_ahead', config.look_ahead);
        calllib(LIB_NAME, 'pupil_io_set_eye_mode', config.active_eye);
        calllib(LIB_NAME, 'pupil_io_set_kappa_filter', config.enable_kappa_verification);
        caliPtr = libpointer('singlePtr', trackerHandler.caliPoints);
        calllib(LIB_NAME, 'pupil_io_set_cali_mode', config.cali_mode, caliPtr);
        trackerHandler.caliPoints = reshape(caliPtr.value, [2, config.cali_mode])';
        if config.enable_debug_logging
            logDir = ensureLogDirectoryExists(config.log_directory);
            calllib(LIB_NAME, 'pupil_io_set_log', 1, logDir);
            fprintf('Debug logging enabled at: %s\n', logDir);
        end
    catch ME
        fprintf('[%s] Configuration error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;
    end
    
    % ===== Initialize tracker first =====
    try
        status = calllib(LIB_NAME, 'pupil_io_init');
        if status ~= SUCCESS_CODE
            error('initializeTracker:initFailed', 'Pupilio init failed with code: %d', status);
        end
        trackerHandler.isInitialized = true;
        
        % ===== Get camera mode (after initialization) =====
        [s_c, camera_mode, ~, ~] = getCameraMode(LIB_NAME);
        
        if ~s_c
            fprintf('Warning: Could not determine camera mode. Using default 200 Hz.\n');
            config.sampling_rate = 200;
            success = true;
            fprintf('[%s] System initialized successfully at %d Hz\n', LIB_NAME, config.sampling_rate);
            return;
        end
        
        fprintf('[PupilioET] Current camera mode: %d\n', camera_mode);
        
        % ===== Determine supported sampling rates =====
        % camera_mode == 0 means CAMERA_MODE_SYNC_400 (supports 200 and 400 Hz)
        if camera_mode == 0
            supported_sr = [200, 400];
        else
            supported_sr = [200];
        end
        
        % ===== Validate or auto-select sampling rate =====
        if config.sampling_rate == 0
            % Auto-select highest supported rate
            config.sampling_rate = supported_sr(end);
            fprintf('Auto-selected sampling rate: %d Hz\n', config.sampling_rate);
        elseif ~ismember(config.sampling_rate, supported_sr)
            % Requested rate not supported - fallback to highest
            fallback_rate = supported_sr(end);
            fprintf('Warning: The requested sampling rate %d Hz is not supported. Automatically degrading to %d Hz.\n', ...
                config.sampling_rate, fallback_rate);
            config.sampling_rate = fallback_rate;
        end
        
        % ===== Handle camera mode change for 200 Hz on 400 Hz camera =====
        % If we have a sync_400 camera and want to run at 200 Hz, we need to:
        % release, set_camera_mode, then init the tracker again
        if camera_mode == 0 && config.sampling_rate == 200
            fprintf('Downgrading from 400 Hz mode to 200 Hz mode...\n');
            
            % Release the tracker
            status = calllib(LIB_NAME, 'pupil_io_release');
            if status ~= SUCCESS_CODE
                error('initializeTracker:releaseFailed', 'Pupilio release failed with code: %d', status);
            end
            fprintf('Tracker released successfully\n');
            
            % Set camera mode to 200 Hz (mode 3 according to Python)
            success_set = setCameraMode(LIB_NAME, 3);  % CAMERA_MODE_SYNC_200 = 3
            if ~success_set
                error('initializeTracker:setCameraModeFailed', 'Failed to set camera mode to 200 Hz');
            end
            
            % Re-initialize tracker
            status = calllib(LIB_NAME, 'pupil_io_init');
            if status ~= SUCCESS_CODE
                error('initializeTracker:reinitFailed', 'Pupilio re-init failed with code: %d', status);
            end
            
            fprintf('Changed sample rate to 200 Hz and re-inited the tracker\n');
            
            % Update camera mode after re-initialization
            [s_c, camera_mode, ~, ~] = getCameraMode(LIB_NAME);
            fprintf('New camera mode: %d\n', camera_mode);
            
        elseif camera_mode == 0 && config.sampling_rate == 400
            % Already in 400 Hz mode, nothing to do
            % fprintf('Running at 400 Hz\n');
        elseif camera_mode ~= 0 && config.sampling_rate == 200
            % Already in 200 Hz mode, nothing to do
            % fprintf('Running at 200 Hz\n');
        end
        
        success = true;
        fprintf('[%s] System initialized successfully at %d Hz\n', LIB_NAME, config.sampling_rate);
        
    catch ME
        fprintf('[%s] Initialization error: %s\n', LIB_NAME, getReport(ME, 'basic'));
    end
end

function logDir = ensureLogDirectoryExists(logDir)
    if ~exist(logDir, 'dir')
        try
            mkdir(logDir);
            fprintf('Created log directory: %s\n', logDir);
        catch
            error('initializeTracker:logDirError', 'Could not create log directory: %s', logDir);
        end
    end
    logDir = fullfile(logDir);
end
