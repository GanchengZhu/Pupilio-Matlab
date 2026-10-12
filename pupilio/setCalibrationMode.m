function setCalibrationMode(tracker, mode)
    %SETCALIBRATIONMODE Switch the tracker's calibration mode at runtime.
    %   Mirrors pupil_io_set_cali_mode(int mode, float* cali_points).
    LIB_NAME = tracker.libName;
    SUCCESS_CODE = 0;

    if mode == 0
        caliPoints = single([]);
    else
        caliPoints = tracker.caliPoints;
    end

    caliPtr = libpointer('singlePtr', caliPoints);
    rc = calllib(LIB_NAME, 'pupil_io_set_cali_mode', int32(mode), caliPtr);
    if rc ~= SUCCESS_CODE
        error('setCalibrationMode(%d) failed with code %d', mode, rc);
    end
end