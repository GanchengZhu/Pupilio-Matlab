% Copyright (c) 2025 Hangzhou DeepGaze Science & Technology Ltd.
% All rights reserved.
%
% PROPRIETARY SOFTWARE LICENSE
% 
% This software and documentation are the proprietary property of Hangzhou 
% DeepGaze Science & Technology Ltd ("DeepGaze"). Unauthorized reproduction,
% distribution, or use is strictly prohibited without express written 
% permission from DeepGaze.
%
% LICENSE RESTRICTIONS:
% 1. This software is licensed for use only by authorized licensees of DeepGaze.
% 2. No redistribution or derivative works are permitted in any form.
% 3. No reverse engineering, decompilation, or disassembly is permitted.
% 4. No commercial use outside of DeepGaze-authorized applications is permitted.
%
% DISCLAIMER:
% THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER 
% EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL 
% DEEPGAZE OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
% OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING IN ANY WAY OUT OF
% THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% --------------------------------------------------------------------------
% CALIBRATION DEMONSTRATION
% 
% This file demonstrates the configuration and execution of the eye tracking
% calibration process using DeepGaze technology.
%
% Authors: 
%   Zhiguo Wang, Gancheng Zhu
%   Hangzhou DeepGaze Science & Technology Ltd.
%   Contact: mianwangming@gmail.com
% --------------------------------------------------------------------------


function [success, trackerHandler] = initializeTracker(config)
    %INITIALIZETRACKER Initialize eye tracker with full configuration
    %   [success, trackerHandler] = initializeTracker(config) initializes the
    %   eye tracking system using either provided configuration or default
    %   settings. Returns success flag and tracker handler structure.
    %
    %   Input:
    %       config - Optional DefaultConfig object. If empty, uses defaults.
    %   Output:
    %       success - Boolean indicating initialization success
    %       trackerHandler - Structure containing tracker state and resources
    
    success = false;

    % Get library paths
    [libFolder, ~, ~] = fileparts(mfilename('fullpath'));
    pathDll = fullfile(libFolder, 'lib', 'PupilioET.dll');
    pathHeader = fullfile(libFolder, 'lib', 'PupilioET.h');

    % Create Tracker Handler Structure
    trackerHandler = struct(...
        'config', config, ...
        'libName', 'PupilioET', ...
        'caliPoints', zeros(config.cali_mode*2, 1, 'single'), ...
        'isInitialized', false, ...
        'libPath', pathDll);
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    % Validate configuration
    if nargin < 1 || isempty(config)
        config = DefaultConfig();
        fprintf('Using default configuration\n');
    elseif ~isa(config, 'DefaultConfig')
        error('initializeTracker:invalidConfig', ...
              'Configuration must be a DefaultConfig object');
    end

    %% Library Loading Checks
    try
        % Check if library exists
        if ~exist(pathDll, 'file')
            error('initializeTracker:missingDLL', ...
                 'Library not found at: %s', pathDll);
        end
        
        % Load library only if not already loaded
        if ~libisloaded(LIB_NAME)
            [notfound, warnings] = loadlibrary(pathDll, pathHeader);

            if isempty(notfound)
                fprintf('[%s] Library loaded successfully\n', LIB_NAME);
            else
                fprintf(warnings);
            end
        end
    catch ME
        fprintf('[%s] Load error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;
    end
    
    %% Configuration Application
    try
        % Set tracking parameters
        calllib(LIB_NAME, 'mlif_pupil_io_set_look_ahead', config.look_ahead);
        calllib(LIB_NAME, 'mlif_pupil_io_set_eye_mode', config.active_eye);
        calllib(LIB_NAME, 'mlif_pupil_io_set_kappa_filter', config.enable_kappa_verification);
        
        % Handle calibration points
        caliPtr = libpointer('singlePtr', trackerHandler.caliPoints);
        calllib(LIB_NAME, 'mlif_pupil_io_set_cali_mode', config.cali_mode, caliPtr);
        trackerHandler.caliPoints = reshape(caliPtr.value, [2, config.cali_mode])';
        
        % Configure logging if enabled
        if config.enable_debug_logging
            logDir = ensureLogDirectoryExists(config.log_directory);
            calllib(LIB_NAME, 'mlif_pupil_io_set_log', 1, logDir);
            fprintf('Debug logging enabled at: %s\n', logDir);
        end
        
        fprintf('[%s] Configuration applied successfully\n', LIB_NAME);
    catch ME
        fprintf('[%s] Configuration error: %s\n', LIB_NAME, getReport(ME, 'basic'));
        return;
    end
    
    %% System Initialization
    try
        status = calllib(LIB_NAME, 'mlif_pupil_io_init');
        
        if status == SUCCESS_CODE
            trackerHandler.isInitialized = true;
            success = true;
            fprintf('[%s] System initialized successfully\n', LIB_NAME);
        else
            error('initializeTracker:initFailed', ...
                 'Initialization failed with code: %d', status);
        end
    catch ME
        fprintf('[%s] Initialization error: %s\n', LIB_NAME, getReport(ME, 'basic'));
    end
end

function logDir = ensureLogDirectoryExists(logDir)
    % Helper function to validate/create log directory
    if ~exist(logDir, 'dir')
        try
            mkdir(logDir);
            fprintf('Created log directory: %s\n', logDir);
        catch
            error('initializeTracker:logDirError', ...
                 'Could not create log directory: %s', logDir);
        end
    end
    logDir = fullfile(logDir); % Return absolute path
end
