% Copyright (c) 2025 Hangzhou DeepGaze Science & Technology Ltd.
% All rights reserved.
%
% PROPRIETARY SOFTWARE LICENSE
% 
% This software and documentation are the proprietary property of Hangzhou 
% DeepGaze Science & Technology Ltd ("DeepGaze"). Unauthorized reproduction,
% distribution, or use is strictly prohibited without express written 
% permission from DeepGaze.
%
% LICENSE RESTRICTIONS:
% 1. This software is licensed for use only by authorized licensees of DeepGaze.
% 2. No redistribution or derivative works are permitted in any form.
% 3. No reverse engineering, decompilation, or disassembly is permitted.
% 4. No commercial use outside of DeepGaze-authorized applications is permitted.
%
% DISCLAIMER:
% THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER 
% EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES 
% OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. IN NO EVENT SHALL 
% DEEPGAZE OR ITS CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
% SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
% PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
% OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
% WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT ARISING IN ANY WAY OUT OF
% THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%
% --------------------------------------------------------------------------
% CALIBRATION DEMONSTRATION
% 
% This file demonstrates the configuration and execution of the eye tracking
% calibration process using DeepGaze technology.
%
% Authors: 
%   Zhiguo Wang, Gancheng Zhu
%   Hangzhou DeepGaze Science & Technology Ltd.
%   Contact: mianwangming@gmail.com
% --------------------------------------------------------------------------


function success = saveDataTo(trackerHandler, filePath)
%SAVEEYETRACKINGDATA Save recorded eye tracking data to file
%   success = saveEyeTrackingData(trackerHandler, filePath)
%
%   Input:
%       trackerHandler - Struct returned by initializePupilio
%       filePath     - Full path for output data file (string/char)
%   Output:
%       success      - True if data was successfully saved (logical)
%
%   Example:
%       % Save to timestamped file in data directory
%       outputFile = fullfile('data', sprintf('eyedata_%s.dat', datestr(now,'yyyymmdd_HHMMSS')));
%       success = saveEyeTrackingData(tracker, outputFile);
%       if success
%           disp(['Data saved to: ' outputFile]);
%       end

    % Initialize output
    success = false;
    
    % Validate input
    if nargin < 2 || isempty(filePath)
        error('Both trackerHandler and filePath must be provided');
    end
    
    if ~isfield(trackerHandler, 'libName') || ...
       ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Invalid or uninitialized tracker handle');
    end
    
    % Convert to char array and ensure null termination
    filePath = [char(filePath), char(0)];
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0; % Assuming 0 indicates success
    
    try
        % Verify directory exists or create it
        [fileDir, ~, ~] = fileparts(filePath);
        if ~isempty(fileDir)
            if ~exist(fileDir, 'dir')
                try
                    fprintf('Creating output directory: %s\n', fileDir);
                    mkdir(fileDir);
                    % Verify creation was successful
                    if ~exist(fileDir, 'dir')
                        error('Failed to create directory: %s', fileDir);
                    end
                catch ME
                    error('Could not create output directory %s: %s', fileDir, ME.message);
                end
            end
        end
        
        % Check file writability
        if exist(filePath, 'file') && ~isfile(filePath)
            error('Path exists but is not a file: %s', filePath);
        end
        
        % Call the DLL function
        status = calllib(LIB_NAME, 'mlif_pupil_io_save_data_to', filePath);
        
        % Check result
        if status == SUCCESS_CODE
            success = true;
            
            % Verify file was actually created
            if ~exist(strtrim(filePath), 'file')
                warning('Command succeeded but output file not found');
                success = false;
            end
        else
            warning('Data save failed with status: %d', status);
        end
        
    catch ME
        fprintf('Error saving eye tracking data: %s\n', ME.message);
        
        % Provide specific suggestions for common errors
        if contains(ME.message, 'permission')
            disp('> Check write permissions for target directory');
        elseif contains(ME.message, 'invalid path')
            disp('> Ensure path uses correct filesystem separators');
        end
    end
end