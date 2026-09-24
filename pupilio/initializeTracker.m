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

    % Determine the number of calibration targets to allocate.
    % Mirrors the Python binding: cali_mode = 0 (NO_CALI) gets a 2-point-sized
    % placeholder, because the native call ignores the buffer when mode = 0 but
    % still requires a valid, non-empty pointer.
    if config.cali_mode == 0
        caliPointCount = 2;
    else
        caliPointCount = double(config.cali_mode);
    end

    trackerHandler = struct( ...
        'config',        config, ...
        'libName',       LIB_NAME, ...
        'caliPoints',    zeros(caliPointCount * 2, 1, 'single'), ...
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
        return;
    end

    % ===== Print native library version =====
    try
        libFns = libfunctions(LIB_NAME);
        if any(strcmp(libFns, 'pupil_io_get_version'))
            versionStr = calllib(LIB_NAME, 'pupil_io_get_version');
            if ~isempty(versionStr)
                fprintf('[PupilioET] Native Pupilio Version: %s\n', versionStr);
            end
        end
    catch ME
        fprintf('[%s] Could not query version: %s\n', LIB_NAME, ME.message);
    end

    % ===== Configure parameters =====
    try
        calllib(LIB_NAME, 'pupil_io_set_look_ahead',  config.look_ahead);
        calllib(LIB_NAME, 'pupil_io_set_eye_mode',    config.active_eye);
        calllib(LIB_NAME, 'pupil_io_set_kappa_filter',config.enable_kappa_verification);

        caliPtr = libpointer('singlePtr', trackerHandler.caliPoints);
        calllib(LIB_NAME, 'pupil_io_set_cali_mode', config.cali_mode, caliPtr);
        trackerHandler.caliPoints = reshape(caliPtr.value, [2, caliPointCount])';

        if config.enable_debug_logging
            logDir = ensureLogDirectoryExists(config.log_directory);
            calllib(LIB_NAME, 'pupil_io_set_log', 0, logDir);
            fprintf('Debug logging enabled at: %s\n', logDir);
        end
    catch ME
        fprintf('[%s] Configuration error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;
    end

    % ===== Initialize tracker first =====
    % Camera mode is only meaningful AFTER pupil_io_init() has succeeded, so
    % the whole rate/mode-resolution block must run after init, not before.
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

        % ---- Apply rate; if 400 Hz fails, fall back to 200 Hz ----
        % Mirrors the Python implementation: on hardware that only supports
        % 200 Hz, setCameraMode(CAMERA_MODE_SYNC_400) is unavailable, so we
        % retry once at 200 Hz and accept the device's native mode.
        while true
            try
                % ---- Resolve target mode ----
                if config.sampling_rate == 400
                    target_mode = CAMERA_MODE_SYNC_400;
                elseif config.sampling_rate == 200
                    target_mode = CAMERA_MODE_SYNC_200;
                else
                    error('initializeTracker:unsupportedRate', ...
                          'Unsupported sampling_rate: %d', config.sampling_rate);
                end

                % ---- If device is already in the desired mode, accept it ----
                % On 200-Hz-only hardware, setCameraMode() is a no-op or fails,
                % so we must not attempt it when the device is already at 200 Hz.
                if trackerHandler.isInitialized && camera_mode == target_mode
                    fprintf(['[PupilioET] Camera already in requested mode ' ...
                             '(%d Hz) - no switch needed\n'], config.sampling_rate);
                    break;
                end

                % ---- Switch ----
                fprintf(['[PupilioET] Switching camera from mode %d to mode %d ' ...
                         '(%d Hz)...\n'], ...
                        camera_mode, target_mode, config.sampling_rate);

                % Release (only if currently initialized)
                if trackerHandler.isInitialized
                    status = calllib(LIB_NAME, 'pupil_io_release');
                    if status ~= SUCCESS_CODE
                        error('initializeTracker:releaseFailed', ...
                              'Pupilio release failed with code: %d', status);
                    end
                    trackerHandler.isInitialized = false;
                end

                % Set target mode
                if ~setCameraMode(LIB_NAME, target_mode)
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
                break;

            catch ME
                % ---- Best-effort cleanup ----
                try
                    if trackerHandler.isInitialized
                        calllib(LIB_NAME, 'pupil_io_release');
                        trackerHandler.isInitialized = false;
                    end
                catch
                    % swallow
                end

                if config.sampling_rate == 400
                    fprintf(['[PupilioET] 400 Hz initialization failed: %s. ' ...
                             'Falling back to 200 Hz.\n'], ME.message);
                    config.sampling_rate = 200;
                    trackerHandler.config.sampling_rate = 200;

                    % ---- Recover device to a known-good state ----
                    % After a failed setCameraMode, the device is in an
                    % undefined state. Re-init so getCameraMode reports the
                    % true hardware default.
                    try
                        status = calllib(LIB_NAME, 'pupil_io_init');
                        if status == SUCCESS_CODE
                            trackerHandler.isInitialized = true;
                            [~, camera_mode, ~, ~] = getCameraMode(LIB_NAME);
                            fprintf(['[PupilioET] Recovered device after 400 Hz ' ...
                                     'failure; current camera mode: %d\n'], ...
                                    camera_mode);

                            % On 200-Hz-only hardware, setCameraMode is not
                            % usable - the device already defaults to 200 Hz.
                            % Accept it and skip the switch entirely.
                            if camera_mode == CAMERA_MODE_SYNC_200
                                fprintf(['[PupilioET] Device is already in native ' ...
                                         '200 Hz mode; accepting without ' ...
                                         'setCameraMode()\n']);
                                break;
                            end
                        end
                    catch recoverME
                        fprintf('[PupilioET] Recovery re-init failed: %s\n', ...
                                recoverME.message);
                    end

                    continue;   % retry the loop at 200 Hz
                end

                rethrow(ME);
            end
        end

        % ---- Happy path ----
        success = true;
        fprintf('[%s] System initialized successfully at %d Hz\n', ...
                LIB_NAME, config.sampling_rate);

    catch ME
        fprintf('[%s] Initialization error: %s\n', ...
                LIB_NAME, getReport(ME, 'basic'));
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

