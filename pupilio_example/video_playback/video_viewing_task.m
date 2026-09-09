% video_viewing_task.m
% MATLAB version of Python video viewing demo
% Uses VideoReader (built-in) for video playback to avoid GStreamer issues.
% Requires: Psychtoolbox, DeepGaze MATLAB SDK

function video_viewing_task()

try
    %% 1. Participant Information Input (GUI)
    prompt = {'Participant ID (name):', 'Age (years):', 'Gender (male/female):', ...
              'Show gaze cursor? (1=yes, 0=no):'};
    dlg_title = 'Participant Info';
    num_lines = 1;
    defaultans = {'', '18', 'male', '1'};
    answer = inputdlg(prompt, dlg_title, num_lines, defaultans);
    
    if isempty(answer)
        disp('User cancelled.');
        return;
    end
    
    participant_info = struct();
    participant_info.name = answer{1};
    participant_info.age = str2double(answer{2});
    participant_info.gender = answer{3};
    participant_info.show_gaze = str2double(answer{4});
    participant_info.now = datestr(now, 'yyyy_mm_dd_HH_MM_SS');
    
    % Create subject folder
    subj_folder = fullfile('data', sprintf('%s_%d_%s', participant_info.name, ...
                          participant_info.age, participant_info.gender));
    if ~exist(subj_folder, 'dir')
        mkdir(subj_folder);
    end
    
    % Save participant info as JSON
    json_str = jsonencode(participant_info);
    fid = fopen(fullfile(subj_folder, 'subj_info.json'), 'w');
    fprintf(fid, '%s', json_str);
    fclose(fid);
    
    %% 2. Video Selection (list all videos in 'video' folder)
    video_dir = 'video';
    if ~exist(video_dir, 'dir')
        error('Video folder "%s" not found.', video_dir);
    end
    video_files = dir(fullfile(video_dir, '*.mp4'));
    video_files = [video_files; dir(fullfile(video_dir, '*.avi'))];
    video_files = [video_files; dir(fullfile(video_dir, '*.mov'))];
    video_files = [video_files; dir(fullfile(video_dir, '*.mkv'))];
    
    if isempty(video_files)
        error('No video files found in "%s".', video_dir);
    end
    
    % Convert to cell array of full paths
    video_paths = cellfun(@(x) fullfile(video_dir, x), {video_files.name}, 'UniformOutput', false);
    
    % Show selection list
    [sel_idx, ok] = listdlg('ListString', {video_files.name}, ...
                            'PromptString', 'Select videos to play (use Ctrl for multiple):', ...
                            'SelectionMode', 'multiple');
    if ~ok || isempty(sel_idx)
        disp('No videos selected. Exiting.');
        return;
    end
    selected_videos = video_paths(sel_idx);
    
    %% 3. Initialize Tracker
    config = DefaultConfig();
    config.lang = "en-US";          % prevent text encoding issues
    % config.cali_mode = 2;         % 2 or 5 (SDK limitation)
    
    [success, tracker] = initializeTracker(config);
    if ~success
        error('Tracker initialization failed');
    end
    
    %% 4. Create Session
    createSession(tracker, 'video_viewing');
    
    %% 5. Setup Psychtoolbox Display
    PsychDefaultSetup(2);
    Screen('Preference', 'SkipSyncTests', 1);
    Screen('Preference', 'Verbosity', 0);
    screenNum = max(Screen('Screens'));
    [window, windowRect] = Screen('OpenWindow', screenNum, [128 128 128]);
    
    %% 6. Calibrate (uncommented)
    cali = CalibrationGraphics(tracker, window);
    cali.draw(true);   % validate = true
    
    %% 7. Start Sampling
    startSampling(tracker);
    WaitSecs(0.1);     % warm-up
    
    %% 8. Play Videos Sequentially using VideoReader
    show_gaze = participant_info.show_gaze;
    
    for i = 1:length(selected_videos)
        video_path = selected_videos{i};
        [~, video_name, ext] = fileparts(video_path);
        fprintf('Playing: %s\n', [video_name ext]);
        
        % ---- Fixation cross (2 sec) ----
        Screen('TextSize', window, 64);
        DrawFormattedText(window, '+', 'center', 'center', [0 0 0]);
        Screen('Flip', window);
        WaitSecs(2);
        
        % ---- Open video with VideoReader (built-in, no GStreamer) ----
        v = VideoReader(video_path);
        fps = v.FrameRate;
        if fps <= 0
            fps = 30;   % fallback
        end
        duration = v.Duration;
        
        % Calculate display region (maintain aspect ratio)
        imgWidth = v.Width;
        imgHeight = v.Height;
        screenAspect = windowRect(3) / windowRect(4);
        videoAspect = imgWidth / imgHeight;
        if videoAspect > screenAspect
            drawWidth = windowRect(3);
            drawHeight = drawWidth / videoAspect;
        else
            drawHeight = windowRect(4);
            drawWidth = drawHeight * videoAspect;
        end
        destRect = CenterRect([0 0 drawWidth drawHeight], windowRect);
        
        % ---- Playback loop (frame-by-frame) ----
        tStart = GetSecs();
        while hasFrame(v) && (GetSecs() - tStart) < duration
            % Read frame
            frame = readFrame(v);
            tex = Screen('MakeTexture', window, frame);
            Screen('DrawTexture', window, tex, [], destRect);
            
            % ---- Draw gaze cursors (left blue, right green) ----
            if show_gaze
                [gazeSuccess, left, right, ~] = estimateGaze(tracker);
                if gazeSuccess
                    lx = double(left(1)); ly = double(left(2));
                    rx = double(right(1)); ry = double(right(2));
                    % Left eye (blue)
                    if isfinite(lx) && isfinite(ly) && lx>=0 && lx<=windowRect(3) && ly>=0 && ly<=windowRect(4)
                        rect = [lx-30, ly-30, lx+30, ly+30];
                        Screen('FillOval', window, [0 0 255], rect, 3);
                    end
                    % Right eye (green)
                    if isfinite(rx) && isfinite(ry) && rx>=0 && rx<=windowRect(3) && ry>=0 && ry<=windowRect(4)
                        rect = [rx-30, ry-30, rx+30, ry+30];
                        Screen('FillOval', window, [0 255 0], rect, 3);
                    end
                end
            end
            
            % Flip and check for ESC
            Screen('Flip', window);
            Screen('Close', tex);
            
            [keyIsDown, ~, keyCode] = KbCheck();
            if keyIsDown && keyCode(KbName('ESCAPE'))
                error('Experiment aborted by user');
            end
        end
    end
    
    %% 9. Stop Sampling and Save Data
    stopSampling(tracker);
    WaitSecs(0.2);
    
    data_filename = sprintf('eye_data_%s.csv', participant_info.now);
    savePath = fullfile(subj_folder, data_filename);
    if ~saveDataTo(tracker, savePath)
        warning('Failed to save eye data to %s', savePath);
    else
        fprintf('Eye data saved to: %s\n', savePath);
    end
    
    %% 10. Completion Message
    Screen('TextSize', window, 32);
    DrawFormattedText(window, 'Playback completed...', 'center', 'center', [255 255 255]);
    Screen('Flip', window);
    WaitSecs(2);
    
catch ME
    fprintf('\nERROR: %s\n', getReport(ME, 'extended', 'hyperlinks', 'off'));
end

%% 11. Cleanup
try
    releaseTracker(tracker);
catch
end
try
    sca;
catch
end

end