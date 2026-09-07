s% Copyright (c) 2025 Hangzhou DeepGaze Science & Technology Ltd.
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

% 
% function success = releaseTracker(trackerHandler)
%     %RELEASETRACKER Release all tracker resources
%     %   success = releaseTracker(trackerHandler) attempts to properly release
%     %   resources and unload the library. Returns true if successful.
% 
%     % Initialize output
%     success = false;
% 
%     % Input validation
%     if nargin < 1 || isempty(trackerHandler) || ~isfield(trackerHandler, 'libName')
%         error('releaseTracker:invalidInput', 'Invalid tracker handle');
%         return;
%     end
% 
%     LIB_NAME = trackerHandler.libName;
%     SUCCESS_CODE = 0;
%     MAX_ATTEMPTS = 3;
%     RETRY_DELAY = 0.5; % seconds between attempts
% 
%     % Early return if library not loaded
%     if ~libisloaded(LIB_NAME)
%         %fprintf('[%s] Library not loaded - nothing to release\n', LIB_NAME);
%         success = true;  % Considered successful if nothing to do
%         return;
%     end
% 
%     %% Phase 1: Release tracker resources
%     pause(1.0); % pause 1.0 second to make sure the tracker has stopped recording
%     for attempt = 1:MAX_ATTEMPTS
%         try
%             releaseStatus = calllib(LIB_NAME, 'mlif_pupil_io_release');
% 
%             if releaseStatus == 0
%                 fprintf('[%s] Successfully released\n', ...
%                        LIB_NAME);
%                 success = true;
%                 break;
%             else
%                 fprintf('[%s] Release failed with code %d (attempt %d)\n', ...
%                        LIB_NAME, releaseStatus, attempt);
%             end
% 
%         catch ME
%             fprintf('[%s] Release error on attempt %d: %s\n', ...
%                    LIB_NAME, attempt, ME.message);
%         end
% 
%         % Only delay if we're going to try again
%         if attempt < MAX_ATTEMPTS
%             pause(RETRY_DELAY);
%         end
%     end
% 
%     try
%         %% Phase 2: Unload library
%         unloadlibrary(LIB_NAME);
%         fprintf('[%s] Library unloaded successfully\n', LIB_NAME);
% 
%         pause(1.0); % pause 1.0 second to make sure the tracker has stopped recording
% 
%         %% Phase 3: Update handle state (if handle is passed by reference)
%         if isfield(trackerHandler, 'isInitialized')
%             trackerHandler.isInitialized = false;
%         end
% 
%         success = true;
% 
%     catch ME
%         %% Enhanced error handling
%         fprintf('[%s] Release error: %s\n', LIB_NAME, getReport(ME, 'extended'));
% 
%         % Emergency cleanup attempt
%         try
%             if libisloaded(LIB_NAME)
%                 unloadlibrary(LIB_NAME);
%                 fprintf('[%s] Emergency unload completed\n', LIB_NAME);
%             end
%         catch
%             fprintf('[%s] FATAL: Library could not be unloaded\n', LIB_NAME);
%             % Consider adding system-level cleanup here if needed
%         end
%     end
% end



function [success, trackerHandler] = releaseTracker(trackerHandler)
    %RELEASETRACKER Release all tracker resources and unload library
    %   [success, trackerHandler] = releaseTracker(trackerHandler) attempts to properly
    %   release resources, clear all outstanding MATLAB objects referencing the library,
    %   and unload the library. Returns true if successful, and the updated tracker handle.
    
    % Initialize output
    success = false;
    
    % Input validation
    if nargin < 1 || isempty(trackerHandler) || ~isfield(trackerHandler, 'libName')
        error('releaseTracker:invalidInput', 'Invalid tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    MAX_ATTEMPTS = 3;
    RETRY_DELAY = 0.5; % seconds between attempts

    % Early return if library not loaded
    if ~libisloaded(LIB_NAME)
        fprintf('[%s] Library not loaded - nothing to release\n', LIB_NAME);
        success = true;
        return;
    end
    
    %% Phase 1: Release tracker resources (internal C library)
    pause(1.0); % ensure recording has stopped
    for attempt = 1:MAX_ATTEMPTS
        try
            releaseStatus = calllib(LIB_NAME, 'mlif_pupil_io_release');
            if releaseStatus == 0
                fprintf('[%s] Successfully released internal resources\n', LIB_NAME);
                break;
            else
                fprintf('[%s] Release failed with code %d (attempt %d)\n', ...
                        LIB_NAME, releaseStatus, attempt);
            end
        catch ME
            fprintf('[%s] Release error on attempt %d: %s\n', ...
                    LIB_NAME, attempt, ME.message);
        end
        if attempt < MAX_ATTEMPTS
            pause(RETRY_DELAY);
        end
    end

    %% Phase 1.5: Clear outstanding MATLAB objects that reference the library
    % This is critical before calling unloadlibrary.
    fprintf('[%s] Clearing outstanding MATLAB objects...\n', LIB_NAME);
    trackerHandler = clearOutstandingObjects(trackerHandler, LIB_NAME);
    
    % Important: If there are other variables in the caller's workspace that
    % also hold libpointers (e.g., config, cursor, etc.), they must be cleared
    % manually. We provide a warning.
    fprintf(['[%s] NOTE: If you have other variables (e.g., ''config'', ''cursor'')\n' ...
             '       that contain libpointers, please clear them manually before\n' ...
             '       calling unloadlibrary.\n'], LIB_NAME);

    %% Phase 2: Unload library
    try
        unloadlibrary(LIB_NAME);
        fprintf('[%s] Library unloaded successfully\n', LIB_NAME);
        
        pause(1.0); % additional safety delay
        
        %% Phase 3: Update handle state
        if isfield(trackerHandler, 'isInitialized')
            trackerHandler.isInitialized = false;
        end
        
        success = true;
        
    catch ME
        %% Enhanced error handling
        fprintf('[%s] Unload error: %s\n', LIB_NAME, getReport(ME, 'extended'));
        
        % Emergency cleanup attempt – may still fail if objects remain
        try
            if libisloaded(LIB_NAME)
                % Try to force clear any remaining objects in the caller
                % (this is a last resort, use with caution)
                evalin('caller', 'clear(''libpointer'', ''libstruct'')');
                unloadlibrary(LIB_NAME);
                fprintf('[%s] Emergency unload succeeded after clearing objects\n', LIB_NAME);
                success = true;
            end
        catch
            fprintf('[%s] FATAL: Library could not be unloaded. Please restart MATLAB.\n', LIB_NAME);
        end
    end
end

%% ------------------------------------------------------------------------
% Helper function: recursively clear all libpointer/libstruct fields
function obj = clearOutstandingObjects(obj, libName)
    % If obj is a struct, scan its fields
    if isstruct(obj)
        fnames = fieldnames(obj);
        for i = 1:length(fnames)
            field = fnames{i};
            value = obj.(field);
            % Check if value is a libpointer or libstruct
            if isa(value, 'libpointer') || isa(value, 'libstruct')
                fprintf('[%s] Clearing field ''%s''\n', libName, field);
                obj.(field) = [];  % release the reference
            elseif isstruct(value) || iscell(value)
                % Recursively clear nested structures/cells
                obj.(field) = clearOutstandingObjects(value, libName);
            end
            % Note: we don't handle object arrays or handle classes here,
            % but they can be added if needed.
        end
    elseif iscell(obj)
        for i = 1:numel(obj)
            obj{i} = clearOutstandingObjects(obj{i}, libName);
        end
    end
    % For other types, leave unchanged
end