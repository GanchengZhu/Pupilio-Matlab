% fixation_stability.m
% MATLAB port of the Python estimate_gaze demo.
% Shows left and right eye gaze cursors labelled "L"/"R" over a fixation cross.
% Requires: Psychtoolbox, DeepGaze MATLAB SDK.

function fixation_stability()

try
    %% 1. Configure and Initialize Tracker
    config = DefaultConfig();
    config.lang = "en-US";           % avoid PTB text encoding issues
    config.face_previewing = 1;      % show face preview during calibration
    config.look_ahead = 2;           % heuristic filter depth (0-4)
    config.sampling_rate = 200;      % Hz; falls back if unsupported
    config.cali_mode = 5;            % 5-point calibration (SDK supports 0/2/5/9)

    [success, tracker] = initializeTracker(config);
    if ~success
        error('Tracker initialization failed');
    end

    %% 2. Create Session
    createSession(tracker, 'estimate_gaze_demo');

    %% 3. Setup Psychtoolbox Display
    % Preferences must be set before PTB initializes.
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    PsychDefaultSetup(2);
    KbName('UnifyKeyNames');         % required for 'KP_Enter', etc.

    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum, [128 128 128]); % gray bg
    HideCursor(window);

    %% 4. Calibrate and Validate
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);                 % validate = true

    %% 5. Start Sampling
    startSampling(tracker);
    WaitSecs(0.1);                   % let a few samples accumulate

    %% 6. Visual Parameters
    crossSize      = 20;
    crossLineWidth = 7;
    gazeRadius     = 50;
    gazeLineWidth  = 5;
    labelFontSize  = 32;

    [screenWidth, screenHeight] = Screen('WindowSize', window);
    centerX = screenWidth  / 2;
    centerY = screenHeight / 2;

    bgColor       = [128 128 128];
    crossColor    = [0 255 0];
    leftEyeColor  = [255 0 0];       % red = left eye
    rightEyeColor = [0 0 255];       % blue = right eye

    Screen('TextFont',  window, 'Arial');
    Screen('TextSize',  window, labelFontSize);
    Screen('TextStyle', window, 1);  % bold

    %% 7. Main Loop — runs until ESC/Q or after maxDuration seconds
    startTime   = GetSecs();
    maxDuration = 10;                % seconds
    running     = true;

    while running && (GetSecs() - startTime) < maxDuration
        % Clear
        Screen('FillRect', window, bgColor);

        % Fixation cross
        Screen('DrawLine', window, crossColor, ...
            centerX - crossSize, centerY, centerX + crossSize, centerY, crossLineWidth);
        Screen('DrawLine', window, crossColor, ...
            centerX, centerY - crossSize, centerX, centerY + crossSize, crossLineWidth);

        % Fetch gaze. `estimateGaze` returns (status, left, right, ts).
        % Use the per-eye validity flags (element 14) to gate drawing,
        % not the outer status code — the DLL returns ET_CALI_CONTINUE
        % (nonzero) even when the samples themselves are valid.
        [~, leftEye, rightEye, ~] = estimateGaze(tracker);

        % Left eye cursor (red) + "L"
        lx = double(leftEye(1)); ly = double(leftEye(2));
        if leftEye(14) == 1 && isfinite(lx) && isfinite(ly)
            rect = double([lx - gazeRadius, ly - gazeRadius, ...
                           lx + gazeRadius, ly + gazeRadius]);
            Screen('FrameOval', window, leftEyeColor, rect, gazeLineWidth);
            [~, ~, tw, th] = Screen('TextBounds', window, 'L');
            Screen('DrawText', window, 'L', lx - tw/2, ly - th/2, leftEyeColor);
        end

        % Right eye cursor (blue) + "R"
        rx = double(rightEye(1)); ry = double(rightEye(2));
        if rightEye(14) == 1 && isfinite(rx) && isfinite(ry)
            rect = double([rx - gazeRadius, ry - gazeRadius, ...
                           rx + gazeRadius, ry + gazeRadius]);
            Screen('FrameOval', window, rightEyeColor, rect, gazeLineWidth);
            [~, ~, tw, th] = Screen('TextBounds', window, 'R');
            Screen('DrawText', window, 'R', rx - tw/2, ry - th/2, rightEyeColor);
        end

        Screen('Flip', window);

        % Quit on ESC or Q
        [keyIsDown, ~, keyCode] = KbCheck;
        if keyIsDown
            if keyCode(KbName('ESCAPE')) || keyCode(KbName('q')) || keyCode(KbName('Q'))
                running = false;
            end
        end
    end

    %% 8. Stop Sampling and Save
    stopSampling(tracker);
    WaitSecs(0.1);                   % capture trailing samples

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