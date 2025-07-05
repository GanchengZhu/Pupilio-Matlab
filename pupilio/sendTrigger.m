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


function success = sendTrigger(trackerHandler, triggerCode)
%SENDTRIGGER Send a trigger code to the eye tracking system
%   success = sendTrigger(trackerHandler, triggerCode)
%
%   Input:
%       trackerHandler - Struct returned by initializePupilioinitializeTracker
%       triggerCode  - Unsigned 64-bit integer trigger code (0-256)
%   Output:
%       success      - True if trigger was successfully sent (logical)
%
%   Example:
%       % Send event marker for trial start (code 10)
%       success = sendTrigger(tracker, uint64(10));
%       if ~success
%           warning('Trigger failed to send');
%       end

    % Initialize output
    success = false;
    
    % Validate input
    if nargin < 2
        error('Both trackerHandler and triggerCode must be provided');
    end
    
    if ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    if ~isa(triggerCode, 'uint64')
        try
            triggerCode = uint64(triggerCode);
        catch
            error('triggerCode must be convertible to uint64 (0-18446744073709551615)');
        end
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0; % Assuming 0 indicates success
    
    try
        % Call the DLL function
        status = calllib(LIB_NAME, 'mlif_pupil_io_send_trigger', triggerCode);
        
        % Check result
        if status == SUCCESS_CODE
            success = true;
        else
            warning('Trigger sending failed with status: %d', status);
        end
        
    catch ME
        fprintf('Error sending trigger: %s\n', ME.message);
        
        % Additional error diagnostics
        if contains(ME.message, 'could not find the function')
            disp('> Check if the DLL exports mlif_pupil_io_send_trigger');
            disp('> Verify function name spelling matches header file');
        end
    end
end