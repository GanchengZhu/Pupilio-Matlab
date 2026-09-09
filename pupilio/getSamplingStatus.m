function [success, isSampling] = getSamplingStatus(trackerHandler)
%GETSAMPLINGSTATUS Check if the eye tracker is currently sampling data
%   [success, isSampling] = getSamplingStatus(trackerHandler)
%
%   Input:
%       trackerHandler - Struct returned by initializeTracker
%   Output:
%       success      - True if status was successfully obtained (logical)
%       isSampling   - True if tracker is currently sampling (logical)
%
%   Return codes:
%       0  - PUPILIO_ET_SUCCESS
%       1  - PUPILIO_ET_CALI_CONTINUE
%       2  - PUPILIO_ET_CALI_NEXT_POINT
%       3  - PUPILIO_ET_INVALID_PATH
%       4  - PUPILIO_ET_INVALID_PARAM
%       8  - PUPILIO_ET_ALREADY_SET
%       9  - PUPILIO_ET_FAILED
%       10 - PUPILIO_ET_EXCEPTION

    % Initialize outputs
    success = false;
    isSampling = false;
    
    % Validate input
    if nargin < 1 || ~isfield(trackerHandler, 'libName')
        error('getSamplingStatus:invalidInput', 'Invalid or uninitialized tracker handle');
    end
    
    LIB_NAME = trackerHandler.libName;
    
    % Return codes
    SUCCESS = 0;
    CALI_CONTINUE = 1;
    CALI_NEXT_POINT = 2;
    INVALID_PATH = 3;
    INVALID_PARAM = 4;
    ALREADY_SET = 8;
    FAILED = 9;
    EXCEPTION = 10;
    
    try
        % Create pointer for status output (int*)
        statusPtr = libpointer('int32Ptr', int32(0));
        
        % Call the DLL function: int pupil_io_sampling_status(int* status)
        returnCode = calllib(LIB_NAME, 'pupil_io_sampling_status', statusPtr);
        
        % Check return code
        if returnCode == SUCCESS
            % Get the status value
            statusValue = statusPtr.Value;
            success = true;
            
            % Interpret status value
            % status == 0 means not sampling (or sampling stopped)
            % status == 1 means currently sampling (or other positive value)
            isSampling = (statusValue > 0);
            
            % Optional: Provide feedback about status
            if isSampling
                % Sampling is active
            else
                % Not sampling
            end
        else
            % Handle error codes
            switch returnCode
                case INVALID_PATH
                    warning('getSamplingStatus:invalidPath', 'Invalid path error');
                case INVALID_PARAM
                    warning('getSamplingStatus:invalidParam', 'Invalid parameter error');
                case ALREADY_SET
                    warning('getSamplingStatus:alreadySet', 'Already set error');
                case FAILED
                    warning('getSamplingStatus:failed', 'Operation failed');
                case EXCEPTION
                    warning('getSamplingStatus:exception', 'Exception occurred');
                otherwise
                    warning('getSamplingStatus:unknownError', 'Unknown error code: %d', returnCode);
            end
        end
        
        % Clean up pointer
        clear statusPtr;
        
    catch ME
        fprintf('Error checking sampling status: %s\n', ME.message);
        
        % Try alternative: maybe the function name is different
        try
            % Some versions might use a different function name
            statusPtr = libpointer('int32Ptr', int32(0));
            returnCode = calllib(LIB_NAME, 'pupil_io_get_sampling_status', statusPtr);
            if returnCode == SUCCESS
                statusValue = statusPtr.Value;
                success = true;
                isSampling = (statusValue > 0);
            end
            clear statusPtr;
        catch
            % Ignore
        end
    end
end