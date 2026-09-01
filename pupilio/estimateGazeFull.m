function [success, gazeFull, timestamp] = estimateGazeFull(trackerHandler)
    success = false;
    gazeFull = NaN(1, 11);
    timestamp = int64(0);
    
    if nargin < 1 || ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        pt = single(zeros(1, 11));
        ts = int64(0);
        
        ptPtr = libpointer('singlePtr', pt);
        tsPtr = libpointer('int64Ptr', ts);
        
        status = calllib(LIB_NAME, 'mlif_pupil_io_est_full', ptPtr, tsPtr);
        
        if status == SUCCESS_CODE
            gazeFull = ptPtr.Value;
            timestamp = tsPtr.Value;
            success = true;
        end
        
        clear ptPtr tsPtr;
    catch ME
        fprintf('Full gaze estimation error: %s\n', ME.message);
    end
end
