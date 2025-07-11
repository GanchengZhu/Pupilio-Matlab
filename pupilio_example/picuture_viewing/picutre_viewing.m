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
% CALIBRATION DEMONSTRATION
%
% This file demonstrates the configuration and execution of the eye tracking
% calibration process using DeepGaze technology.
%
% Authors:
%   Zhiguo Wang, Gancheng Zhu
%   Hangzhou DeepGaze Science & Technology Ltd.
%   Contact: mianwangming@gmail.com
% --------------------------------------------------------------------------

% run the picture viewing task for 10 seconds
durationSec = 10;

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
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);

    %% Prepare Stimuli
    imgMatrix = imread('old_town.jpg');
    imgTexture = Screen('MakeTexture', window, imgMatrix);
    [imgH, imgW, ~] = size(imgMatrix);

    %% Set up the gaze cursor
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
        [success, left, right, ~] = estimateGaze(tracker);

        % Draw scene
        destRect = CenterRect([0 0 imgW imgH], windowRect);
        Screen('DrawTexture', window, imgTexture, [], destRect);

        % draw cursor for the left eye
        if success && cursor.visible && ~any(isnan(left(1:2)))
            lx = double(left(1));
            ly = double(left(2));
            rect = [lx-cursor.radius, ly-cursor.radius, ...
                lx+cursor.radius, ly+cursor.radius];
            if all(rect(3:4) <= windowRect(3:4)) && all(rect(1:2) >= windowRect(1:2))
                Screen('FillOval', window, [0 0 255], rect);
            end
        end

        % draw cursor for the right eye
        if success && cursor.visible && ~any(isnan(left(1:2)))
            rx = double(right(1));
            ry = double(right(2));
            rect = [rx-cursor.radius, ry-cursor.radius, ...
                rx+cursor.radius, ry+cursor.radius];
            if all(rect(3:4) <= windowRect(3:4)) && all(rect(1:2) >= windowRect(1:2))
                Screen('FillOval', window, [0 255 0], rect);
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


    %% Save Data
    stopSampling(tracker);
    WaitSecs(0.2);

    [filepath,~,~] = fileparts(mfilename('fullpath'));
    dataDir = fullfile(filepath, 'data');
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

    %% Show completion message
    Screen('FillRect', window, [255 255 255]); % gray background
    DrawFormattedText(window, 'Testing completed, press any key to exit...', ...
        'center', 'center', [0 0 0]);
    Screen('Flip', window);
    KbWait(-1); 

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



