classdef Version
% LIBNAME.VERSION  Library version information
    properties (Constant)
        % Major version (incremented for breaking changes)
        MAJOR = 1;
        
        % Minor version (incremented for new features)
        MINOR = 3;
        
        % Patch version (incremented for bug fixes)
        PATCH = 0;
        
        % Release status
        STATUS = 'stable'; % 'alpha', 'beta', 'rc', or 'stable'
        
        % Release date (YYYY-MM-DD)
        DATE = '2024-03-15';
    end
    
    methods (Static)
        function str = string()
            % Get version as string
            str = sprintf('%d.%d.%d', ...
                pupilio.Version.MAJOR, ...
                pupilio.Version.MINOR, ...
                pupilio.Version.PATCH);
            
            if ~strcmpi(pupilio.Version.STATUS, 'stable')
                str = [str '-' upper(pupilio.Version.STATUS)];
            end
        end
        
        function display()
            % Show version information
            fprintf('pupilio version %s (%s)\n', ...
                pupilio.Version.string(), ...
                pupilio.Version.DATE);
        end
    end
end