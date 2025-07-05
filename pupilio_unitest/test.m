%% Pupilio Eye Tracking Example Script
% This script demonstrates how to:
% 1. Initialize the eye tracker
% 2. Perform calibration
% 3. Collect gaze data
% 4. Save the data to a file


%% Initialize the System
clear all;
close all;
clc;

% Add path to Pupilio classes (if needed)
% addpath('path_to_pupilio_classes');

%% Create Configuration
config = DefaultConfig();
config.cali_mode = 2; % 5-point calibration
config.enable_kappa_verification = 0;
config.enable_debug_logging = 0;
config.log_directory = 'log_et';
config.lang = 'zh-CN';

%% Initialize Pupilio
% Initialize system
[success, tracker] = initializeTracker(config);

if success==0
        % Perform eye tracking operations...
        fprintf('Running with %d-point calibration in %s\n', ...
                tracker.config.cali_mode, tracker.config.lang);
end

%% Create a Session
    % Create a new session with a descriptive name
    sessionName = 'Participant12_Trial3';  % Can also use char array ('Participant12_Trial3')
    
    % Attempt to create the session
    createSession(tracker, sessionName);

%% Start & Stop Sampling
% 3. Start sampling with full status monitoring
    [samplingSuccess, statusCode] = startSampling(tracker);
    if samplingSuccess
        % 4. Run the eye-tracking portion of the experiment
        disp('Beginning eye-tracking experiment...');

        % Create a timer that will run for 3 seconds
        duration = 3; % seconds
        startTime = tic;
        
        while toc(startTime) < duration
            % Get current gaze data
            % [success, left, right, bino] = getCurrentGaze(tracker);
            % 
            % if success
            %     fprintf('Left: [%.3f,%.3f,%.3f] Right: [%.3f,%.3f,%.3f] Binocular: [%.3f,%.3f,%.3f]\n',...
            %             left(1), left(2), left(3), right(1), right(2), right(3), bino(1), bino(2), bino(3));
            % end
            
            [success, left, right, ts] = estimateGaze(tracker);
            if success
              fprintf('Left: [%.2f,%.2f] Right: [%.2f,%.2f] @ %dμs\n',...
                      left(1),left(2),right(1),right(2),ts);
            end

            % Add a small pause to prevent overwhelming the system
            pause(0.001); % 10ms pause
        end

        fprintf('Gaze tracking completed after %.1f seconds.\n', duration);

        % 5. Stop sampling when done (assuming similar stopSampling() exists)
        stopSampling(tracker);
    else
        % Handle specific failure modes
        switch statusCode
            case -1
                error('System error: Library communication failure');
            case 2
                warning('Camera not detected - checking connections...');
                % Add recovery logic here
            otherwise
                error('Unknown sampling error (Code: %d)', statusCode);
        end
    end

%% save data to 
% Save to timestamped file
savePath = fullfile(pwd, 'data', ['eyetrack_' datestr(now,'yyyymmdd_HHMMSS') '.txt']);
if saveDataTo(tracker, savePath)
    disp(['Data saved to: ' savePath]); 
else
    error('Failed to save eye tracking data');
end


%% Clean Up
% With sampling check and retry logic
if ~clearCache(tracker)
    % If first attempt fails, stop sampling and retry
    stopSampling(tracker);
    pause(0.1);
    if ~clearCache(tracker)
        error('Failed to clear cache after retry');
    end
end

%% release the tracker
 % Ensure release
releaseTracker(tracker);
