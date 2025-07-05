function [] = unitestSendTrigger()
% Send triggers 1-255

% set configuration file
config = DefaultConfig();
[~, tk] = initializeTracker(config);  % initialize

if tk.isInitialized
    % create session
    createSession(tk, 'testing');

    % start recording
    startSampling(tk);

    for trigger =1:255
        % pause for 0.1 second
        pause(0.1)
        sendTrigger(tk, trigger);
        fprintf('Sending trigger: %d\n', trigger);
    end
    % stop recording
    stopSampling(tk);

    % save data to file
    dataDir = fullfile(pwd, 'data');
    if ~exist(dataDir, 'dir')
        mkdir(dataDir);
    end
    timeString = char(datetime('now','Format','yyyyMMdd_HHmmss'));
    dataFileName = sprintf('trigger_test_%s.txt', timeString);
    savePath = fullfile(dataDir, dataFileName);
    saveDataTo(tk, savePath);

    releaseTracker(tk);  % release the tracker
end
end