function [success] = setCameraParam(trackerHandler, cameraParam)
    success = false;
    if nargin < 2 || ~isfield(trackerHandler, 'libName')
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        paramPtr = libpointer('singlePtr', single(cameraParam));
        status = calllib(LIB_NAME, 'mlif_pupil_io_set_camera_param', paramPtr);
        if status == SUCCESS_CODE
            success = true;
        end
        clear paramPtr;
    catch ME
        fprintf('Set camera param error: %s\n', ME.message);
    end
end
