function unitestCalibration(durationSec)
% UNITESTCALIBRATION Run Pupilio eye tracker calibration and test routine
%
%   unitestCalibration(durationSec)
%
%   Inputs:
%   Example:
%       unitestCalibration(10);

try
    %% Initialize System
    config = DefaultConfig();
    config.lang = "en-US";
    config.cali_mode = 2;
    config.active_eye = 0;
    
    [success, tracker] = initializeTracker(config);
    if ~success
        error('Tracker initialization failed');
    end
    
    %% Setup Session
    createSession(tracker, 'cali_test');
    
    %% Initialize Display
    PsychDefaultSetup(1);
    Screen('Preference', 'Verbosity', 1); % Increase verbosity for debugging
    Screen('Preference', 'SkipSyncTests', 1); % Skip sync tests (temporarily)

    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum);

    %% Run Calibration
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);
    
    %% Prepare Stimuli    
    imgMatrix = imread('old_town.jpg');
    imgTexture = Screen('MakeTexture', window, imgMatrix);
    [imgH, imgW, ~] = size(imgMatrix);
    
    %% Eye Tracking Parameters
    cursor = struct(...
        'radius', 50, ...
        'color', [0 255 0], ...
        'visible', true);
    
    %% Main Experiment
    startSampling(tracker);
    startTime = GetSecs();
    fprintf('Starting %d second eye-tracking period...\n', durationSec);
    
    while GetSecs() - startTime < durationSec
        % Get gaze data
        % [success, left, ~] = estimateGaze(tracker);
        [success, left, right, bino] = getCurrentGaze(tracker);
        
        % Draw scene
        destRect = CenterRect([0 0 imgW imgH], windowRect);
        Screen('DrawTexture', window, imgTexture, [], destRect);
        
        % Draw cursor if valid
        if success && cursor.visible && ~any(isnan(bino(1:3)))
            x = double(bino(2));
            y = double(bino(3));
            rect = [x-cursor.radius, y-cursor.radius, ...
                    x+cursor.radius, y+cursor.radius];
            
            if all(rect(3:4) <= windowRect(3:4)) && all(rect(1:2) >= windowRect(1:2))
                Screen('FrameOval', window, cursor.color, rect, 5);
            end
        end
        
        % Check for early exit
        [~, ~, keyCode] = KbCheck();
        if keyCode(KbName('ESCAPE'))
            fprintf('Experiment aborted by user\n');
            break;
        end
        
        Screen('Flip', window);
    end

    %% Show completion message
    Screen('FillRect', window, [255 255 255]); % gray background
    DrawFormattedText(window, 'Testing completed, saving data to file...', ...
        'center', 'center', [0 0 0]);
    Screen('Flip', window);

    %% Save Data
    stopSampling(tracker);
    WaitSecs(0.2);
    
    dataDir = fullfile(pwd, 'data');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    
    timeString = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    dataFileName = sprintf('cali_test_%s.txt', timeString);
    savePath = fullfile(dataDir, dataFileName);
    
    if ~saveDataTo(tracker, savePath)
        warning('Failed to save data to %s', savePath);
    else
        fprintf('Data saved to: %s\n', savePath);
    end
    
catch ME
    fprintf('\nERROR: %s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
    
    try
        stopSampling(tracker);
    catch
    end
end

%% Cleanup
try
    releaseTracker(tracker);
catch
end

try
    sca;
catch
end

end