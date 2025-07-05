function unitestCalibration(durationSec)
% UNITESTCALIBRATION Run Pupilio eye tracker calibration and test routine
%
%   unitestCalibration(durationSec)
%
%   Inputs:
%   Example:
%       unitestCalibration();

try
    %% Initialize System
    config = DefaultConfig();
    config.lang = "en-US";
    config.cali_mode = 2;
    
    [success, tracker] = initializeTracker(config);
    if ~success
        error('Tracker initialization failed');
    end
    
    %% Setup Session
    createSession(tracker, 'cali_test');
    
    %% Initialize Display
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'Verbosity', 0);
    
    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum);

    %% Run Calibration
    cali = Calibration(tracker, window);
    cali.draw(true);
    
    %% Prepare Stimuli    
    imgMatrix = imread('old_town.jpg');
    imgTexture = Screen('MakeTexture', window, imgMatrix);
    [imgH, imgW, ~] = size(imgMatrix);
    
    %% Eye Tracking Parameters
    cursor = struct(...
        'radius', 30, ...
        'color', [0 0 255], ...
        'visible', true);
    
    %% Main Experiment
    startSampling(tracker);
    startTime = GetSecs();
    fprintf('Starting %d second eye-tracking period...\n', durationSec);
    
    while GetSecs() - startTime < durationSec
        % Get gaze data
        [success, left, ~] = estimateGaze(tracker);
        
        % Draw scene
        destRect = CenterRect([0 0 imgW imgH], windowRect);
        Screen('DrawTexture', window, imgTexture, [], destRect);
        
        % Draw cursor if valid
        if success && cursor.visible && ~any(isnan(left(1:2)))
            x = double(left(1));
            y = double(left(2));
            rect = [x-cursor.radius, y-cursor.radius, ...
                    x+cursor.radius, y+cursor.radius];
            
            if all(rect(3:4) <= windowRect(3:4)) && all(rect(1:2) >= windowRect(1:2))
                Screen('FillOval', window, cursor.color, rect);
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
    Screen('FillRect', window, [127 127 127]); % gray background
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