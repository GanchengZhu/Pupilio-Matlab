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


function success = clearCache(trackerHandler)
%CLEARCACHE Clear the eye tracker's internal cache memory
%   success = clearCache(trackerHandler) attempts to clear the tracker's cache
%
%   Input:
%       trackerHandler - Struct returned by initializePupilio containing:
%                       - libName: Name of loaded library
%                       - isInitialized: Boolean initialization status
%   Output:
%       success       - True if cache was successfully cleared (logical)
%
%   Example:
%       success = clearCache(tracker);
%       if success
%           disp('Cache cleared successfully');
%       else
%           warning('Failed to clear cache');
%       end
%
%   Notes:
%       - Checks tracker initialization status
%       - Verifies library is loaded
%       - Includes error recovery and status reporting
%       - Optional sampling status check (commented out)

    % Initialize output with failure state
    success = false;
    
    % Input validation
    try
        % Check for required fields in trackerHandler
        requiredFields = {'libName', 'isInitialized'};
        missingFields = setdiff(requiredFields, fieldnames(trackerHandler));
        
        if nargin < 1 || ~isempty(missingFields) || ~trackerHandler.isInitialized
            errorStruct.identifier = 'clearCache:invalidInput';
            errorStruct.message = sprintf('Invalid handle. Missing fields: %s', strjoin(missingFields, ', '));
            error(errorStruct);
        end
        
        LIB_NAME = trackerHandler.libName;
        
        % Library status check
        if ~libisloaded(LIB_NAME)
            error('clearCache:libraryNotLoaded', 'Library %s is not loaded', LIB_NAME);
        end
        
        % Define expected success code (device specific)
        SUCCESS_CODE = 0;  % Modify based on device protocol
        
        % Optional: Check if device is sampling (uncomment if needed)
        % if isfield(trackerHandler, 'getSamplingStatus')
        %     [~, isSampling] = trackerHandler.getSamplingStatus();
        %     if isSampling
        %         warning('clearCache:deviceBusy', 'Cannot clear cache during active sampling');
        %         return;
        %     end
        % end
        
        % Attempt cache clearance
        status = calllib(LIB_NAME, 'mlif_pupil_io_clear_cache');
        
        % Process result
        if status == SUCCESS_CODE
            success = true;
            pause(0.05);  % Brief delay for operation completion
        else
            warning('clearCache:operationFailed', ...
                   'Device returned failure code: %d', status);
        end
        
    catch ME
        % Enhanced error reporting
        switch ME.identifier
            case 'clearCache:invalidInput'
                fprintf(2, 'INVALID DEVICE HANDLE:\n%s\n', ME.message);
            case 'clearCache:libraryNotLoaded'
                fprintf(2, 'LIBRARY ERROR:\n%s\n', ME.message);
                disp('Suggested fixes:');
                disp('1. Call initializePupilio first');
                disp('2. Check library path');
            otherwise
                fprintf(2, 'OPERATION FAILED:\n%s\n', ME.message);
                
                % Handle common DLL errors
                if contains(ME.message, 'could not find the function')
                    disp('> DLL troubleshooting:');
                    disp('  1. Verify function name in header file');
                    disp('  2. Check DLL version compatibility');
                    disp('  3. Confirm library exports the function');
                end
        end
    end
end