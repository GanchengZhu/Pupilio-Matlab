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


function [success, leftGaze, rightGaze, binoGaze] = getCurrentGaze(trackerHandler)
%GETCURRENTGAZE Get the current gaze positions from the eye tracker
%   [success, leftGaze, rightGaze, binoGaze] = getCurrentGaze(trackerHandler)
%
%   Input:
%       trackerHandler - Struct containing tracker information (from initializeTracker)
%   Output:
%       success    - True if data was successfully obtained (logical)
%       leftGaze   - [x,y,valid] coordinates of left eye gaze
%       rightGaze  - [x,y,valid] coordinates of right eye gaze
%       binoGaze   - [x,y,valid] coordinates of binocular averaged gaze
%
%   Example:
%       [success, left, right, bino] = getCurrentGaze(tracker);
%       if success
%           fprintf('Left: [%.3f,%.3f,%.3f] Right: [%.3f,%.3f,%.3f] Binocular: [%.3f,%.3f,%.3f]\n',...
%                   left(1),left(2),left(3),right(1),right(2),right(3),bino(1),bino(2),bino(3));
%       end

    % Initialize outputs
    success = false;
    leftGaze = [NaN, NaN, NaN];
    rightGaze = [NaN, NaN, NaN];
    binoGaze = [NaN, NaN, NaN];
    
    % Validate input
    if nargin < 1 || ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0; % Assuming 0 indicates success
    
    try
        % Prepare output buffers (x,y coordinates for each gaze, & valid)
        left = single([0, 0, 0]);
        right = single([0, 0, 0]);
        bino = single([0, 0, 0]);
        
        % Create pointers for DLL call
        leftPtr = libpointer('singlePtr', left);
        rightPtr = libpointer('singlePtr', right);
        binoPtr = libpointer('singlePtr', bino);
        
        % Call the DLL function
        status = calllib(LIB_NAME, 'mlif_pupil_io_get_current_gaze', ...
                        leftPtr, rightPtr, binoPtr);
        
        % Process results
        if status == SUCCESS_CODE
            leftGaze = [leftPtr.Value(1), leftPtr.Value(2), leftPtr.Value(3)];
            rightGaze = [rightPtr.Value(1), rightPtr.Value(2), rightPtr.Value(3)];
            binoGaze = [binoPtr.Value(1), binoPtr.Value(2), binoPtr.Value(3)];
            success = true;
        else
            warning('Gaze data acquisition failed with status: %d', status);
        end
        
        % Clean up pointers
        clear leftPtr rightPtr binoPtr;
        
    catch ME
        fprintf('Error in getCurrentGaze: %s\n', ME.message);
        % Pointers are automatically cleared when function exits
    end
end