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
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;


    if nargin < 1 || isempty(config)
        config = DefaultConfig();
        fprintf('Using default configuration\n');
    elseif ~isa(config, 'DefaultConfig')
        error('initializeTracker:invalidConfig', 'Configuration must be a DefaultConfig object');
    end

    try
        if ~exist(pathDll, 'file')
            error('initializeTracker:missingDLL', 'Library not found at: %s', pathDll);
        end
        if ~libisloaded(LIB_NAME)
            [notfound, warnings] = loadlibrary(pathDll, pathHeader);
            if isempty(notfound)
                fprintf('[%s] Library loaded successfully\n', LIB_NAME);
            else
                fprintf(warnings);
            end

                fprintf('===== Available functions in DLL =====\n');
    funcs = libfunctions(LIB_NAME);
    for i = 1:length(funcs)
        fprintf('  %s\n', funcs{i});
    end
    fprintf('=====================================\n');


    
        end
    catch ME
        fprintf('[%s] Load error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;
    end
    
    try
        calllib(LIB_NAME, 'mlif_pupil_io_set_look_ahead', config.look_ahead);
        calllib(LIB_NAME, 'mlif_pupil_io_set_eye_mode', config.active_eye);
        calllib(LIB_NAME, 'mlif_pupil_io_set_kappa_filter', config.enable_kappa_verification);
        caliPtr = libpointer('singlePtr', trackerHandler.caliPoints);
        calllib(LIB_NAME, 'mlif_pupil_io_set_cali_mode', config.cali_mode, caliPtr);
        trackerHandler.caliPoints = reshape(caliPtr.value, [2, config.cali_mode])';
        if config.enable_debug_logging
            logDir = ensureLogDirectoryExists(config.log_directory);
            calllib(LIB_NAME, 'mlif_pupil_io_set_log', 1, logDir);
            fprintf('Debug logging enabled at: %s\n', logDir);
        end
    catch ME
        fprintf('[%s] Configuration error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;
    end
        
    try
        status = calllib(LIB_NAME, 'mlif_pupil_io_init');
        if status == SUCCESS_CODE
            trackerHandler.isInitialized = true;
            
            % ---------- 获取相机模式 ----------
            modePtr = libpointer('int32Ptr', int32(0));
            leftPtr = libpointer('int32Ptr', int32([0, 0, 0, 0]));
            rightPtr = libpointer('int32Ptr', int32([0, 0, 0, 0]));
            
            s_c = (calllib(LIB_NAME, 'mlif_pupil_io_get_camera_mode', modePtr, leftPtr, rightPtr) == SUCCESS_CODE);
            
            if s_c
                camera_mode = modePtr.Value;
                trackerHandler.camera_mode = camera_mode;
                
                % 确定支持的采样率
                if camera_mode == 0  % SYNC_400
                    supported_sr = [200, 400];
                else
                    supported_sr = [200];
                end
                
                % 验证采样率
                if config.sampling_rate == 0
                    config.sampling_rate = supported_sr(end);
                else
                    if ~ismember(config.sampling_rate, supported_sr)
                        fallback_rate = supported_sr(end);
                        fprintf('The requested sampling rate %d Hz is not supported. Automatically degrading to %d Hz.\n', ...
                            config.sampling_rate, fallback_rate);
                        config.sampling_rate = fallback_rate;
                    end
                end
                
                % ===== SYNC_400 + 200Hz：需要重新初始化 =====
                if camera_mode == 0 && config.sampling_rate == 200
                    fprintf('SYNC_400 detected with 200Hz request. Re-initializing...\n');
                    
                    % 释放
                    release_status = calllib(LIB_NAME, 'mlif_pupil_io_release');
                    if release_status ~= SUCCESS_CODE
                        fprintf('Warning: Release returned %d\n', release_status);
                    end
                    fprintf('Released\n');
                    
                    pause(0.1);
                    
                    % 直接设置模式（不通过 setCameraMode 函数）
                    setPtr = libpointer('int32Ptr', int32(3));
                    set_status = calllib(LIB_NAME, 'mlif_pupil_io_set_camera_mode', setPtr);
                    clear setPtr;
                    
                    if set_status ~= SUCCESS_CODE
                        fprintf('Warning: set_camera_mode returned %d\n', set_status);
                    end
                    fprintf('Set camera mode to 3 (SYNC_200)\n');
                    
                    pause(0.1);
                    
                    % 重新初始化
                    status2 = calllib(LIB_NAME, 'mlif_pupil_io_init');
                    if status2 ~= SUCCESS_CODE
                        error('Re-initialization failed with code: %d', status2);
                    end
                    fprintf('Re-initialized successfully\n');
                    
                    % 更新相机模式
                    modePtr2 = libpointer('int32Ptr', int32(0));
                    leftPtr2 = libpointer('int32Ptr', int32([0, 0, 0, 0]));
                    rightPtr2 = libpointer('int32Ptr', int32([0, 0, 0, 0]));
                    
                    if calllib(LIB_NAME, 'mlif_pupil_io_get_camera_mode', modePtr2, leftPtr2, rightPtr2) == SUCCESS_CODE
                        trackerHandler.camera_mode = modePtr2.Value;
                        fprintf('Verified camera mode: %d\n', trackerHandler.camera_mode);
                    end
                    clear modePtr2 leftPtr2 rightPtr2;
                end
                
                clear modePtr leftPtr rightPtr;
            end
            % ------------------------------------------
            
            success = true;
            fprintf('[%s] System initialized successfully\n', LIB_NAME);
        else
            error('initializeTracker:initFailed', 'Initialization failed with code: %d', status);
        end
    catch ME
        fprintf('[%s] Initialization error: %s\n', LIB_NAME, getReport(ME, 'basic'));
    end


    % try
    %     status = calllib(LIB_NAME, 'mlif_pupil_io_init');
    %     if status == SUCCESS_CODE
    %         trackerHandler.isInitialized = true;
    % 
    %         [s_c, camera_mode, ~, ~] = getCameraMode(trackerHandler);
    %         if s_c
    %             if camera_mode == 0
    %                 supported_sr = [200, 400];
    %             else
    %                 supported_sr = [200];
    %             end
    % 
    %             if config.sampling_rate == 0
    %                 config.sampling_rate = supported_sr(end);
    %             else
    %                 if ~ismember(config.sampling_rate, supported_sr)
    %                     fallback_rate = supported_sr(end);
    %                     fprintf('The requested sampling rate %d Hz is not supported. Automatically degrading to %d Hz.\n', config.sampling_rate, fallback_rate);
    %                     config.sampling_rate = fallback_rate;
    %                 end
    %             end
    % 
    %             if camera_mode == 0 && config.sampling_rate == 200
    %                 calllib(LIB_NAME, 'mlif_pupil_io_release');
    %                 setCameraMode(trackerHandler, 3);
    %                 status2 = calllib(LIB_NAME, 'mlif_pupil_io_init');
    %                 if status2 ~= SUCCESS_CODE
    %                     error('Re-initialization failed');
    %                 end
    %                 fprintf('Changed sample rate to 200 Hz and re-inited the tracker\n');
    %             end
    %         end
    % 
    %         success = true;
    %         fprintf('[%s] System initialized successfully\n', LIB_NAME);
    %     else
    %         error('initializeTracker:initFailed', 'Initialization failed with code: %d', status);
    %     end
    % catch ME
    %     fprintf('[%s] Initialization error: %s\n', LIB_NAME, getReport(ME, 'basic'));
    % end
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
