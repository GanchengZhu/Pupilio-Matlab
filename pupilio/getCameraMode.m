function [success, mode, leftRoi, rightRoi] = getCameraMode(libName)
    success = false;
    mode = 0;
    leftRoi = [0, 0, 0, 0];
    rightRoi = [0, 0, 0, 0];
    
    if nargin < 1 || isempty(libName)
        error('Library name must be specified');
    end
    
    libName = 'PupilioET';

    SUCCESS_CODE = 0;
    
    try
        % Use pointers (standard MATLAB approach)
        modePtr = libpointer('int32Ptr', int32(0));
        leftPtr = libpointer('int32Ptr', int32([0, 0, 0, 0]));
        rightPtr = libpointer('int32Ptr', int32([0, 0, 0, 0]));
        
        status = calllib(libName, 'pupil_io_get_camera_mode', modePtr, leftPtr, rightPtr);
        
        if status == SUCCESS_CODE
            mode = modePtr.Value;
            leftRoi = double(leftPtr.Value);
            rightRoi = double(rightPtr.Value);
            success = true;
        else
            fprintf('getCameraMode: Failed with status %d\n', status);
        end
        
        clear modePtr leftPtr rightPtr;
        
    catch ME
        fprintf('Error in getCameraMode: %s\n', ME.message);
    end
end