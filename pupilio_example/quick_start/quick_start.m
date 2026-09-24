% quick_start.m
% MATLAB version of quick_start.py
% Demonstrates basic eye-tracking: initialization, calibration, recording, saving.

try
%% 1. Initialize Tracker with default configuration + language setting
    config = DefaultConfig();
    config.lang = "en-US";          % Important: avoids Psychtoolbox text encoding issues.
    
    % Calibration mode. If left unset, DefaultConfig defaults to 2 (two-point).
    % Valid values: 0 (skip calibration), 2 (two-point), 4 (four-point), 5 (five-point).
    config.cali_mode = 5;          % Optional: 2-point, 4-point, or 5-point calibration.
    
    [success, tracker] = initializeTracker(config);
    if ~success
        error('Tracker initialization failed');
    end

    %% 2. Create Session
    createSession(tracker, 'quick_start');

    %% 3. Setup Psychtoolbox Display (fullscreen)
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'Verbosity', 0);
    
    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum, [128 128 128]);

    %% 4. Calibrate and Validate
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);   % validate = true

    %% 5. Start Sampling
    startSampling(tracker);

    %% 6. Display Message and Record for 5 Seconds
    msg = 'Recording... Script will terminate in 5 seconds.';
    Screen('TextSize', window, 32);
    Screen('TextFont', window, 'Arial');
    DrawFormattedText(window, msg, 'center', 'center', [0 0 0]);
    Screen('Flip', window);
    
    WaitSecs(5);   % record for 5 seconds

    %% 7. Stop Sampling and Save Data
    stopSampling(tracker);
    WaitSecs(0.1);   % capture ending samples

    dataDir = fullfile(pwd, 'data');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    savePath = fullfile(dataDir, 'quick_start.csv');
    
    if ~saveDataTo(tracker, savePath)
        warning('Failed to save data to %s', savePath);
    else
        fprintf('Data saved to: %s\n', savePath);
    end

catch ME
    fprintf('\nERROR: %s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
end

%% 8. Cleanup
try
    releaseTracker(tracker);
catch
end

try
    sca;   % close Psychtoolbox window
catch
end
