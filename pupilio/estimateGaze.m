% Copyright (c) 2025 Hangzhou DeepGaze Science & Technology Ltd.
% ...
function [success, leftGaze, rightGaze, binoGaze, timestamp] = estimateGaze(trackerHandler)
    success = false;
    leftGaze = NaN(1, 14);
    rightGaze = NaN(1, 14);
    binoGaze = NaN(1, 10);
    timestamp = int64(0);
    
    if nargin < 1 || ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;
    
    try
        ptL = single(zeros(1, 14));
        ptR = single(zeros(1, 14));
        ptBino = single(zeros(1, 10));
        ts = int64(0);
        
        ptLPtr = libpointer('singlePtr', ptL);
        ptRPtr = libpointer('singlePtr', ptR);
        ptBinoPtr = libpointer('singlePtr', ptBino);
        tsPtr = libpointer('int64Ptr', ts);
        
        status = calllib(LIB_NAME, 'mlif_pupil_io_estimate_gaze', ptLPtr, ptRPtr, ptBinoPtr, tsPtr);
        
        if status == SUCCESS_CODE
            leftGaze = ptLPtr.Value;
            rightGaze = ptRPtr.Value;
            binoGaze = ptBinoPtr.Value;
            timestamp = tsPtr.Value;
            success = true;
        end
        
        clear ptLPtr ptRPtr ptBinoPtr tsPtr;
    catch ME
        fprintf('Binocular gaze estimation error: %s\n', ME.message);
    end
end
