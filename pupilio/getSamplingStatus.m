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


function [success, isSampling] = getSamplingStatus(trackerHandler)
%GETSAMPLINGSTATUS Check if the eye tracker is currently sampling data
%   [success, isSampling] = getSamplingStatus(trackerHandler)
%
%   Input:
%       trackerHandler - Struct returned by initializeTracker
%   Output:
%       success      - True if status was successfully obtained (logical)
%       isSampling   - True if tracker is currently sampling (logical)
%
%   Example:
%       [success, sampling] = getSamplingStatus(tracker);
%       if success && sampling
%           disp('Tracker is actively sampling eye data');
%       end

    % Initialize outputs
    success = false;
    isSampling = false;
    
    % Validate input
    if nargin < 1 || ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0; % Assuming 0 indicates success
    
    try
        % Prepare output buffer (MATLAB's logical maps to C++ bool)
        samplingStatus = false;
        statusPtr = libpointer('boolPtr', samplingStatus);
        
        % Call the DLL function
        returnStatus = calllib(LIB_NAME, 'mlif_pupil_io_sampling_status', statusPtr);
        
        % Process results
        if returnStatus == SUCCESS_CODE
            isSampling = statusPtr.Value;
            success = true;
        else
            warning('Failed to get sampling status (Error: %d)', returnStatus);
        end
        
        % Clean up pointer
        clear statusPtr;
        
    catch ME
        fprintf('Error checking sampling status: %s\n', ME.message);
        % Pointer is automatically cleared when function exits
    end
end