function [success] = setCameraMode(trackerHandler, mode)
    success = false;
    
    if nargin < 2
        error('Camera mode must be specified');
    end
    
    if nargin < 1 || ~isfield(trackerHandler, 'libName')
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        % 使用 pupil_io_set_camera_mode（在 extern "C" 内部）
        modePtr = libpointer('int32Ptr', int32(mode));
        status = calllib(LIB_NAME, 'pupil_io_set_camera_mode', modePtr);
        
        if status == SUCCESS_CODE
            success = true;
            fprintf('setCameraMode: Successfully set to %d\n', mode);
        else
            fprintf('setCameraMode: Failed with status %d\n', status);
        end
        
        clear modePtr;
        
    catch ME
        fprintf('Error in setCameraMode: %s\n', ME.message);
    end
end