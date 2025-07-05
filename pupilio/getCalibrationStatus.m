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


function result = getCalibrationStatus(trackerHandler, cali_point_id)
% GETCALIBRATIONSTATUS - MATLAB interface for eye tracker calibration function
%
% Syntax:
%   result = getCalibrationStatus(trackerHandler, cali_point_id)
%
% Input:
%   trackerHandler - Structure containing:
%                   libName: Name of the tracker DLL
%                   (other fields as needed by your application)
%   cali_point_id - Integer specifying the calibration point ID (1-based index)
%
% Output:
%   result - Integer return status (0 = SUCCESS)
%
% Example:
%   tracker = struct('libName', 'PUPILIO_DLL');
%   status = getCalibrationStatus(tracker, 5);

    % Validate input
    if nargin < 1 || ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end

    % Define success code (modify according to your API specification)
    SUCCESS_CODE = 0;
    
    % Get library name from handler
    LIB_NAME = trackerHandler.libName;
    
    % Call the DLL function
    result = calllib(LIB_NAME, 'mlif_pupil_io_cali', int32(cali_point_id));
    % fprintf('Calibration return %d point# %d\n', result, cali_point_id);

    % Provide feedback if no output requested
    if nargout == 0
        if result == SUCCESS_CODE
            fprintf('Calibration point %d: Success\n', cali_point_id);
        else
            warning('Calibration point %d failed (code: %d)', ...
                    cali_point_id, result);
        end
    end
end