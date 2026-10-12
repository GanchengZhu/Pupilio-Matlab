function [success] = setCameraMode(libName, mode)
    success = false;
    
    if nargin < 2
        error('Camera mode must be specified');
    end
    
    if nargin < 1 || isempty(libName)
        error('Library name must be specified');
    end
    libName = 'PupilioET';

    SUCCESS_CODE = 0;
    
    try
        % Try passing mode as integer directly
        status = calllib(libName, 'pupil_io_set_camera_mode', int32(mode));
        
        if status == SUCCESS_CODE
            success = true;
            fprintf('[PupilioET] Successfully set camera mode to %d\n', mode);
        else
            fprintf('[PupilioET] Failed with status %d\n', status);
            
            % Try with pointer as fallback
            try
                fprintf('setCameraMode: Trying with pointer...\n');
                modePtr = libpointer('int32Ptr', int32(mode));
                status = calllib(libName, 'pupil_io_set_camera_mode', modePtr);
                
                if status == SUCCESS_CODE
                    success = true;
                    fprintf('setCameraMode: Successfully set camera mode to %d (via pointer)\n', mode);
                else
                    fprintf('setCameraMode: Failed with status %d (via pointer)\n', status);
                end
                
                clear modePtr;
            catch ME2
                fprintf('setCameraMode: Pointer method also failed: %s\n', ME2.message);
            end
        end
        
    catch ME
        fprintf('Error in setCameraMode: %s\n', ME.message);
    end
end

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