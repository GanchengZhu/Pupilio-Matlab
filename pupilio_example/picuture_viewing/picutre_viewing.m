% Copyright (c) 2025 Hangzhou DeepGaze Science & Technology Ltd.
% All rights reserved.
%
% PROPRIETARY SOFTWARE LICENSE
%
% --------------------------------------------------------------------------
% PICTURE VIEWING TASK (MATLAB version with dual cursors, matching Python demo)
%
% Features:
%   - 5-point calibration with validation
%   - Three images shown sequentially (gray_grid, west_lake, old_town)
%   - Trigger 202 sent at each image onset
%   - Real-time gaze cursors: left eye red with "L", right eye blue with "R"
%   - Each image displayed until Enter key or 100 s timeout
%   - Data saved to ./data/deepgaze_demo.csv
% --------------------------------------------------------------------------

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
    createSession(tracker, 'deepgaze_demo');

    %% 3. Setup Psychtoolbox Display
    % Preferences must be set before PTB initializes.
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'VisualDebugLevel', 0);
    Screen('Preference', 'SuppressAllWarnings', 1);
    PsychDefaultSetup(2);
    KbName('UnifyKeyNames');         % required for 'KP_Enter', etc.

    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum, [128 128 128]);

    %% 4. Calibrate and Validate
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);                 % validate = true

    %% 5. Start Sampling and Warm-up
    startSampling(tracker);
    WaitSecs(0.1);                   % let a few samples accumulate

    %% 6. Prepare Images
    imgFolder    = 'images';
    imageFiles   = {'gray_grid.jpg', 'west_lake.jpg', 'old_town.jpg'};
    maxDuration  = 100;              % seconds per image
    triggerValue = 202;

    % Preload textures
    numImages = length(imageFiles);
    textures  = cell(1, numImages);
    imgSizes  = zeros(numImages, 2);
    for i = 1:numImages
        imgPath = fullfile(imgFolder, imageFiles{i});
        if ~exist(imgPath, 'file')
            warning('Image %s not found, skipping.', imgPath);
            continue;
        end
        imgMatrix = imread(imgPath);
        textures{i} = Screen('MakeTexture', window, imgMatrix);
        [imgSizes(i,1), imgSizes(i,2), ~] = size(imgMatrix);
    end

    % Gaze cursor visual parameters
    gazeRadius    = 50;
    gazeLineWidth = 5;
    labelFontSize = 32;
    leftEyeColor  = [255 0 0];       % red = left eye
    rightEyeColor = [0 0 255];       % blue = right eye

    Screen('TextFont',  window, 'Arial');
    Screen('TextSize',  window, labelFontSize);
    Screen('TextStyle', window, 1);  % bold

    %% 7. Main Loop: Show Each Image with Dual Cursors
    for i = 1:numImages
        if isempty(textures{i})
            continue;
        end

        % Discard any buffered key events from the previous image
        FlushEvents('keyDown');

        % Send trigger at image onset
        try
            setTrigger(tracker, triggerValue);
        catch
            % setTrigger may not be implemented in every SDK build.
        end

        % Draw the image
        destRect = CenterRect([0 0 imgSizes(i,2) imgSizes(i,1)], windowRect);
        Screen('DrawTexture', window, textures{i}, [], destRect);
        Screen('Flip', window);

        % Gaze loop
        startTime     = GetSecs();
        gotKey        = false;
        hasLeftValid  = false;
        hasRightValid = false;
        leftGazeX  = -65536; leftGazeY  = -65536;
        rightGazeX = -65536; rightGazeY = -65536;

        while ~gotKey && (GetSecs() - startTime) < maxDuration
            % Fetch gaze. `estimateGaze` returns (status, left, right, ts).
            % The per-eye validity flag is element 14 (1 = valid, 0 = invalid,
            % -1 = no face). The outer status code is NOT a good gate — in
            % no-cali mode the DLL returns a nonzero value even for valid
            % samples, so we use the per-eye flags instead.
            [~, left, right, ~] = estimateGaze(tracker);

            % Left eye
            lx = double(left(1)); ly = double(left(2));
            if left(14) == 1 && isfinite(lx) && isfinite(ly)
                leftGazeX = lx; leftGazeY = ly;
                hasLeftValid = true;
            end

            % Right eye
            rx = double(right(1)); ry = double(right(2));
            if right(14) == 1 && isfinite(rx) && isfinite(ry)
                rightGazeX = rx; rightGazeY = ry;
                hasRightValid = true;
            end

            % Redraw image and cursors
            Screen('DrawTexture', window, textures{i}, [], destRect);

            % Left cursor (red) + "L"
            if hasLeftValid
                rectLeft = double([leftGazeX - gazeRadius, leftGazeY - gazeRadius, ...
                                   leftGazeX + gazeRadius, leftGazeY + gazeRadius]);
                Screen('FrameOval', window, leftEyeColor, rectLeft, gazeLineWidth);
                [~, ~, tw, th] = Screen('TextBounds', window, 'L');
                Screen('DrawText', window, 'L', ...
                    leftGazeX - tw/2, leftGazeY - th/2, leftEyeColor);
            end

            % Right cursor (blue) + "R"
            if hasRightValid
                rectRight = double([rightGazeX - gazeRadius, rightGazeY - gazeRadius, ...
                                    rightGazeX + gazeRadius, rightGazeY + gazeRadius]);
                Screen('FrameOval', window, rightEyeColor, rectRight, gazeLineWidth);
                [~, ~, tw, th] = Screen('TextBounds', window, 'R');
                Screen('DrawText', window, 'R', ...
                    rightGazeX - tw/2, rightGazeY - th/2, rightEyeColor);
            end

            Screen('Flip', window);

            % Advance on Enter, abort on ESC
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown
                if keyCode(KbName('Return')) || keyCode(KbName('KP_Enter'))
                    gotKey = true;
                end
                if keyCode(KbName('ESCAPE'))
                    error('Experiment aborted by user');
                end
            end
        end

        WaitSecs(0.1);   % brief pause between images
    end

    %% 8. Finish and Save Data
    Screen('FillRect', window, [128 128 128]);
    DrawFormattedText(window, 'Testing completed, saving data to file...', ...
        'center', 'center', [0 0 0]);
    Screen('Flip', window);
    WaitSecs(0.5);

    stopSampling(tracker);
    WaitSecs(0.2);                   % capture trailing samples

    dataDir = fullfile(pwd, 'data');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end

    savePath = fullfile(dataDir, 'deepgaze_demo.csv');

    try
        if ~saveDataTo(tracker, savePath)
            warning('Failed to save data to %s', savePath);
        else
            fprintf('Data saved to: %s\n', savePath);
        end
    catch
        warning('Failed to save data');
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