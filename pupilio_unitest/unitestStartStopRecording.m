function [] = unitestStartStopRecording(n)
% brutally call these functions 100 times in a for loop, non-stop
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
        saveDataTo(tk, 'testing.csv');

        releaseTracker(tk);  % release the tracker
    end
    fprintf("____________________________________________\n");
end
end