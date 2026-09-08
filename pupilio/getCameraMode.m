function [success, mode, leftRoi, rightRoi] = getCameraMode(trackerHandler)
    success = false;
    mode = 0;
    leftRoi = [0, 0, 0, 0];
    rightRoi = [0, 0, 0, 0];
    
    if nargin < 1 || ~isfield(trackerHandler, 'libName')
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        % 使用 pupil_io_get_camera_mode（在 extern "C" 内部）
        modePtr = libpointer('int32Ptr', int32(0));
        leftPtr = libpointer('int32Ptr', int32([0, 0, 0, 0]));
        rightPtr = libpointer('int32Ptr', int32([0, 0, 0, 0]));
        
        status = calllib(LIB_NAME, 'pupil_io_get_camera_mode', modePtr, leftPtr, rightPtr);
        
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