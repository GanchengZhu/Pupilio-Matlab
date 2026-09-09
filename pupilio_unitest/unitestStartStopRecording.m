function [] = unitestStartStopRecording(n)

% Set default if not provided
if nargin < 1
    n = 10;
    fprintf('Using default duration: 10 seconds\n');
end

% brutally call these functions n times in a for loop, non-stop
for i =1:n

    % with configuration file
    config = DefaultConfig();
    [~, tk] = initializeTracker(config);  % initialize

    if tk.isInitialized

        % create session
        createSession(tk, 'testing');

        % start recording
        startSampling(tk);

        % pause for 1 second
        pause(1.0)

        % stop recording
        stopSampling(tk);

        % save data to file
        scriptDir = fileparts(mfilename('fullpath'));
        dataDir = fullfile(scriptDir, 'data');

        if ~exist(dataDir, 'dir')
            mkdir(dataDir);
        end

        savePath = fullfile(dataDir, 'testing.csv');
        saveDataTo(tk, savePath);

        releaseTracker(tk);  % release the tracker
    end
    fprintf("____________________________________________\n");
end
end