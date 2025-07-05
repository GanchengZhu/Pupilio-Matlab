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


function status = facePreviewerInit(tracker, udp_address, port)
% FACEPREVIEWERINIT Initialize the eye previewer system
%   status = facePreviewerInit(tracker, udp_address, port) initializes the 
%   eye previewer system with the specified UDP address and port.
%
%   Inputs:
%     tracker      - Struct returned by initializeTracker
%     udp_address  - IP address as string (e.g., '127.0.0.1')
%     port         - UDP port number (integer between 1024 and 49151)
%
%   Returns:
%     status       - 0 if successful, error code otherwise
%
%   Example:
%     [success, tracker] = initializeTracker();
%     status = facePreviewerInit(tracker, '192.168.1.100', 5000);

    % Input validation
    if nargin < 3
        error('FacePreviewerInit requires three input arguments');
    end
    
    if ~isstruct(tracker) || ~isfield(tracker, 'libName')
        error('tracker must be a struct with libName field');
    end
    
    LIB_NAME = tracker.libName;
    
    
    if ~ischar(udp_address) || isempty(udp_address)
        error('udp_address must be a non-empty string');
    end
    
    % Validate port is in user port range (1024-49151)
    if ~isnumeric(port) || port < 1024 || port > 49151 || mod(port,1) ~= 0
        error('port must be an integer between 1024 and 49151');
    end

    % Call the DLL function
    try
        status = calllib(LIB_NAME, 'mlif_pupil_io_previewer_init', udp_address, int32(port));
    catch ME
        error('Failed to initialize previewer: %s\nEnsure the UDP address and port are correct.', ME.message);
    end
    
    % Provide more detailed feedback
    if status == 0
        fprintf('Previewer initialized successfully on %s:%d\n', udp_address, port);
    else
        warning('Previewer initialization failed with error code: %d', status);
        
        % Common error code explanations
        switch status
            case -1
                warning('Possible causes: Invalid UDP address or port in use');
            case -2
                warning('Possible causes: Network connection failed');
            otherwise
                warning('Refer to PUPILIO documentation for error code meanings');
        end
    end
end