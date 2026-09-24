classdef Version
% Version  Library version information
    properties (Constant)
        % Major version (incremented for breaking changes)
        MAJOR = 1;
        
        % Minor version (incremented for new features)
        MINOR = 5;
        
        % Patch version (incremented for bug fixes)
        PATCH = 0;
        
        % Release status
        STATUS = 'stable'; % 'alpha', 'beta', 'rc', or 'stable'
        
        % Release date (YYYY-MM-DD)
        DATE = '2026-09-24';
    end
    
    methods (Static)
        function str = string()
            % Get version as string
            str = sprintf('%d.%d.%d', ...
                Version.MAJOR, ...      % Changed from pupilio.Version.MAJOR
                Version.MINOR, ...      % Changed from pupilio.Version.MINOR
                Version.PATCH);         % Changed from pupilio.Version.PATCH
            
            if ~strcmpi(Version.STATUS, 'stable')  % Changed from pupilio.Version.STATUS
                str = [str '-' upper(Version.STATUS)];
            end
        end
        
        function display()
            % Show version information
            fprintf('pupilio version %s (%s)\n', ...
                Version.string(), ...   % Changed from pupilio.Version.string()
                Version.DATE);          % Changed from pupilio.Version.DATE
        end
    end
end