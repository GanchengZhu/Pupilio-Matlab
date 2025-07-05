function [] = unitestInitRelease(n)
% brutally call these functions 100 times in a for loop, non-stop
for i =1:n
    % with configuration file
    config = DefaultConfig();
    [suc, tk] = initializeTracker(config);  % initialize

    [sdkVersion, wrapperVersion, ~] = getVersionString(tk);
    fprintf('SDK Version: %s, pupilio Version: %s\n', sdkVersion, wrapperVersion);

    if suc
        releaseTracker(tk);  % release the tracker
    end

    pause(0.01); % pause for 10 ms

    % % without configuration file
    % [s, tk2] = initializeTracker();  % initialize
    % if s
    %     releaseTracker(tk2);  % release the tracker
    % end
end
end