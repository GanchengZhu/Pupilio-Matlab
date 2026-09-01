function [success, status] = startSampling(trackerHandler)
    if nargin < 1 || isempty(trackerHandler)
        error('Tracker handler required.');
    end
    
    if ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Tracker not initialized.');
    end
    
    [s, isSampling] = getSamplingStatus(trackerHandler);
    if s && isSampling
        error('Sampling is already running; call stopSampling first.');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;

    try
        status = calllib(LIB_NAME, 'mlif_pupil_io_start_sampling');
        pause(0.05);
        success = (status == SUCCESS_CODE);
        if success
            trackerHandler.isSampling = true;
            fprintf('[%s] Sampling started\n', LIB_NAME);
        else
            warning('[%s] Sampling start failed (Status: %d)', LIB_NAME, status);
        end
    catch ME
        success = false;
        status = -1;
        fprintf('[%s] Critical sampling error: %s\n', LIB_NAME, ME.message);
    end
end
