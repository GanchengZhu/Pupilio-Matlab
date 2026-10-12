function [sdkVersion, wrapperVersion, success] = getVersionString(trackerHandler)
%GETVERSIONSTRING Get SDK and wrapper version information
%   [sdkVersion, wrapperVersion, success] = getVersionString(trackerHandler)
%
%   Input:
%       trackerHandler - Struct returned by initializeTracker
%   Output:
%       sdkVersion     - SDK version string
%       wrapperVersion - Wrapper version string
%       success        - True if SDK version was retrieved
%
%   Example:
%       [sdkVer, wrapVer, ~] = getVersionString(tracker);

    sdkVersion = 'Unknown';
    wrapperVersion = 'N/A';
    success = false;
    
    if nargin < 1 || ~isstruct(trackerHandler)
        error('getVersionString:invalidInput', 'Valid tracker handle required');
    end
    
    LIB_NAME = trackerHandler.libName;
    
    if ~libisloaded(LIB_NAME)
        error('getVersionString:libraryNotLoaded', 'Library %s is not loaded', LIB_NAME);
    end
    
    % Get SDK version
    try
        sdkVersion = calllib(LIB_NAME, 'pupil_io_get_version');
        if ~isempty(sdkVersion)
            success = true;
        else
            sdkVersion = 'Unknown';
        end
    catch
        try
            sdkVersion = calllib(LIB_NAME, 'pupil_io_version');
            if ~isempty(sdkVersion)
                success = true;
            else
                sdkVersion = 'Unknown';
            end
        catch
            sdkVersion = 'Unknown';
        end
    end
    
    % Get wrapper version - try multiple methods
    versionFound = false;
    
    % Method 1: pupilio.Version (package)
    if ~versionFound
        try
            if exist('pupilio.Version', 'class')
                wrapperVersion = pupilio.Version.string();
                versionFound = true;
            end
        catch
        end
    end
    
    % Method 2: Version (no package)
    if ~versionFound
        try
            if exist('Version', 'class')
                wrapperVersion = Version.string();
                versionFound = true;
            end
        catch ME
            % If Version class exists but has internal errors
            if contains(ME.message, 'pupilio.Version')
                % Try to construct version manually from properties
                try
                    ver = Version;
                    wrapperVersion = sprintf('%d.%d.%d', ver.MAJOR, ver.MINOR, ver.PATCH);
                    if ~strcmpi(ver.STATUS, 'stable')
                        wrapperVersion = [wrapperVersion '-' upper(ver.STATUS)];
                    end
                    versionFound = true;
                catch
                end
            end
        end
    end
    
    % Method 3: Try to get from trackerHandler if stored
    if ~versionFound
        try
            if isfield(trackerHandler, 'version')
                wrapperVersion = trackerHandler.version;
                versionFound = true;
            end
        catch
        end
    end
    
    % Method 4: Try to get from a global variable
    if ~versionFound
        try
            global pupilio_version;
            if ~isempty(pupilio_version)
                wrapperVersion = pupilio_version;
                versionFound = true;
            end
        catch
        end
    end
    
    % Method 5: Try to read from a version file
    if ~versionFound
        try
            versionFile = fullfile(fileparts(mfilename('fullpath')), 'version.txt');
            if exist(versionFile, 'file')
                fid = fopen(versionFile, 'r');
                wrapperVersion = strtrim(fgetl(fid));
                fclose(fid);
                versionFound = true;
            end
        catch
        end
    end
    
    % If still not found
    if ~versionFound
        wrapperVersion = 'N/A';
    end
    
    % Print one-liner
    fprintf('C/C++ SDK:%s / Matlab Wrapper:%s\n', sdkVersion, wrapperVersion);
end