function [status, img_left, img_right, eye_rects, pupil_centers, glint_centers] = facePreviewerGetImages(tracker)
    if nargin < 1
        error('FacePreviewerGetImages requires one input argument');
    end
    
    if ~isstruct(tracker) || ~isfield(tracker, 'libName')
        error('tracker must be a struct with libName field');
    end
    
    LIB_NAME = tracker.libName;

    img_left = [];
    img_right = [];
    eye_rects = [];
    pupil_centers = [];
    glint_centers = [];

    [s_c, camera_mode, leftRoi, rightRoi] = getCameraMode(tracker);
    
    is_sync_200 = false;
    if s_c
        if camera_mode == 3 || (camera_mode == 0 && isfield(tracker, 'config') && tracker.config.sampling_rate == 200)
            is_sync_200 = true;
        end
    end
    
    if is_sync_200
        img_left_height = 1024;
        img_left_width = 1280;
        img_right_height = 1024;
        img_right_width = 1280;
    else
        if s_c
            img_left_height = leftRoi(4);
            img_left_width = leftRoi(3);
            img_right_height = rightRoi(4);
            img_right_width = rightRoi(3);
        else
            img_left_height = 1024;
            img_left_width = 1280;
            img_right_height = 1024;
            img_right_width = 1280;
        end
    end
            
    img_left_ptr = libpointer('uint8PtrPtr', zeros(img_left_height, img_left_width, 'uint8'));
    img_right_ptr = libpointer('uint8PtrPtr', zeros(img_right_height, img_right_width, 'uint8'));
    
    eye_rects_ptr = libpointer('singlePtr', zeros(4*4,1));
    pupil_centers_ptr = libpointer('singlePtr', zeros(4*2,1));
    glint_centers_ptr = libpointer('singlePtr', zeros(4*2,1));

    [status, ~, ~, eye_rects_ptr, pupil_centers_ptr, glint_centers_ptr] = ...
        calllib(LIB_NAME, 'mlif_pupil_io_get_previewer', ...
               img_left_ptr, img_right_ptr, ...
               eye_rects_ptr, pupil_centers_ptr, glint_centers_ptr);
    
    if status == 0
        % In MATLAB, libpointer might not automatically reshape correctly if the inner pointer changed,
        % but setdatatype can be used. Assuming it works like original.
        setdatatype(img_left_ptr.Value, 'uint8Ptr', img_left_width, img_left_height);
        setdatatype(img_right_ptr.Value, 'uint8Ptr', img_right_width, img_right_height);
        img_left = reshape(img_left_ptr.Value, [img_left_width, img_left_height])';
        img_right = reshape(img_right_ptr.Value, [img_right_width, img_right_height])';
        eye_rects = eye_rects_ptr; 
        pupil_centers = pupil_centers_ptr;
        glint_centers = glint_centers_ptr;
    end
    
    if status ~= 0
        warning('Previewer image capture failed with error code: %d', status);
    end
end
