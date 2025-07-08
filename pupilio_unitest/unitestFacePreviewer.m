function unitestFacePreviewer(duration_sec)
% UNITESTFACEPREVIEWER Real-time eye tracker video preview
%   unitestFacePreviewer(duration_sec) shows smooth video feed from eye tracker
%
%   Input:
%       duration_sec - Number of seconds to run the preview (minimum 1 second)
%
%   Example:
%       unitestFacePreviewer(30); % Shows preview for 30 seconds

%% Input validation
if nargin < 1 || duration_sec < 1
    duration_sec = 10;
    warning('Using default duration of 10 seconds');
end

%% Initialize system
config = DefaultConfig();
config.lang = "en";
[success, tracker] = initializeTracker(config);
if ~success
    error('Failed to initialize tracker. Check device connection.');
end

%% Configuration
udp_address = '127.0.0.1';
port = 5000;
previewer_size = [512, 512]; % Standard size for both eyes

%% Setup face previewer with error handling
try
    facePreviewerInit(tracker, udp_address, port);
    facePreviewerStart(tracker);
    
    %% Create optimized figure window
    fig = figure('Name', 'Pupilio Eye Tracker - Live Video Preview', ...
                'NumberTitle', 'off', ...
                'Color', [0.2 0.2 0.2], ...
                'GraphicsSmoothing', 'on', ...
                'DoubleBuffer', 'on');
    
    % Create image placeholders for faster updates
    subplot(1,2,1);
    himgL = imshow(zeros(previewer_size, 'uint8'));
    title('Right CAM');
    axR = gca;
    
    subplot(1,2,2);
    himgR = imshow(zeros(previewer_size, 'uint8'));
    title('Left CAM');
    axL = gca;
    
    colormap(gray);
    
    %% Video update loop
    start_time = tic;
    frame_count = 0;
    update_rate = 30; % Target fps
    update_interval = 1/update_rate;
    last_update = 0;
    
    fprintf('Starting live preview (target %.0f FPS)...\n', update_rate);
    
    while toc(start_time) < duration_sec
        current_time = toc(start_time);
        
        % Throttle updates to target frame rate
        if current_time - last_update >= update_interval
            tic_frame = tic;
            
            % Get new frame
            % [status, imgL, imgR] = facePreviewerGetImages(tracker);
            [imgL, imgR] = getPreviewImages(tracker);

            % if ~status
                % Process and display images
            try
                % Resize and update images
                set(himgR, 'CData', imresize(imgR, previewer_size));
                set(himgL, 'CData', imresize(imgL, previewer_size));
                
                % Update titles with frame rate info
                elapsed_str = sprintf('Time: %.1f/%.1fs', current_time, duration_sec);
                title(axR, {'Right Eye', elapsed_str});
                title(axL, {'Left Eye', elapsed_str});
                
                drawnow limitrate; % Optimized display update
                
                frame_count = frame_count + 1;
            catch ME
                fprintf('Frame %d error: %s\n', frame_count, ME.message);
            end
            % end
            
            last_update = current_time;
            frame_time = toc(tic_frame);
            
            % Adaptive rate control
            if frame_time > update_interval
                update_rate = max(15, update_rate * 0.9); % Reduce FPS if lagging
                update_interval = 1/update_rate;
            end
        end
        
        % Small pause to prevent CPU overload
        pause(0.001);
    end
    
    %% Performance summary
    actual_fps = frame_count / toc(start_time);
    fprintf('Preview completed:\n');
    fprintf('- Duration: %.1f seconds\n', toc(start_time));
    fprintf('- Frames processed: %d\n', frame_count);
    fprintf('- Average FPS: %.1f\n', actual_fps);
    
catch ME
    fprintf('\nError during preview:\n%s\n', getReport(ME, 'extended'));
end

%% Cleanup
try
    fprintf('Stopping preview...\n');
    facePreviewerStop(tracker);
    releaseTracker(tracker);
    if ishandle(fig)
        close(fig);
    end
catch
    fprintf('Error during cleanup\n');
end
end