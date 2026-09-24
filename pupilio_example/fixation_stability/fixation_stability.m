% fixation_stability.m
% MATLAB version of Python estimate_gaze demonstration
% Shows left and right eye gaze cursors with L/R labels.
% Requires: Psychtoolbox, DeepGaze MATLAB SDK

function fixation_stability()


try
    %% 1. Configure and Initialize Tracker
    config = DefaultConfig();
    config.lang = "en-US";          % prevent text encoding issues
    config.face_previewing = 1;      % show face during calibration
    config.look_ahead = 2;           % heuristic filter
    config.sampling_rate = 400;      % sampling rate (Hz) - will degrade if unsupported
    config.cali_mode = 5;            % 2-point calibration (SDK only supports 2 or 5)

    [success, tracker] = initializeTracker(config);
    if ~success
        error('Tracker initialization failed');
    end

    %% 2. Create Session
    createSession(tracker, 'estimate_gaze_demo');

    %% 3. Setup Psychtoolbox Display
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'Verbosity', 0);
    
    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum, [128 128 128]); % gray
    HideCursor;

    %% 4. Calibrate and Validate
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);

    %% 5. Start Sampling
    startSampling(tracker);
    WaitSecs(0.1);

    %% 6. Visual Parameters
    crossSize = 20;
    crossLineWidth = 7;
    gazeRadius = 50;
    gazeLineWidth = 5;
    labelFontSize = 32;

    [screenWidth, screenHeight] = Screen('WindowSize', window);
    centerX = screenWidth / 2;
    centerY = screenHeight / 2;

    bgColor       = [128 128 128];
    crossColor    = [0 255 0];
    leftEyeColor  = [255 0 0];
    rightEyeColor = [0 0 255];

    % Set font
    Screen('TextFont', window, 'Arial');
    Screen('TextSize', window, labelFontSize);
    Screen('TextStyle', window, 1);  % bold

    %% 7. Main Loop (infinite until ESC or Q)
    startTime = GetSecs();
    maxDuration = 10;  % seconds
    running = true;
    while running && (GetSecs() - startTime) < maxDuration
        % Clear screen
        Screen('FillRect', window, bgColor);

        % Fixation cross
        Screen('DrawLine', window, crossColor, ...
            centerX - crossSize, centerY, centerX + crossSize, centerY, crossLineWidth);
        Screen('DrawLine', window, crossColor, ...
            centerX, centerY - crossSize, centerX, centerY + crossSize, crossLineWidth);

        % Get gaze
        [gazeSuccess, leftEye, rightEye, ~] = estimateGaze(tracker);

        if gazeSuccess
            % Left eye. Only finite/NaN checks are kept — the cursor is
            % drawn at the raw gaze coordinates even when they fall outside
            % the display, since off-screen gaze is a valid measurement.
            lx = double(leftEye(1)); ly = double(leftEye(2));
            leftValid = isfinite(lx) && isfinite(ly) && ~any(isnan([lx, ly]));

            % Right eye.
            rx = double(rightEye(1)); ry = double(rightEye(2));
            rightValid = isfinite(rx) && isfinite(ry) && ~any(isnan([rx, ry]));

            % Draw left cursor (red) + "L"
            if leftValid
                rect = [lx - gazeRadius, ly - gazeRadius, lx + gazeRadius, ly + gazeRadius];
                Screen('FrameOval', window, leftEyeColor, rect, gazeLineWidth);
                % Draw "L" centered at (lx, ly)
                [~, ~, tw, th] = Screen('TextBounds', window, 'L');
                Screen('DrawText', window, 'L', lx - tw/2, ly - th/2, leftEyeColor);
            end

            % Draw right cursor (blue) + "R"
            if rightValid
                rect = [rx - gazeRadius, ry - gazeRadius, rx + gazeRadius, ry + gazeRadius];
                Screen('FrameOval', window, rightEyeColor, rect, gazeLineWidth);
                [~, ~, tw, th] = Screen('TextBounds', window, 'R');
                Screen('DrawText', window, 'R', rx - tw/2, ry - th/2, rightEyeColor);
            end
        end

        Screen('Flip', window);

        % Check for quit (ESC or Q)
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if any(keyCode(KbName('ESCAPE'))) || any(keyCode(KbName('q'))) || any(keyCode(KbName('Q')))
                running = false;
            end
        end
    end

    %% 8. Stop and Save
    stopSampling(tracker);
    WaitSecs(0.1);

    dataDir = fullfile(pwd, 'data');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    savePath = fullfile(dataDir, 'estimate_gaze_demo.csv');

    if ~saveDataTo(tracker, savePath)
        warning('Failed to save data to %s', savePath);
    else
        fprintf('Data saved to: %s\n', savePath);
    end

catch ME
    fprintf('\nERROR: %s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
end

%% 9. Cleanup
try
    releaseTracker(tracker);
catch
end
try
    sca;
catch
end
end