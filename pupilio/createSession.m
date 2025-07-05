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


function session_id = createSession(trackerHandler, session_name)
% CREATESESSION Creates a new eye tracking session with comprehensive error handling
%
% Inputs:
%   trackerHandler - Structure containing tracker configuration with required fields:
%                   * libName: Name of the loaded library (string)
%                   * config: Configuration structure
%   session_name   - String with session name/identifier
%
% Output:
%   session_id     - Integer session ID (negative values indicate errors)
%                   -1: Library not loaded
%                   -2: Invalid input
%                   -3: Library call failed
%                   -4: Unexpected error
%
% Example:
%   session_id = createSession(tracker, 'test_session_1');

    % Initialize default error return value
    session_id = -4; % Default error code
    
    try
        %% Input Validation
        if nargin < 2
            error('Not enough input arguments');
        end
        
        if ~isfield(trackerHandler, 'libName')
            session_id = -2;
            error('trackerHandler must contain libName field');
        end
        
        if ~ischar(session_name) || isempty(session_name)
            session_id = -2;
            error('session_name must be a non-empty string');
        end
        
        LIB_NAME = trackerHandler.libName;
        
        %% Library State Check
        if ~libisloaded(LIB_NAME)
            session_id = -1;
            error('Library %s is not loaded', LIB_NAME);
        end
        
        %% Update Configuration
        if isfield(trackerHandler, 'config')
            trackerHandler.config.session_name = session_name;
        else
            trackerHandler.config = struct('session_name', session_name);
        end
        
        %% Attempt Session Creation
        try
            session_id = calllib(LIB_NAME, 'mlif_pupil_io_create_session', session_name);
            
            % Verify the returned session ID
            if ~isnumeric(session_id)
                session_id = -3;
                error('Invalid session ID returned from library');
            end
            
            % Log successful creation
            fprintf('[%s] Created session "%s" with Session_ID: %d\n', ...
                   LIB_NAME, session_name, session_id);
            
        catch libErr
            session_id = -3;
            error('Library call failed: %s', libErr.message);
        end
        
    catch finalErr
        %% Error Handling and Reporting
        switch session_id
            case -1
                errMsg = sprintf('Library %s not loaded', LIB_NAME);
            case -2
                errMsg = 'Invalid input parameters';
            case -3
                errMsg = 'Library function failed';
            otherwise
                errMsg = 'Unexpected error occurred';
        end
        
        fprintf('[ERROR] Failed to create session "%s": %s\n', ...
               session_name, errMsg);
        fprintf('Error details: %s\n', finalErr.message);
        
        % For debugging, consider logging the full stack trace:
        % fprintf('Stack trace:\n');
        % disp(finalErr.stack);
    end
end