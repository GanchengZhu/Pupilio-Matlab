function [] = unitestRetrieveGaze()
% brutally call these functions 100 times in a for loop, non-stop

    % with configuration file
    config = DefaultConfig();
    [suc, tk] = initializeTracker(config);  % initialize

    [sdkVersion, wrapperVersion, ~] = getVersionString(tk);
    fprintf('SDK Version: %s, pupilio Version: %s\n', sdkVersion, wrapperVersion);

    for i=1:100
        [~, gazeLeft, gazeRight, timestamp] = estimateGaze(tk);
        fprintf('estimateGaze: %s, left, %s, right, %s\n', timestamp, mat2str(gazeLeft), mat2str(gazeRight));
        pause(0.01);        
        
        [~, leftGaze, rightGaze, binoGaze] = getCurrentGaze(tk);
        fprintf('getCurrentGaze: left, %s, right, %s, bino %s\n',  mat2str(leftGaze), mat2str(rightGaze), mat2str(binoGaze));
        pause(0.01);
    end

    if suc
        releaseTracker(tk);  % release the tracker
    end

end