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


function [success, status] = startSampling(trackerHandler)
    %STARTSAMPLING Initiates eye tracking data acquisition using tracker handler
    %   [success, status] = startSampling(trackerHandler)
    %
    % Inputs:
    %   trackerHandler - Struct returned by initializeTracker() containing:
    %       .libName      : Library name ('PupilioET')
    %       .isInitialized: Boolean indicating tracker state
    %       .config       : Configuration object
    %
    % Returns:
    %   success: Logical true if sampling started successfully
    %   status : Raw status code from DLL (0 = success)

    %% Input Validation
    if nargin < 1 || isempty(trackerHandler)
        error('Tracker handler required. Call initializeTracker() first.');
    end
    
    if ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Tracker not initialized. Check initializeTracker() output.');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;  % Assuming 0 indicates success

    %% Library State Check
    if ~libisloaded(LIB_NAME)
        error('%s library not loaded. System may have been released.', LIB_NAME);
    end

    %% Execute Sampling Command
    try
        % 1. Start sampling via DLL
        status = calllib(LIB_NAME, 'mlif_pupil_io_start_sampling');
        
        % 2. Interpret status code
        success = (status == SUCCESS_CODE);
        
        % 3. Update handler state if successful
        if success
            trackerHandler.isSampling = true;  % Add new state field
            fprintf('[%s] Sampling started (Mode: %d-point calibration)\n', ...
                   LIB_NAME, trackerHandler.config.cali_mode);
        else
            warning('[%s] Sampling start failed (Status: %d)', LIB_NAME, status);
            interpretStatus(status, trackerHandler.config);  % Enhanced helper
        end
        
    catch ME
        success = false;
        status = -1;  % Custom error code
        fprintf('[%s] Critical sampling error: %s\n', LIB_NAME, ME.message);
        
        % Attempt recovery if this is a communication error
        if contains(ME.message, 'communication')
            fprintf('Attempting to reinitialize...\n');
            [success, trackerHandler] = initializeTracker(trackerHandler.config);
            if success
                [success, status] = startSampling(trackerHandler);  % Retry
            end
        end
    end
end

%% Local Helper Function
function interpretStatus(status, config)
    %INTERPRETSTATUS Provides detailed error messages based on status codes
    switch status
        case -1
            msg = 'Communication timeout';
        case 1
            msg = 'Calibration required';
            if config.enable_debug_logging
                fprintf('Run recalibrate() with mode %d\n', config.cali_mode);
            end
        case 2
            msg = 'Hardware not detected';
        otherwise
            msg = 'Unknown error';
    end
    fprintf('SYSTEM ERROR: %s (Code: %d)\n', msg, status);
end