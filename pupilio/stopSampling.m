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


function success = stopSampling(trackerHandler)
% STOP_SAMPLING - Stops eye tracking data sampling
%
% Input:
%   trackerHandler - Struct containing libName (DLL name)
%
% Output:
%   success - Logical indicating if sampling was stopped successfully
%
% Example:
%   tracker = struct('libName', 'PUPILIO_DLL');
%   success = pupil_io_stop_sampling(tracker);

    % Default return value
    success = false;
    LIB_NAME = trackerHandler.libName;

    % Check input
    if ~isfield(trackerHandler, 'libName')
        error('trackerHandler must contain libName field');
    end
    
    % Ensure DLL is loaded
    if ~libisloaded(trackerHandler.libName)
        warning('DLL not loaded: %s', trackerHandler.libName);
        return;
    end
    
    % Call the function
    try
        result = calllib(trackerHandler.libName, 'mlif_pupil_io_stop_sampling');
        success = (result == 0); % Assuming 0 means success
        if success
            trackerHandler.isSampling = false;  % Add new state field
            fprintf('[%s] Sampling stopped (Mode: %d-point calibration)\n', ...
                   LIB_NAME, trackerHandler.config.cali_mode);
        end
    catch ME
        warning('Failed to stop sampling: %s', ME.message);
    end
end