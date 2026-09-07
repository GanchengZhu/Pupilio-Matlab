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
% FACEPREVIEWERGETIMAGES Get eye preview images and tracking data.
%
%   This function uses the **pre‑allocated buffer** method: it creates
%   zero‑initialised matrices of the correct size and passes them to the
%   C library. The library fills the matrices directly, so no pointer
%   address manipulation or setdatatype() is required. This works with
%   all MATLAB versions.
%
%   The image dimensions are determined dynamically from the camera mode
%   and sampling rate via getCameraMode().
%
%   Input:
%     tracker - Struct containing the library name (field 'libName'),
%               and optionally 'config.sampling_rate' for 200 Hz sync mode.
%
%   Outputs:
%     status         - 0 on success, non‑zero error code
%     img_left/right - Eye images as uint8 matrices (height × width)
%     eye_rects      - 4×4 matrix of eye bounding boxes
%     pupil_centers  - 4×2 matrix of pupil centers
%     glint_centers  - 4×2 matrix of glint centers

    if nargin < 1
        error('FacePreviewerGetImages requires one input argument');
    end
    if ~isstruct(tracker) || ~isfield(tracker, 'libName')
        error('tracker must be a struct with libName field');
    end

    LIB_NAME = tracker.libName;

    % --- Initialise outputs (empty on failure) ---
    img_left      = [];
    img_right     = [];
    eye_rects     = [];
    pupil_centers = [];
    glint_centers = [];

    % --- Dynamically determine image dimensions (your original logic) ---
    [s_c, camera_mode, leftRoi, rightRoi] = getCameraMode(tracker);
    
    is_sync_200 = false;
    if s_c
        if camera_mode == 3 || (camera_mode == 0 && isfield(tracker, 'config') && tracker.config.sampling_rate == 200)
            is_sync_200 = true;
        end
    end
    
    if is_sync_200
        img_left_height  = 1024;
        img_left_width   = 1280;
        img_right_height = 1024;
        img_right_width  = 1280;
    else
        if s_c
            img_left_height  = leftRoi(4);
            img_left_width   = leftRoi(3);
            img_right_height = rightRoi(4);
            img_right_width  = rightRoi(3);
        else
            img_left_height  = 1024;
            img_left_width   = 1280;
            img_right_height = 1024;
            img_right_width  = 1280;
        end
    end

    % --- Validate dimensions ---
    if any([img_left_height, img_left_width, img_right_height, img_right_width] <= 0)
        error('Invalid image dimensions (height or width <= 0). Check getCameraMode() output.');
    end

    % --- Pre‑allocate buffers using the correct sizes ---
    img_left_ptr  = libpointer('uint8PtrPtr', zeros(img_left_height,  img_left_width,  'uint8'));
    img_right_ptr = libpointer('uint8PtrPtr', zeros(img_right_height, img_right_width, 'uint8'));

    % Feature buffers (4 eyes × 4 coordinates for rects, etc.)
    eye_rects_ptr     = libpointer('singlePtr', zeros(4*4, 1));
    pupil_centers_ptr = libpointer('singlePtr', zeros(4*2, 1));
    glint_centers_ptr = libpointer('singlePtr', zeros(4*2, 1));

    % --- Call the DLL ---
    [status, ~, ~, eye_rects_ptr, pupil_centers_ptr, glint_centers_ptr] = ...
        calllib(LIB_NAME, 'mlif_pupil_io_get_previewer', ...
                img_left_ptr, img_right_ptr, ...
                eye_rects_ptr, pupil_centers_ptr, glint_centers_ptr);

    % --- Process result ---
    if status == 0
        img_left  = reshape(img_left_ptr.Value,  [img_left_width,  img_left_height])';
        img_right = reshape(img_right_ptr.Value, [img_right_width, img_right_height])';

        % 检查数据是否合理（例如，检查标准差或是否全黑）
        if all(img_left(:) == 0) && all(img_right(:) == 0)
            status = -3;
            warning('Previewer returned zero images.');
            img_left = []; img_right = [];
            eye_rects = []; pupil_centers = []; glint_centers = [];
            return;
        end

        eye_rects     = eye_rects_ptr;
        pupil_centers = pupil_centers_ptr;
        glint_centers = glint_centers_ptr;
    else
        warning('Previewer image capture failed with error code: %d', status);
    end
end
