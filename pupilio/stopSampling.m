function success = stopSampling(trackerHandler)
    success = false;
    if nargin < 1 || ~isfield(trackerHandler, 'libName')
        error('trackerHandler must contain libName field');
    end
    
    [s, isSampling] = getSamplingStatus(trackerHandler);
    if s && ~isSampling
        error('No sampling thread is currently running.');
    end
    
    LIB_NAME = trackerHandler.libName;
    try
        result = calllib(LIB_NAME, 'mlif_pupil_io_stop_sampling');
        pause(0.1);
        success = (result == 0);
        if success
            trackerHandler.isSampling = false;
            fprintf('[%s] Sampling stopped\n', LIB_NAME);
        end
    catch ME
        warning('Failed to stop sampling: %s', ME.message);
    end
end
