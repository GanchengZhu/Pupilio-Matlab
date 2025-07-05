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


function status = facePreviewerStop(tracker)
% FACEPREVIEWERSTOP Stops the eye previewer system
%   status = facePreviewerStop(tracker) stops the running eye previewer
%
%   Input:
%     tracker - Struct containing DLL handler information with libName field
%
%   Returns:
%     status - 0 if successful, error code otherwise
%
%   Example:
%     tracker = struct('libName', 'PUPILIO_DLL');
%     status = facePreviewerStop(tracker);

    % Input validation
    if nargin < 1
        error('FacePreviewerStop requires one input argument');
    end
    
    if ~isstruct(tracker) || ~isfield(tracker, 'libName')
        error('tracker must be a struct with libName field');
    end
    
    LIB_NAME = tracker.libName;
    
    % Call the DLL function
    try
        status = calllib(LIB_NAME, 'mlif_pupil_io_previewer_stop');
    catch ME
        error('Failed to stop previewer: %s', ME.message);
    end
    
    % Provide feedback
    if status == 0
        fprintf('Previewer stopped successfully\n');
    else
        warning('Previewer stop failed with error code: %d', status);
        
        % Common error code explanations
        switch status
            case -1
                warning('Possible causes: Previewer not running');
            case -2 
                warning('Possible causes: Previewer already stopped');
            otherwise
                warning('Refer to PUPILIO documentation for error code meanings');
        end
    end
end