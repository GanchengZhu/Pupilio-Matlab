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


function [success, gazeLeft, gazeRight, timestamp] = estimateGaze(trackerHandler)
%ESTIMATEGAZE Get binocular gaze estimate from eye tracker
%   [success, gazeLeft, gazeRight, timestamp] = estimateGaze(trackerHandler)
%
%   Input:
%       trackerHandler - Struct returned by initializeTracker
%   Output: [success, gazeLeft, gazeRight, timestamp]
    % - int: Status code, where `ET_ReturnCode.ET_SUCCESS` indicates success.
    % - np.ndarray: Estimated gaze point for the left eye. Contains 14 elements.
    %     left_eye_sample[0]:left eye gaze position x (0~1920)
    %     left_eye_sample[1]:left eye gaze position y (0~1920)
    %     left_eye_sample[2]:left eye pupil diameter (0~10) (mm)
    %     left_eye_sample[3]:left eye pupil position x
    %     left_eye_sample[4]:left eye pupil position y
    %     left_eye_sample[5]:left eye pupil position z
    %     left_eye_sample[6]:left eye visual angle in spherical: theta
    %     left_eye_sample[7]:left eye visual angle in spherical: phi
    %     left_eye_sample[8]:left eye visual angle in vector: x
    %     left_eye_sample[9]:left eye visual angle in vector: y
    %     left_eye_sample[10]:left eye visual angle in vector: z
    %     left_eye_sample[11]:left eye pix per degree x
    %     left_eye_sample[12]:left eye pix per degree y
    %     left_eye_sample[13]:left eye valid (0:invalid 1:valid)
    % - np.ndarray: Estimated gaze point for the right eye. Contains 14 elements.
    %     right_eye_sample[0]:right eye gaze position x (0~1920)
    %     right_eye_sample[1]:right eye gaze position y (0~1920)
    %     right_eye_sample[2]:right eye pupil diameter (0~10) (mm)
    %     right_eye_sample[3]:right eye pupil position x
    %     right_eye_sample[4]:right eye pupil position y
    %     right_eye_sample[5]:right eye pupil position z
    %     right_eye_sample[6]:right eye visual angle in spherical: theta
    %     right_eye_sample[7]:right eye visual angle in spherical: phi
    %     right_eye_sample[8]:right eye visual angle in vector: x
    %     right_eye_sample[9]:right eye visual angle in vector: y
    %     right_eye_sample[10]:right eye visual angle in vector: z
    %     right_eye_sample[11]:right eye pix per degree x
    %     right_eye_sample[12]:right eye pix per degree y
    %     right_eye_sample[13]:right eye valid (0:invalid 1:valid)
    %     - int: Timestamp of the estimation (in milliseconds).
%
%   Example:
%       [success, left, right, ts] = estimateGaze(tracker);
%       if success
%           fprintf('Left: [%.2f,%.2f] Right: [%.2f,%.2f] @ %dμs\n',...
%                   left(1),left(2),right(1),right(2),ts);
%       end

    % Initialize outputs
    success = false;
    gazeLeft = [NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN];
    gazeRight = [NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN, NaN];
    timestamp = int64(0);
    
    % Validate input
    if nargin < 1 || ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0; % Assuming 0 indicates success
    
    try
        % Prepare output buffers
        ptL = single([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]); % Left eye sample
        ptR = single([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]); % Right eye sample
        ts = int64(0);        % Timestamp
        
        % Create pointers for DLL call
        ptLPtr = libpointer('singlePtr', ptL);
        ptRPtr = libpointer('singlePtr', ptR);
        tsPtr = libpointer('int64Ptr', ts);
        
        % Call the DLL function
        status = calllib(LIB_NAME, 'mlif_pupil_io_est_lr', ptLPtr, ptRPtr, tsPtr);
        
        % Process results
        if status == SUCCESS_CODE
            gazeLeft = [ptLPtr.Value(1), ptLPtr.Value(2),ptLPtr.Value(3), ptLPtr.Value(4),...
                ptLPtr.Value(5), ptLPtr.Value(6),ptLPtr.Value(7), ptLPtr.Value(8),...
                ptLPtr.Value(9), ptLPtr.Value(10),ptLPtr.Value(11), ptLPtr.Value(12),...
                ptLPtr.Value(13), ptLPtr.Value(14)];
            gazeRight = [ptRPtr.Value(1), ptRPtr.Value(2),ptRPtr.Value(3), ptRPtr.Value(4),...
                ptRPtr.Value(5), ptRPtr.Value(6),ptRPtr.Value(7), ptRPtr.Value(8),...
                ptRPtr.Value(9), ptRPtr.Value(10),ptRPtr.Value(11), ptRPtr.Value(12),...
                ptRPtr.Value(13), ptRPtr.Value(14)];
            timestamp = tsPtr.Value;
            success = true;
        else
            warning('Binocular gaze estimation failed with status: %d', status);
        end
        
        % Clean up pointers
        clear  ptLPtr ptRPtr tsPtr;
        
    catch ME
        fprintf('Binocular gaze estimation error: %s\n', ME.message);
        % Pointers are automatically cleared when function exits
    end
end