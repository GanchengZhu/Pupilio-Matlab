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

classdef CalibrationMode < int32
    % CalibrationMode Enumeration representing calibration modes
    %
    % Values:
    %   TWO_POINTS  - 2 (Two-point calibration)
    %   FIVE_POINTS - 5 (Five-point calibration)
    
    enumeration
        TWO_POINTS    (2)  % Two-point calibration
        FIVE_POINTS   (5)  % Five-point calibration
    end
    
    methods
        function numPoints = getNumberOfPoints(obj)
            % Get the number of calibration points
            numPoints = int32(obj);
        end
        
        function isStandard = isStandardMode(obj)
            % Check if this is a standard calibration mode
            isStandard = (obj == CalibrationMode.TWO_POINTS) || ...
                         (obj == CalibrationMode.FIVE_POINTS);
        end
    end
    
    methods (Static)
        function mode = fromInteger(value)
            % Convert integer to CalibrationMode enum
            % Valid inputs: 2 or 5
            if value == 2
                mode = CalibrationMode.TWO_POINTS;
            elseif value == 5
                mode = CalibrationMode.FIVE_POINTS;
            else
                error('Invalid calibration mode: %d (must be 2 or 5)', value);
            end
        end
        
        function allModes = getAllModes()
            % Get all available calibration modes
            allModes = [CalibrationMode.TWO_POINTS, CalibrationMode.FIVE_POINTS];
        end
    end
end