function [success] = setCameraMode(trackerHandler, mode)
    success = false;
    
    if nargin < 2 || ~isfield(trackerHandler, 'libName')
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        modePtr = libpointer('int32Ptr', int32(mode));
        
        status = calllib(LIB_NAME, 'mlif_pupil_io_set_camera_mode', modePtr);
        
        if status == SUCCESS_CODE
            success = true;
        end
        clear modePtr;
    catch ME
        fprintf('Error in setCameraMode: %s\n', ME.message);
    end
end
