% Copyright (c) 2025 Hangzhou DeepGaze Science & Technology Ltd.
% All rights reserved.
%
% PROPRIETARY SOFTWARE LICENSE
%
% This software and documentation are the proprietary property of Hangzhou
% DeepGaze Science & Technology Ltd ("DeepGaze"). Unauthorized reproduction,
% distribution, or use is strictly prohibited without express written
% permission from DeepGaze.
%
% LICENSE RESTRICTIONS:
% 1. This software is licensed for use only by authorized licensees of DeepGaze.
% 2. No redistribution or derivative works are permitted in any form.
% 3. No reverse engineering, decompilation, or disassembly is permitted.
% 4. No commercial use outside of DeepGaze-authorized applications is permitted.
%
% DISCLAIMER:
% THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
% EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL
% DEEPGAZE OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
% OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING IN ANY WAY OUT OF
% THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% --------------------------------------------------------------------------
% PICTURE VIEWING TASK (MATLAB version with dual cursors, matching Python demo)
%
% Features:
%   - 4-point calibration with validation
%   - Three images shown sequentially (gray_grid, west_lake, old_town)
%   - Trigger 202 sent at each image onset
%   - Real-time gaze cursors: left eye blue, right eye green
%   - Each image displayed until Enter key or 10 sec timeout
%   - Data saved to ./data/deepgaze_demo.csv
% --------------------------------------------------------------------------

try
    %% 1. Initialize Tracker
    config = DefaultConfig();
    config.lang = "en-US";
    config.cali_mode = 4;
    config.face_previewing = 1;
    config.look_ahead = 0;
    config.sampling_rate = 400;
    [success, tracker] = initializeTracker(config);

    if ~success
        error('Tracker initialization failed');
    end

    %% 2. Create Session
    createSession(tracker, 'deepgaze_demo');

    %% 3. Setup Psychtoolbox Display
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'Verbosity', 0);

    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum, [128 128 128]);

    %% 4. Run Calibration with Validation
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);

    %% 5. Start Sampling and Warm-up
    startSampling(tracker);
    WaitSecs(0.1);     % 100 ms to fill buffer

    %% 6. Prepare Images
    imgFolder = 'images';
    imageFiles = {'gray_grid.jpg', 'west_lake.jpg', 'old_town.jpg'};
    maxDuration = 10;          % seconds per image
    triggerValue = 202;

    % Preload textures
    numImages = length(imageFiles);
    textures = cell(1, numImages);
    imgSizes = zeros(numImages, 2);
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

    %% 7. Main Loop: Show Each Image with Dual Cursors
    for i = 1:numImages
        if isempty(textures{i})
            continue;
        end

        % Clear pending keyboard events
        FlushEvents('keyDown');

        % Send trigger (if SDK supports)
        try
            setTrigger(tracker, triggerValue);
        catch
            % ignore if not implemented
        end

        % Draw image
        destRect = CenterRect([0 0 imgSizes(i,2) imgSizes(i,1)], windowRect);
        Screen('DrawTexture', window, textures{i}, [], destRect);
        Screen('Flip', window);

        % Gaze loop
        startTime = GetSecs();
        gotKey = false;
        hasLeftValid = false;
        hasRightValid = false;
        leftGazeX = -65536; leftGazeY = -65536;
        rightGazeX = -65536; rightGazeY = -65536;

        while ~gotKey && (GetSecs() - startTime) < maxDuration
            % Get gaze samples
            [gazeSuccess, left, right, ~] = estimateGaze(tracker);

            if gazeSuccess
                lx = double(left(1)); ly = double(left(2));
                rx = double(right(1)); ry = double(right(2));

                % Check left eye: finite and within screen
                leftFinite = isfinite(lx) && isfinite(ly) && ~any(isnan([lx, ly]));
                leftInScreen = lx >= 0 && lx <= windowRect(3) && ly >= 0 && ly <= windowRect(4);
                if leftFinite && leftInScreen
                    leftGazeX = lx; leftGazeY = ly;
                    hasLeftValid = true;
                end

                % Check right eye
                rightFinite = isfinite(rx) && isfinite(ry) && ~any(isnan([rx, ry]));
                rightInScreen = rx >= 0 && rx <= windowRect(3) && ry >= 0 && ry <= windowRect(4);
                if rightFinite && rightInScreen
                    rightGazeX = rx; rightGazeY = ry;
                    hasRightValid = true;
                end
            end

            % Redraw image and cursors
            Screen('DrawTexture', window, textures{i}, [], destRect);

            % Left eye cursor (blue)
            if hasLeftValid
                radius = 50;
                rectLeft = [leftGazeX-radius, leftGazeY-radius, leftGazeX+radius, leftGazeY+radius];
                if all(rectLeft(3:4) <= windowRect(3:4)) && all(rectLeft(1:2) >= windowRect(1:2))
                    Screen('FillOval', window, [0 0 255], rectLeft, 5);
                end
            end

            % Right eye cursor (green)
            if hasRightValid
                radius = 50;
                rectRight = [rightGazeX-radius, rightGazeY-radius, rightGazeX+radius, rightGazeY+radius];
                if all(rectRight(3:4) <= windowRect(3:4)) && all(rectRight(1:2) >= windowRect(1:2))
                    Screen('FillOval', window, [0 255 0], rectRight, 5);
                end
            end

            Screen('Flip', window);

            % Check for key press (Enter to proceed)
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

        WaitSecs(0.1); % small pause between images
    end

    %% 8. Finish and Save Data
    Screen('FillRect', window, [128 128 128]);
    DrawFormattedText(window, 'Testing completed, saving data to file...', ...
        'center', 'center', [0 0 0]);
    Screen('Flip', window);
    WaitSecs(0.5);

    stopSampling(tracker);
    WaitSecs(0.2);

    dataDir = fullfile(pwd, 'data');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end

    fileName = "deepgaze_demo.csv";
    savePath = fullfile(dataDir, fileName);

    try
        if ~saveDataTo(tracker, savePath)
            warning('Failed to save data to %s', savePath);
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