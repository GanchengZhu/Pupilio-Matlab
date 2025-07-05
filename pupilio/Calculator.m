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


classdef Calculator < handle
    % Calculator - Class to perform calculations related to screen dimensions
    
    properties
        screen_width          % Screen width in pixels
        screen_height         % Screen height in pixels
        physical_screen_width % Physical screen width in inches
        physical_screen_height % Physical screen height in inches
        pixels_per_cm_width   % Precomputed conversion factor
        pixels_per_cm_height  % Precomputed conversion factor
    end
    
    methods
        function obj = Calculator(screen_width, screen_height, physical_screen_width, physical_screen_height)
            obj.screen_width = screen_width;
            obj.screen_height = screen_height;
            obj.physical_screen_width = physical_screen_width;
            obj.physical_screen_height = physical_screen_height;
            
            % Precompute conversion factors (inches to cm conversion included)
            obj.pixels_per_cm_width = screen_width / (physical_screen_width);
            obj.pixels_per_cm_height = screen_height / (physical_screen_height);
        end
        
        function visual_angle = error(obj, gt_pixel, es_pixel, distance)
            % Convert pixels to centimeters
            gt_cm = obj.px2cm(gt_pixel);
            es_cm = obj.px2cm(es_pixel);
            
            % Calculate Euclidean distance in cm
            l2_norm = norm(gt_cm - es_cm);
            
            % Calculate visual angle in degrees
            visual_angle = 2 * rad2deg(atan(l2_norm / (2 * distance)));
        end
        
        function point_cm = px2cm(obj, pixel_point)
            % Convert pixel coordinates to centimeters
            point_cm = [pixel_point(1)/double(obj.pixels_per_cm_width), ...
                       pixel_point(2)/double(obj.pixels_per_cm_height)];
        end
        
        function result = calculate_error_by_sliding_window(obj, gt_point, es_points, distances)
            % Input validation
            if isempty(es_points) || size(es_points, 1) < 5
                result = struct('min_error', [], ...
                               'min_error_es_point', [], ...
                               'gt_point', gt_point);
                return;
            end
            
            % Preallocate error list
            error_list = zeros(size(es_points, 1), 1);
            
            % Calculate errors
            for n = 1:size(es_points, 1)
                error_list(n) = obj.error(gt_point, es_points(n,:), distances(n));
            end
            
            % Find minimum error window
            window_size = 5;
            min_error = inf;
            min_idx = 1;
            
            for i = 1:(length(error_list)-window_size+1)
                window_errors = error_list(i:i+window_size-1);
                current_mean = mean(window_errors);
                
                if current_mean < min_error
                    min_error = current_mean;
                    min_idx = i;
                end
            end
            
            % Prepare results
            result = struct('min_error', min_error, ...
                           'min_error_es_point', mean(es_points(min_idx:min_idx+window_size-1,:)), ...
                           'gt_point', gt_point);
        end
    end
end