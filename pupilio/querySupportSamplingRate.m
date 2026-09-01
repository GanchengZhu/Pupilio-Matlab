function supported_sr = querySupportSamplingRate(trackerHandler)
    [s_c, camera_mode, ~, ~] = getCameraMode(trackerHandler);
    if s_c
        if camera_mode == 1
            supported_sr = [200, 400, 800];
        elseif camera_mode == 2
            supported_sr = [200, 400, 800, 1000];
        elseif camera_mode == 3
            supported_sr = [200];
        elseif camera_mode == 0 || camera_mode == 4
            supported_sr = [200, 400];
        else
            supported_sr = [200];
        end
    else
        supported_sr = [200];
    end
end
