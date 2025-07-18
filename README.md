<div align="left">

## Pupil.IO Matlab SDK

</div>

This repo hosts the Matlab SDK for the Pupil.IO eye-trackers, manufactured by Hangzhou DeepGaze Sci & Tech Co., Ltd. 


## The Pupil.IO eye-tracker

<div align="left">
  <a href="https://raw.githubusercontent.com/GanchengZhu/Pupilio/refs/heads/master/docs/_static/images/intro/about/pupilio_c.PNG">
    <img width="390" height="351" src="https://raw.githubusercontent.com/GanchengZhu/Pupilio/refs/heads/master/docs/_static/images/intro/about/pupilio_c.PNG">
  </a>
</div>

[Pupil.IO](https://www.deep-gaze.com/) is a high-speed, high-precision eye-tracking system featuring an all-in-one (AIO) plug-and-play design that is ideal for both scientific research and clinical applications. With minimal setup (just power on and start tracking), it delivers lab-grade accuracy in a compact, user-friendly form factor.

### Features
- **Precision Tracking**: Capture high-frequency eye movement and pupil dynamics with lab-grade accuracy.
- **Seamless Compatibility**: Native integration with PsychoPy, PyGame, and other Python experimental platforms.
- **Intuitive Workflow**: Simplified calibration, validation, and recording with minimal setup.

### Specifications

| Attribute                | Specification                                 |
|--------------------------|-----------------------------------------------|
| Sample Rate              | 200 Hz        |
| Accuracy                 | 0.5-1°                                          |
| Precision                | 0.03°                                         |
| Blink/Occlusion Recovery | 5 ms @ 200 Hz                |
| Head Box                 | 40 cm x 40 cm @ 70 cm                         |
| Operation Range          | 50 - 90 cm                                    |
| Gaze Signal Delay        | < 25 ms                                       |
| Tracking Technology      | Neural Networks                               |
| Dimension                | 32 cm x 45 cm x 20 cm                         |
| Weight                   | 5 kg [Eye-tracker + Display + Compute Module] |
| Operating System         | Windows 11                                    |
| SDK                      | C/C++/Python/Matlab                           |


## Installation

Please ensure that you have Matlab 2024b (Windows 11) and PTB 3.0.19 installed on the all-in-one tracker, otherwise, PTB may crash randomly.

#### 1. Download the Library

Obtain the library files as a .zip file, and then extract it.

#### 2. Place the Library in a Permanent Location

Save the library folder in a stable directory (e.g., C:\MATLAB_Libraries\ or ~/Documents/MATLAB/).
Please avoid temporary locations (e.g., Desktop, Downloads) to prevent path issues.

#### 3. Add the Library to MATLAB’s Path

- Open MATLAB.
- Go to "Home" → "Set Path".
- Click "Add with Subfolders".
- Select the library’s root folder (e.g., C:\MATLAB_Libraries\library_name).
- Click "Save" to make the path persistent.

#### 4. Verify Installation

Test the library function by running the  example script included in this repo.


## Quick Start
Here is a simple example to get started with Pupilio. The source code is included in the repo, under "pupilio_example/picture_viewing".

```matlab
% run the picture viewing task for 10 seconds
durationSec = 10;

try
    %% Initialize the tracker with custom configrations (e.g., calibration mode)
    config = DefaultConfig();
    config.lang = "en-US";
    config.cali_mode = 2;

    [success, tracker] = initializeTracker(config);
    if ~success
        error('Tracker initialization failed');
    end

    %% Setup a Testing Session
    % Note that the sessing name is critical for system logging
    createSession(tracker, 'cali_test');

    %% Initialize a PTB Display
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

    %% Set up a gaze cursor
    cursor = struct(...
        'radius', 30, ...
        'color', [0 0 255], ...
        'visible', true);

    %% Main Experiment
    % start recording
    startSampling(tracker);
    startTime = GetSecs();
    fprintf('Starting %d second eye-tracking period...\n', durationSec);
    
    % retrieve real-time gaze data and show the gaze cursor in a while loop 
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
    % stop recording before we save data to file
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

    %% Show Task Completion Message
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

```

## Documentation

Comprehensive documentation is available at Pupilio [Documentation](https://pupilio.readthedocs.io/en/latest/start/demo.html).

## Support

If you encounter any issues or have questions, please open an issue on GitHub or contact [zhugc2016@gmail.com](mailto:zhugc2016@gmail.com).

## License

Pupilio is a proprietary software developed by Hangzhou Shenning Technology Co., Ltd. All rights reserved. Unauthorized use, distribution, or modification is prohibited without explicit permission. For licensing inquiries, please contact [zhugc2016@gmail.com](mailto:zhugc2016@gmail.com).

## Acknowledgments
Pupilio is developed and maintained by Hangzhou Shenning Technology Co., Ltd. Special thanks to the community for their valuable feedback and support.

