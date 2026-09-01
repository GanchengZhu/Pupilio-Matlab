function status = facePreviewerInit(tracker, udp_address, port, draw_preview_annotation)
    if nargin < 4
        draw_preview_annotation = true;
    end
    if nargin < 3
        error('FacePreviewerInit requires at least three input arguments');
    end
    
    if ~isstruct(tracker) || ~isfield(tracker, 'libName')
        error('tracker must be a struct with libName field');
    end
    
    LIB_NAME = tracker.libName;
    
    if ~ischar(udp_address) || isempty(udp_address)
        error('udp_address must be a non-empty string');
    end
    
    if ~isnumeric(port) || port < 1024 || port > 49151 || mod(port,1) ~= 0
        error('port must be an integer between 1024 and 49151');
    end

    try
        status = calllib(LIB_NAME, 'mlif_pupil_io_previewer_init', udp_address, int32(port), logical(draw_preview_annotation));
    catch ME
        error('Failed to initialize previewer: %s\nEnsure the UDP address and port are correct.', ME.message);
    end
    
    if status == 0
        fprintf('Previewer initialized successfully on %s:%d\n', udp_address, port);
    else
        warning('Previewer initialization failed with error code: %d', status);
    end
end
