% Testing all functions in the library
init_test = 0;  % test the initialize and release functions
config_test = 0; % test the configuration function
sampling_test = 0; % test start/stop sampling
get_gaze_test = 0;  %test gaze retrieving
facepreviewer_test = 0; % testing the face previewer
calibration_test = 1; % testing the calibration routine
trigger_test = 0; % testing the send trigger function

%% tracker initialization and release, get version string
if init_test==1
    fprintf('---------------------\n');
    fprintf('tracker initialization and release, get version string\n');
    unitestInitRelease(2);
end

%% tracker configuration
% locale settings
% langs= {'zh', 'en', 'fr', 'es', 'jp', 'ko', 'zh-CN','zh-HK', 'zh-TW', ...
%         'zh-SG', 'zh-MO','en-US','fr-FR','es-ES','jp-JP','ko-KR'};
if config_test==1
    fprintf('---------------------\n');
    fprintf('tracker configuration\n');
    langs={'zh'};

    for i = 1:length(langs)
        currentLang = langs{i};
        uniTestConfiguration(currentLang);
    end
end

%% create_session, start/stop sampling
if sampling_test==1
    fprintf('---------------------\n');
    fprintf('tracker configuration\n');
    unitestStartStopRecording(10);
end

%% getCurrentGaze, estimateGaze, getSamplingStatus
if get_gaze_test==1
    fprintf('---------------------\n');
    fprintf('getCurrentGaze, estimateGaze, getSamplingStatus\n');
    unitestRetrieveGaze();
end

%% facePreviewerInit, facePreviewerStart, facePreviewerStop
if facepreviewer_test==1
    fprintf('---------------------\n');
    fprintf('facePreviewerInit, facePreviewerStart, facePreviewerStop\n');
    unitestFacePreviewer(10);
end

%% Calibration
if calibration_test==1
    fprintf('---------------------\n');
    fprintf('facePreviewerInit, facePreviewerStart, facePreviewerStop\n');
    unitestCalibration(10); % calibrate the tracker and record 10 seconds
end

%% Send Trigger
if trigger_test==1
    fprintf('---------------------\n');
    fprintf('sendTrigger\n');
    unitestSendTrigger();
end
