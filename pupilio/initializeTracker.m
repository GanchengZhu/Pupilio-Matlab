function [success, trackerHandler] = initializeTracker(config)
    success = false;
    [libFolder, ~, ~] = fileparts(mfilename('fullpath'));
    pathDll    = fullfile(libFolder, 'lib', 'PupilioET.dll');
    pathHeader = fullfile(libFolder, 'lib', 'PupilioET.h');

    LIB_NAME     = 'PupilioET';
    SUCCESS_CODE = 0;

    CAMERA_MODE_SYNC_400 = 0;   % 400 Hz
    CAMERA_MODE_SYNC_200 = 3;   % 200 Hz
    HARDWARE_RATES       = [200, 400];   % sync_400 sensor capability

    % --- Config handling ---
    if nargin < 1 || isempty(config)
        config = DefaultConfig();
        fprintf('Using default configuration\n');
    elseif ~isa(config, 'DefaultConfig')
        error('initializeTracker:invalidConfig', ...
              'Configuration must be a DefaultConfig object');
    end

    trackerHandler = struct( ...
        'config',        config, ...
        'libName',       LIB_NAME, ...
        'caliPoints',    zeros(config.cali_mode*2, 1, 'single'), ...
        'isInitialized', false, ...
        'libPath',       pathDll);

    % ===== Load DLL =====
    try
        if ~exist(pathDll, 'file')
            error('initializeTracker:missingDLL', ...
                  'Library not found at: %s', pathDll);
        end
        if ~exist(pathHeader, 'file')
            error('initializeTracker:missingHeader', ...
                  'Header not found at: %s', pathHeader);
        end
        if ~libisloaded(LIB_NAME)
            loadlibrary(pathDll, pathHeader);
            fprintf('[%s] Library loaded successfully\n', LIB_NAME);
        end
    catch ME
        fprintf('[%s] Load error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;   % success stays false; caller sees real message via ME?
                  % (return without rethrow — see note below)
    end

    % ===== Configure parameters =====
    try
        calllib(LIB_NAME, 'pupil_io_set_look_ahead',  config.look_ahead);
        calllib(LIB_NAME, 'pupil_io_set_eye_mode',    config.active_eye);
        calllib(LIB_NAME, 'pupil_io_set_kappa_filter',config.enable_kappa_verification);

        caliPtr = libpointer('singlePtr', trackerHandler.caliPoints);
        calllib(LIB_NAME, 'pupil_io_set_cali_mode', config.cali_mode, caliPtr);
        trackerHandler.caliPoints = reshape(caliPtr.value, [2, config.cali_mode])';

        if config.enable_debug_logging
            logDir = ensureLogDirectoryExists(config.log_directory);
            calllib(LIB_NAME, 'pupil_io_set_log', 0, logDir);
            fprintf('Debug logging enabled at: %s\n', logDir);
        end
    catch ME
        fprintf('[%s] Configuration error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;   % success stays false
    end

    % ===== Initialize tracker first =====
    try
        status = calllib(LIB_NAME, 'pupil_io_init');
        if status ~= SUCCESS_CODE
            error('initializeTracker:initFailed', ...
                  'pupil_io_init failed with code: %d', status);
        end
        trackerHandler.isInitialized = true;

        % ---- Read current camera mode (now meaningful) ----
        [s_c, camera_mode, ~, ~] = getCameraMode(LIB_NAME);
        if ~s_c
            fprintf(['[PupilioET] Warning: could not determine camera mode. ' ...
                     'Keeping config.sampling_rate = %d Hz.\n'], ...
                    config.sampling_rate);
            success = true;
            fprintf('[%s] System initialized (camera mode unknown)\n', LIB_NAME);
            return;
        end
        fprintf('[PupilioET] Current camera mode: %d\n', camera_mode);

        % ---- Validate / auto-select sampling rate vs HARDWARE ----
        if config.sampling_rate == 0
            config.sampling_rate = HARDWARE_RATES(end);
            fprintf('[PupilioET] Auto-selected sampling rate: %d Hz\n', ...
                    config.sampling_rate);
        elseif ~ismember(config.sampling_rate, HARDWARE_RATES)
            fallback_rate = HARDWARE_RATES(end);
            fprintf(['[PupilioET] Warning: requested sampling rate %d Hz is ' ...
                     'not supported by this hardware. Falling back to %d Hz.\n'], ...
                    config.sampling_rate, fallback_rate);
            config.sampling_rate = fallback_rate;
        end
        trackerHandler.config.sampling_rate = config.sampling_rate;

        % ---- Resolve target mode ----
        if config.sampling_rate == 400
            target_mode = CAMERA_MODE_SYNC_400;
        elseif config.sampling_rate == 200
            target_mode = CAMERA_MODE_SYNC_200;
        else
            error('initializeTracker:unsupportedRate', ...
                  'Unsupported sampling_rate: %d', config.sampling_rate);
        end

        % ---- Switch only if needed ----
        if camera_mode ~= target_mode
            fprintf(['[PupilioET] Switching camera from mode %d to mode %d ' ...
                     '(%d Hz)...\n'], ...
                    camera_mode, target_mode, config.sampling_rate);

            prev_mode = camera_mode;

            % Release
            status = calllib(LIB_NAME, 'pupil_io_release');
            if status ~= SUCCESS_CODE
                error('initializeTracker:releaseFailed', ...
                      'Pupilio release failed with code: %d', status);
            end
            trackerHandler.isInitialized = false;

            % Set target mode (with best-effort rollback on failure)
            if ~setCameraMode(LIB_NAME, target_mode)
                try
                    calllib(LIB_NAME, 'pupil_io_init');
                    trackerHandler.isInitialized = true;
                catch
                    % swallow — original error is more useful
                end
                error('initializeTracker:setCameraModeFailed', ...
                      'Failed to set camera mode to %d Hz (mode %d)', ...
                      config.sampling_rate, target_mode);
            end

            % Re-init
            status = calllib(LIB_NAME, 'pupil_io_init');
            if status ~= SUCCESS_CODE
                error('initializeTracker:reinitFailed', ...
                      'Pupilio re-init failed with code: %d', status);
            end
            trackerHandler.isInitialized = true;

            % Refresh mode from device
            [~, camera_mode, ~, ~] = getCameraMode(LIB_NAME);
            fprintf(['[PupilioET] Changed sample rate to %d Hz ' ...
                     '(mode %d) and re-inited the tracker\n'], ...
                    config.sampling_rate, camera_mode);
        else
            fprintf('[PupilioET] Camera already in requested mode (%d Hz)\n', ...
                    config.sampling_rate);
        end

        % ---- Happy path ----
        success = true;
        fprintf('[%s] System initialized successfully at %d Hz\n', ...
                LIB_NAME, config.sampling_rate);

    catch ME
        fprintf('[%s] Initialization error: %s\n', ...
                LIB_NAME, getReport(ME, 'basic'));
        % success stays false; caller will see the real error if it
        % chooses to rethrow or inspect trackerHandler.isInitialized.
        % Uncomment the next line if you want the error to propagate:
        % rethrow(ME);
    end
end

% ------------------------------------------------------------------------
function logDir = ensureLogDirectoryExists(logDir)
    if ~exist(logDir, 'dir')
        try
            mkdir(logDir);
            fprintf('Created log directory: %s\n', logDir);
        catch
            error('initializeTracker:logDirError', ...
                  'Could not create log directory: %s', logDir);
        end
    end
    logDir = fullfile(logDir);
end