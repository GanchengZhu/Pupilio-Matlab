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


function [status, img_left, img_right, eye_rects, pupil_centers, glint_centers] = facePreviewerGetImages(tracker)
% FACEPREVIEWERGETIMAGES Gets eye preview images and tracking data
%   [status, img_left, img_right, eye_rects, pupil_centers, glint_centers] = facePreviewerGetImages(tracker)
%
%   Input:
%     tracker - Struct containing DLL handler information with libName field
%
%   Outputs:
%     status         - 0 if successful, error code otherwise
%     img_left       - Left eye image as uint8 matrix (height×width)
%     img_right      - Right eye image as uint8 matrix (height×width)
%     eye_rects      - 4×4 matrix of eye bounding boxes [left_eye; right_eye]
%     pupil_centers  - 4×2 matrix of pupil centers [left_pupil; right_pupil]
%     glint_centers  - 4×2 matrix of glint centers [left_glint; right_glint]
%
%   Example:
%     tracker = struct('libName', 'PUPILIO_DLL');
%     [status, imgL, imgR, rects, pupils, glints] = facePreviewerGetImages(tracker);

    % Input validation
    if nargin < 1
        error('FacePreviewerGetImages requires one input argument');
    end
    
    if ~isstruct(tracker) || ~isfield(tracker, 'libName')
        error('tracker must be a struct with libName field');
    end
    
    LIB_NAME = tracker.libName;

    % Initialize output variables in case of early return
    img_left = [];
    img_right = [];
    eye_rects = [];
    pupil_centers = [];
    glint_centers = [];

    % Get image dimensions (adjust these values according to your camera)
    img_height = 1024;  % Example value - replace with actual
    img_width = 1280;   % Example value - replace with actual
            
    % Create pointers for DLL to fill
    img_left_ptr = libpointer('uint8PtrPtr', zeros(img_height, img_width));
    img_right_ptr = libpointer('uint8PtrPtr', zeros(img_height, img_width));
    
    % Allocate memory for float arrays (assuming 4 coordinates per eye × 2 eyes)
    eye_rects_ptr = libpointer('singlePtr', zeros(4*4,1));
    pupil_centers_ptr = libpointer('singlePtr', zeros(4*2,1));
    glint_centers_ptr = libpointer('singlePtr', zeros(4*2,1));

    % try
        % Call the DLL function
        [status, ~, ~, eye_rects_ptr, pupil_centers_ptr, glint_centers_ptr] = ...
            calllib(LIB_NAME, 'mlif_pupil_io_get_previewer', ...
                   img_left_ptr, img_right_ptr, ...
                   eye_rects_ptr, pupil_centers_ptr, glint_centers_ptr);
        
        % Only process data if call was successful
        if status == 0
            img_left = reshape(img_left_ptr.Value, [img_width, img_height])';
            img_right = reshape(img_right_ptr.Value, [img_width, img_height])';
            eye_rects = eye_rects_ptr; 
            pupil_centers = pupil_centers_ptr;
            glint_centers = glint_centers_ptr;
        end
        
    % catch ME
    %     error('Failed to get previewer images: %s', ME.message);
    % end
    
    % Provide feedback
    if status ~= 0
        warning('Previewer image capture failed with error code: %d', status);
        switch status
            case -1
                warning('Possible causes: Previewer not running');
            case -2
                warning('Possible causes: Camera disconnected');
            otherwise
                warning('Refer to PUPILIO documentation for error code meanings');
        end
    end
end
