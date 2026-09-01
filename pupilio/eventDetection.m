function [success] = eventDetection(trackerHandler, dataPath, outputDir, whichEye, minimumDuration, dispersionThreshold)
    success = false;
    
    if nargin < 6
        dispersionThreshold = 1.0;
    end
    if nargin < 5
        minimumDuration = 30;
    end
    if nargin < 4
        whichEye = 'bino';
    end
    
    if nargin < 3 || ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle or missing arguments');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        status = calllib(LIB_NAME, 'mlif_pupil_io_event_detection', dataPath, outputDir, whichEye, minimumDuration, dispersionThreshold);
        if status == SUCCESS_CODE
            success = true;
        end
    catch ME
        fprintf('Event detection error: %s\n', ME.message);
    end
end
