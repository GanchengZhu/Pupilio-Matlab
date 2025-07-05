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


function [sdkVersion, wrapperVersion, success] = getVersionString(trackerHandler)
%GETVERSIONSTRING Get both SDK and wrapper version information
%   [sdkVersion, wrapperVersion, success] = getVersionString(trackerHandler)
%
%   Input:
%       trackerHandler - Struct returned by initializePupilio
%   Output:
%       sdkVersion     - SDK version string (empty if failed)
%       wrapperVersion - Wrapper version string (empty if failed)
%       success        - True if at least one version was retrieved (logical)
%
%   Example:
%       [sdkVer, wrapVer, success] = getVersionString(tracker);
%       if success
%           disp(['SDK Version: ' sdkVer]);
%           disp(['Wrapper Version: ' wrapVer]);
%       end

    % Initialize outputs
    sdkVersion = '';
    wrapperVersion = '';
    success = false;
    
    % Validate input
    if nargin < 1 || ~isstruct(trackerHandler) || ...
       ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('getVersionString:invalidHandle', ...
              'Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    
    % Verify library is loaded
    if ~libisloaded(LIB_NAME)
        error('getVersionString:libraryNotLoaded', ...
              'Library %s is not loaded', LIB_NAME);
    end
    
    % Get SDK version (mlif_pupil_io_get_version)
    try
        sdkVersion = calllib(LIB_NAME, 'mlif_pupil_io_get_version');
        if ~isempty(sdkVersion)
            success = true;
        else
            warning('getVersionString:emptySDKVersion', ...
                   'SDK version query returned empty string');
        end
    catch ME
        fprintf('Error retrieving SDK version: %s\n', ME.message);
        if contains(ME.message, 'could not find the function')
            disp('> SDK version function (mlif_pupil_io_get_version) not found');
        end
    end
    
    % Get wrapper version (mlif_get_version)
    try
        wrapperVersion = calllib(LIB_NAME, 'mlif_get_version');
        if ~isempty(wrapperVersion)
            success = true;
        else
            warning('getVersionString:emptyWrapperVersion', ...
                   'Wrapper version query returned empty string');
        end
    catch ME
        fprintf('Error retrieving wrapper version: %s\n', ME.message);
        if contains(ME.message, 'could not find the function')
            disp('> Wrapper version function (mlif_get_version) not found');
        end
    end
    
    % Validate version strings (semantic versioning: X.Y.Z)
    % versionPattern = '^\d+\.\d+\.\d+$';  % Strict format check
    % 
    % if ~isempty(sdkVersion) && isempty(regexp(sdkVersion, versionPattern, 'once'))
    %     warning('getVersionString:invalidSDKVersionFormat', ...
    %            'Unexpected SDK version string format: %s', sdkVersion);
    % end
    % 
    % if ~isempty(wrapperVersion) && isempty(regexp(wrapperVersion, versionPattern, 'once'))
    %     warning('getVersionString:invalidWrapperVersionFormat', ...
    %            'Unexpected wrapper version string format: %s', wrapperVersion);
    % end
    
    % If neither version was retrieved successfully
    if ~success
        warning('getVersionString:noVersionsFound', ...
               'Could not retrieve either SDK or wrapper version');
    end
end