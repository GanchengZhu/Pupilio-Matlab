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


classdef CalibrationGraphics < handle
    properties
        % Constants
        BLACK = [0, 0, 0];
        RED = [255, 0, 0];
        GREEN = [0, 255, 0];
        BLUE = [0, 0, 255];
        WHITE = [255, 255, 255];
        CRIMSON = [220, 20, 60];
        CORAL = [240, 128, 128];
        GRAY = [128, 128, 128];

        % Psychtoolbox handles
        window
        windowRect
        screenNumber
        ifi
        vbl

        % Configuration
        config
        tracker

        % folder
        currentFolder

        % Fonts
        font_size = 32;
        error_font_size = 20;
        instruction_font_size = 24;

        % Timing
        refreshRate = 60;
        animation_frequency

        % calculator for coordinates transformation, etc.
        calculator

        % Resources
        clock_textures = struct();
        clock_height = 100;
        animation_textures = {};
        animation_sizes = {};

        % Calibration points
        calibration_points
        validation_points
        calibration_bounds
        face_in_rect

        % Previewer settings
        previewer_size = [512, 512];
        previewer_positions = struct();
        previewer_textures = struct();

        % State variables
        phase_adjust_position = true;
        calibration_preparing = false;
        validation_preparing = false;
        phase_calibration = false;
        phase_validation = false;
        need_validation = false;
        graphics_finished = false;
        exit = false;
        calibration_drawing_list = 1:5;
        calibration_timer = 0;
        validation_timer = 0;
        validation_left_sample_store = {};
        validation_right_sample_store = {};
        validation_left_eye_distance_store = {};
        validation_right_eye_distance_store = {};
        n_validation = 0;
        error_threshold = 2;
        calibration_point_index = 0;
        drawing_validation_result = false;
        hands_free = false;
        hands_free_adjust_head_wait_time = 10;
        hands_free_adjust_head_start_timestamp = 0;
        validation_finished_timer = 0;
        just_pos_sound_once = false;
        preparing_hands_free_start = 0;
        waitframes = 0;
    end

    methods
        function obj = CalibrationGraphics(tracker, screen)
            % Constructor with Psychtoolbox initialization
            obj.tracker = tracker;
            obj.window = screen;

            % hide the mouse cursor
            HideCursor(obj.window);

            % Get full path of the current script
            currentScriptPath = mfilename('fullpath');
            [currentFolder, ~, ~] = fileparts(currentScriptPath);
            obj.currentFolder = currentFolder;

            % Initialize configuration
            obj.config = tracker.config;
            obj.calibration_points = tracker.caliPoints;

            % Set up text parameters
            Screen('TextFont', obj.window, 'Arial');
            Screen('TextSize', obj.window, obj.font_size);

            % Initialize calculator
            obj.calculator = Calculator(...
                obj.config.screen_width_pix, ...
                obj.config.screen_height_pix, ...
                obj.config.screen_width_cm, ...
                obj.config.screen_height_cm);

            % Initialize calibration bounds
            rec_w = double(600);
            rec_h = rec_w;
            rec_x = double(obj.config.screen_width_pix/2 - rec_w/2);
            rec_y = double(obj.config.screen_height_pix/2 - rec_h/2);
            obj.face_in_rect = [rec_x  rec_y  rec_x + rec_w  rec_y + rec_h];
            obj.calibration_bounds = [0, 0, obj.config.screen_width_pix, obj.config.screen_height_pix];

            % Initialize validation points
            obj.validation_points = [...
                0.5, 0.08; ...
                0.08, 0.5; ...
                0.92, 0.5; ...
                0.5, 0.92];

            % target animation frequence
            obj.animation_frequency = obj.config.cali_target_animation_frequency;

            % Shuffle validation points
            % obj.validation_points = obj.validation_points(randperm(size(obj.validation_points, 1)), :);
            obj.validation_points = [obj.validation_points; 0.5, 0.5];

            % Scale validation points
            obj.validation_points(:,1) = obj.validation_points(:,1) * double(obj.calibration_bounds(3));
            obj.validation_points(:,2) = obj.validation_points(:,2) * double(obj.calibration_bounds(4));

            % Load resources (placeholder - actual implementation would load images)
            obj.load_resources();

            % Initialize previewer if needed
            obj.previewer_positions.left = [...
                obj.previewer_size(1)/2 + 79 - obj.previewer_size(1)/2, ...
                obj.config.screen_height_pix/2 - obj.previewer_size(2)/2];
            obj.previewer_positions.right = [...
                obj.config.screen_width_pix - obj.previewer_size(1)/2 - 79 - obj.previewer_size(1)/2, ...
                obj.config.screen_height_pix/2 - obj.previewer_size(2)/2];

            % Initialize validation sample stores
            obj.initialize_variables();

            % Get frame duration
            obj.ifi = Screen('GetFlipInterval', obj.window);
            obj.refreshRate = 1/obj.ifi;
            fprintf('Actual refresh rate: %.2f Hz\n', obj.refreshRate);

            % initialize face previewer
            if obj.config.face_previewing
                udp_address = '127.0.0.1';  % Localhost
                port = 5000;                % Example port number
                facePreviewerInit(obj.tracker, udp_address, port);
                facePreviewerStart(obj.tracker);
            end

            %     % Set up fonts etc.
            %     Screen('Preference', 'TextAntiAliasing', 2); % Full anti-aliasing
            %     Screen('Preference', 'TextEncodingLocale', 'zh_CN.UTF-8'); % Set encoding
            %
            %     % Specify a Chinese-compatible font (choose one):
            %     chinese_fonts = {'Microsoft YaHei UI', 'Microsoft YaHei UI Light',...
            %         'Microsoft JhengHei UI Light', 'Microsoft JhengHei UI', 'Microsoft JhengHei Light',...
            %         'Microsoft JhengHei', 'Lucida Sans Unicode'};
            %     font_found = 0;
            %
            %     for font = chinese_fonts
            %         try
            %             Screen('TextFont', win, font{1});
            %             font_found = 1;
            %             break;
            %         catch
            %             continue;
            %         end
            %     end
            %
            %     if ~font_found
            %         error('No Chinese font available! Install fonts: %s', strjoin(chinese_fonts, ', '));
            %     end

        end

        function load_resources(obj)
            % Load clock number textures (placeholder)
            for n = 0:9
                % In a real implementation, you would load actual images here
                % obj.clock_textures.(sprintf('num%d', n)) = Screen('MakeTexture', ...);
            end

            % Initialize animation textures
            max_size = obj.config.cali_target_img_maximum_size;
            min_size = obj.config.cali_target_img_minimum_size;

            for i = 1:20
                size_val = min_size + (max_size - min_size) * i / 19;
                obj.animation_sizes{i} = [size_val, size_val];
                [tar_img, ~, alpha] = imread(fullfile(obj.currentFolder, 'asset', 'windmill.png'));
                resizedImage = imresize(tar_img, obj.animation_sizes{i});
                obj.animation_textures{i} = Screen('MakeTexture', obj.window, resizedImage);
            end
        end

        function initialize_variables(obj)
            obj.phase_adjust_position = true;
            obj.calibration_preparing = false;
            obj.validation_preparing = false;
            obj.phase_calibration = false;
            obj.phase_validation = false;
            obj.need_validation = false;
            obj.graphics_finished = false;
            obj.exit = false;
            obj.calibration_drawing_list = 1:5;
            obj.calibration_timer = 0;
            obj.validation_timer = 0;

            n_points = length(obj.validation_points);
            obj.validation_left_sample_store = cell(1, n_points);
            obj.validation_right_sample_store = cell(1, n_points);
            obj.validation_left_eye_distance_store = cell(1, n_points);
            obj.validation_right_eye_distance_store = cell(1, n_points);

            obj.n_validation = 0;
            obj.error_threshold = 2;
            obj.calibration_point_index = 0;
            obj.drawing_validation_result = false;
            obj.hands_free = false;
            obj.hands_free_adjust_head_wait_time = 10;
            obj.hands_free_adjust_head_start_timestamp = 0;
            obj.validation_finished_timer = 0;
        end

        function draw_error_line(obj, ground_truth_point, estimated_point, error_color)
            % Draw error line between ground truth and estimated points

            % convert the coordinates into double
            ground_truth_point = double(ground_truth_point);
            estimated_point = double(estimated_point);

            Screen('TextSize', obj.window, obj.font_size);
            DrawFormattedText(obj.window, '+', ...
                ground_truth_point(1), ground_truth_point(2), obj.GREEN);

            if isempty(estimated_point) || any(isnan(estimated_point))
                return;
            end

            DrawFormattedText(obj.window, '+', ...
                estimated_point(1), estimated_point(2), error_color);

            Screen('DrawLine', obj.window, obj.BLACK, ...
                ground_truth_point(1), ground_truth_point(2), ...
                estimated_point(1), estimated_point(2), 1);
        end

        function draw_error_text(obj, min_error, ground_truth_point, is_left)
            % Draw error text on screen
            Screen('TextSize', obj.window, obj.error_font_size);

            if is_left
                error_text = sprintf('L: %.2f°', min_error);
                height_position = 1;
            else
                error_text = sprintf('R: %.2f°', min_error);
                height_position = 2;
            end

            DrawFormattedText(obj.window, error_text, ...
                double(ground_truth_point(1)), ...
                double(ground_truth_point(2) + 20 * height_position), ...
                obj.BLACK);

            % reset font size
            Screen('TextSize', obj.window, obj.font_size);

        end

        function draw_recali_and_continue_tips(obj)
            % Draw recalibration and continue tips
            legend_texts = {...
                obj.config.instruction_calibration_over, ...
                obj.config.instruction_recalibration};

            % Position based on language
            if contains(obj.config.lang, 'en-')
                x = obj.config.screen_width_pix - 600;
                y = obj.config.screen_height_pix - 96;
            elseif contains(obj.config.lang, 'zh-')
                x = obj.config.screen_width_pix - 464;
                y = obj.config.screen_height_pix - 96;
            elseif contains(obj.config.lang, 'jp-')
                x = obj.config.screen_width_pix - 712;
                y = obj.config.screen_height_pix - 96;
            elseif contains(obj.config.lang, 'ko-')
                x = obj.config.screen_width_pix - 464;
                y = obj.config.screen_height_pix - 96;
            elseif contains(obj.config.lang, 'fr-')
                x = obj.config.screen_width_pix - 715;
                y = obj.config.screen_height_pix - 96;
            elseif contains(obj.config.lang, 'es-')
                x = obj.config.screen_width_pix - 512;
                y = obj.config.screen_height_pix - 144;
            else
                error('Unknown language: %s, please check the code.', obj.config.lang);
            end

            Screen('TextSize', obj.window, obj.error_font_size);
            for n = 1:length(legend_texts)
                lines = strsplit(legend_texts{n}, '\n');
                for m = 1:length(lines)
                    DrawFormattedText(obj.window, lines{m}, ...
                        double(x), double(y), obj.BLACK);
                    y = y + 25;
                end
            end

            % reset font size
            Screen('TextSize', obj.window, obj.font_size);
        end

        function draw_legend(obj)
            % Draw legend on screen
            legend_texts = {...
                obj.config.legend_target, ...
                obj.config.legend_left_eye, ...
                obj.config.legend_right_eye};
            color_list = {obj.GREEN, obj.CRIMSON, obj.CORAL};
            x = 128;
            y = obj.config.screen_height_pix - 128;

            Screen('TextSize', obj.window, obj.error_font_size);
            for n = 1:length(legend_texts)
                DrawFormattedText(obj.window, '+', ...
                    double(x), double(y), color_list{n});
                DrawFormattedText(obj.window, legend_texts{n}, ...
                    double(x + 20), double(y), obj.BLACK);
                y = y + 25;
            end

            % reset font size
            Screen('TextSize', obj.window, obj.font_size);
        end

        function draw_animation(obj, point, time_elapsed)
            % Draw animation at point
            index = mod(floor(time_elapsed * (obj.animation_frequency * 20)), 20) + 1;
            width = obj.animation_sizes{index}(1);
            height = obj.animation_sizes{index}(2);

            % fprintf('Calibration point coordinates: (%.2f, %.2f)\n', point(1), point(2));

            % In a real implementation, you would draw the actual texture
            Screen('DrawTexture', obj.window, obj.animation_textures{index}, [], ...
                [point(1) - double(width/2), point(2) - double(height/2), ...
                point(1) + double(width/2), point(2) + double(height/2)]);
        end

        function draw(obj, validate, bg_color)
            % Main draw method with Psychtoolbox
            if nargin < 2
                validate = false;
            end
            if nargin < 3
                bg_color = obj.WHITE;
            end

            % initialize the (re)calibration routine
            trackerCalibrationInit(obj.tracker);
            obj.initialize_variables();
            obj.need_validation = validate;

            targetIFI = 1/60;
            obj.waitframes = round(targetIFI/obj.ifi);
            if obj.waitframes < 1
                obj.waitframes = 1;
            end

            % Animation loop
            obj.vbl = Screen('Flip', obj.window);

            while ~obj.exit
                % Initialize response flags
                user_response_continue = false;
                user_response_recali = false;

                % Check keyboard input
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown
                    user_response_continue = keyCode(KbName('Return')) || keyCode(KbName('space'));
                    user_response_recali = keyCode(KbName('r'));

                    if keyCode(KbName('q'))
                        obj.exit = true;
                    end

                    clearKeyboardEvents(); % Clear any buffered keyboard events
                end

                % Handle state transitions based on user responses
                if user_response_continue
                    if obj.phase_adjust_position
                        % Transition from adjust position to calibration preparation
                        obj.phase_adjust_position = false;
                        obj.calibration_preparing = true;

                    elseif obj.calibration_preparing
                        % Transition to calibration phase
                        obj.phase_adjust_position = false;
                        obj.calibration_preparing = false;
                        obj.phase_calibration = true;

                    elseif obj.validation_preparing
                        % Transition to validation phase
                        obj.phase_validation = true;
                        obj.validation_preparing = false;

                    elseif obj.phase_validation && obj.drawing_validation_result
                        % Exit validation results screen
                        obj.phase_validation = false;
                    end
                elseif user_response_recali && obj.drawing_validation_result
                    % Handle recalibration request
                    obj.phase_validation = false;
                    obj.drawing_validation_result = false;
                    obj.draw(obj.need_validation, bg_color);
                    return;
                end

                % Clear the screen
                Screen('FillRect', obj.window, bg_color);

                % Draw the appropriate phase content
                if obj.phase_calibration && ~obj.phase_adjust_position && ~obj.calibration_preparing
                    obj.draw_calibration_point();
                elseif obj.calibration_preparing
                    obj.draw_calibration_preparing();
                elseif obj.validation_preparing
                    obj.draw_validation_preparing();
                elseif obj.phase_adjust_position
                    if obj.config.face_previewing
                        obj.draw_previewer();
                    end
                    obj.draw_adjust_position();
                elseif obj.phase_validation
                    obj.draw_validation_point();
                elseif ~obj.phase_validation && ~obj.calibration_preparing && ...
                        ~obj.phase_calibration && ~obj.phase_adjust_position && ...
                        ~obj.validation_preparing

                    % All phases completed
                    obj.graphics_finished = true;
                    obj.exit = true;
                end

                % Flip at 60Hz
                obj.vbl = Screen('Flip', obj.window, obj.vbl + (obj.waitframes - 0.5) * obj.ifi);
            end
        end

        function draw_hands_free(obj, validate, bg_color)
            % Hands-free draw method with Psychtoolbox
            if nargin < 2
                validate = false;
            end
            if nargin < 3
                bg_color = obj.WHITE;
            end

            obj.initialize_variables();
            obj.need_validation = validate;
            obj.preparing_hands_free_start = 0;
            obj.hands_free = true;

            targetIFI = 1/60;
            obj.waitframes = round(targetIFI/obj.ifi);
            if obj.waitframes < 1
                obj.waitframes = 1;
            end
            % Initialize timing
            obj.vbl = Screen('Flip', obj.window);

            while ~obj.exit
                % Handle keyboard input
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown && keyCode(KbName('q'))
                    obj.exit = true;
                end

                % Clear screen
                Screen('FillRect', obj.window, bg_color);

                % Draw current phase
                if obj.phase_calibration
                    obj.draw_calibration_point();
                elseif obj.calibration_preparing
                    obj.draw_calibration_preparing_hands_free();
                elseif obj.phase_adjust_position
                    obj.draw_adjust_position();
                elseif obj.phase_validation
                    obj.draw_validation_point();
                elseif ~obj.phase_validation && ~obj.calibration_preparing && ...
                        ~obj.phase_calibration && ~obj.phase_adjust_position && ...
                        ~obj.validation_preparing
                    obj.graphics_finished = true;
                    break;
                end

                % Flip at 60Hz
                obj.vbl = Screen('Flip', obj.window, obj.vbl + (obj.waitframes - 0.5) * obj.ifi);
            end
        end

        % Additional helper methods
        function draw_calibration_point(obj)
            if obj.calibration_timer == 0
                % clear the screen first
                obj.clearCalibrationSceen();
                % Play sound here
                obj.playBeepSound();
                 % Start timer
                obj.calibration_timer = GetSecs;
            end

            time_elapsed = GetSecs - obj.calibration_timer;

            % Get calibration status from tracker
            status = getCalibrationStatus(obj.tracker, obj.calibration_point_index);
            % fprintf('Current index %d', status);

            % Handle status
            if status == ET_ReturnCode.ET_CALI_CONTINUE

                obj.calibration_point_index = obj.calibration_point_index;

            elseif status == ET_ReturnCode.ET_CALI_NEXT_POINT
                if obj.calibration_point_index + 1 == length(obj.calibration_points)
                    % Finished all points
                    obj.phase_calibration = false;
                    obj.validation_preparing = false;
                    if obj.need_validation && ~obj.hands_free
                        obj.validation_preparing = true;
                        obj.phase_validation = false;
                    elseif obj.hands_free && obj.need_validation
                        obj.phase_calibration = false;
                        obj.validation_preparing = false;
                        obj.phase_validation = true;
                    else
                        obj.exit = true;
                        obj.graphics_finished = true;
                    end
                else
                    % Move to next point
                    obj.calibration_point_index = obj.calibration_point_index + 1;
                    obj.calibration_timer = 0;
                end

            elseif status == ET_ReturnCode.ET_SUCCESS
                % Calibration complete
                obj.phase_calibration = false;
                obj.validation_preparing = false;
                if obj.need_validation && ~obj.hands_free
                    obj.validation_preparing = true;
                elseif obj.hands_free && obj.need_validation
                    obj.phase_calibration = false;
                    obj.validation_preparing = false;
                    obj.phase_validation = true;
                else
                    % clear the screen when the calibration process is
                    % completed
                    Screen('FillRect', obj.window, obj.WHITE);
                    obj.exit = true;
                    obj.graphics_finished = true;
                    return;
                end
            end

            % Draw current calibration point
            if obj.calibration_point_index < length(obj.calibration_points)
                point = obj.calibration_points(obj.calibration_point_index+1,:);
                point = double(point);
                px = double(point(1));
                py = double(point(2));
                obj.draw_animation([px, py], time_elapsed);
            end
        end

        function draw_calibration_preparing(obj)
            % Draw calibration preparation instructions
            text = obj.config.instruction_enter_calibration;
            obj.draw_text_center(text);
        end

        function draw_validation_preparing(obj)
            % Draw validation preparation instructions
            text = obj.config.instruction_enter_validation;
            obj.draw_text_center(text);
        end

        function draw_adjust_position(obj)
            % Draw position adjustment interface
            if ~obj.just_pos_sound_once
                % Play sound here
                obj.just_pos_sound_once = true;
            end

            % Get face position from tracker
            [status, face_position] = getFacePosition(obj.tracker);

            % Calculate eyebrow center point
            fp_x = double(obj.config.screen_width_pix)/2.0 + double((face_position(1) - 172.08) * 10.0);
            fp_y = double(obj.config.screen_height_pix)/2.0 + double((face_position(2) - 96.79) * 10.0);
            eyebrow_center = [fp_x, fp_y];

            % Determine rectangle color
            if IsInRect(eyebrow_center(1), eyebrow_center(2), obj.face_in_rect)
                rect_color = obj.GREEN;
                instruction_text = ' ';
            else
                rect_color = obj.RED;
                instruction_text = obj.config.instruction_head_center;
            end

            % Determine face texture and color based on Z position
            face_z = face_position(3);
            if face_z == 0
                face_z = 65536;
            end

            color_ratio = 280 / abs(face_z);
            if face_z > -530 || face_z < -630
                % Use frowning face
                [face_img, ~, alpha] = imread(fullfile(obj.currentFolder, 'asset', 'frowning-face.png'));
                if face_z > -530
                    instruction_text = obj.config.instruction_face_far;
                elseif face_z < -630
                    instruction_text = obj.config.instruction_face_near;
                end
            else
                % Use smiling face
                [face_img, ~, alpha] = imread(fullfile(obj.currentFolder, 'asset', 'smiling-face.png'));
            end

            % Draw rectangle
            Screen('FrameRect', obj.window, rect_color, obj.face_in_rect, 5);

            % Draw face if position data is valid
            if status == ET_ReturnCode.ET_SUCCESS || any(face_position ~= 0)
                face_size = round(256 * color_ratio);

                % Convert to 4-channel RGBA (Red, Green, Blue, Alpha)
                if size(face_img, 3) == 3
                    face_img(:,:,4) = alpha; % Add alpha channel
                end
                face_texture =  Screen('MakeTexture', obj.window, face_img);
                [textureWidth, textureHeight] = Screen('WindowSize', face_texture);
                face_rect = CenterRectOnPoint(...
                    [0 0 textureWidth textureHeight], ...
                    eyebrow_center(1), ...
                    eyebrow_center(2));

                try
                    texInfo = Screen('GetWindowInfo', face_texture);
                    isTexture = ~isempty(texInfo) && texInfo(1) > 0;
                catch
                    isTexture = false;
                end

                if all(face_rect > 0, 'all')
                    face_rect = [double(face_rect(1)) double(face_rect(2)) double(face_rect(3)) double(face_rect(4))];
                    Screen('DrawTexture', obj.window, face_texture, [], face_rect);
                end
            end

            % Draw instruction text, force conversion to prevent problems
            try
                instruction_text = char(instruction_text); % Force Unicode conversion
            catch
                instruction_text = unicode2native(instruction_text, 'UTF-8');
            end

            % Get text bounds (accounts for wrapping) and then show it below
            % the face
            bounds = Screen('TextBounds', obj.window, instruction_text);
            y_offset = double(face_size + 20.0);
            DrawFormattedText(obj.window, instruction_text, ...
                eyebrow_center(1) - bounds(3)/2,...
                eyebrow_center(2) + y_offset, obj.BLACK);

            % Handle hands-free mode
            if obj.hands_free
                if (-630 <= face_z && face_z <= -530 && ...
                        IsInRect(eyebrow_center(1), eyebrow_center(2), obj.face_in_rect) && ...
                        obj.hands_free_adjust_head_wait_time <= 0)
                    % Criteria met
                    obj.phase_adjust_position = false;
                    obj.calibration_preparing = true;
                elseif (-630 <= face_z && face_z <= -530 && ...
                        IsInRect(eyebrow_center(1), eyebrow_center(2), obj.face_in_rect) && ...
                        obj.hands_free_adjust_head_wait_time > 0)
                    % Countdown
                    if obj.hands_free_adjust_head_start_timestamp == 0
                        obj.hands_free_adjust_head_start_timestamp = GetSecs;
                    else
                        current_time = GetSecs;
                        obj.hands_free_adjust_head_wait_time = obj.hands_free_adjust_head_wait_time - ...
                            (current_time - obj.hands_free_adjust_head_start_timestamp);
                        obj.hands_free_adjust_head_start_timestamp = current_time;
                    end
                else
                    obj.hands_free_adjust_head_start_timestamp = 0;
                end
            end
        end

        function draw_text_center(obj, text)
            % Draw text centered on screen
            lines = strsplit(text, '\n');
            total_height = length(lines) * 40;
            start_y = double(obj.config.screen_height_pix/2 - total_height/2);

            for i = 1:length(lines)
                bounds = Screen('TextBounds', obj.window, lines{i});
                start_x = double(obj.config.screen_width_pix/2 - bounds(3)/2);
                DrawFormattedText(obj.window, lines{i}, ...
                    start_x,...
                    start_y + double((i-1)*40), obj.BLACK);
            end
        end

        function draw_calibration_preparing_hands_free(obj)
            % Hands-free calibration preparation
            if obj.preparing_hands_free_start == 0
                obj.preparing_hands_free_start = GetSecs;
                % Play instruction sound here
            end

            time_elapsed = GetSecs - obj.preparing_hands_free_start;
            if time_elapsed <= 9.0
                text = obj.config.instruction_hands_free_calibration;
                obj.draw_text_center(text);

                % Draw countdown
                remaining = ceil(10 - time_elapsed);
                % In a real implementation, you would draw the clock textures
                % Screen('DrawTexture', obj.window, obj.clock_textures.(sprintf('num%d', remaining)), ...
                %     [], [obj.config.screen_width_pix/2-50, obj.config.screen_height_pix/2-200, obj.config.screen_width_pix/2+50, obj.config.screen_height_pix/2-100]);

                % Placeholder: draw the number as text
                DrawFormattedText(obj.window, num2str(remaining), ...
                    'center', double(obj.config.screen_height_pix/2 - 150), obj.BLACK);
            else
                obj.calibration_preparing = false;
                obj.phase_calibration = true;
            end
        end

        function draw_validation_point(obj)
            % Draw validation point and collect samples
            if isempty(obj.calibration_drawing_list)
                % Validation complete
                if obj.n_validation == 1
                    obj.repeat_calibration_point();
                else
                    if obj.hands_free && obj.validation_finished_timer == 0
                        obj.validation_finished_timer = GetSecs;
                    elseif obj.hands_free && obj.validation_finished_timer > 0
                        if GetSecs - obj.validation_finished_timer > 3
                            obj.phase_validation = false;
                        end
                    end

                    % Save validation results
                    if obj.config.enable_validation_result_saving
                        calibrationDir = fullfile(pwd, 'calibration', obj.config.session_name);
                        if ~exist(calibrationDir, 'dir')
                            mkdir(calibrationDir);
                        end

                        % timeString = datetime('now', 'Format', 'yyyy-MM-dd_HH-mm-ss');
                        % save(fullfile(calibrationDir, [char(timeString) '.csv']), ...
                        %     'obj.validation_left_samples', 'obj.validation_right_samples', ...
                        %     'obj.validation_ground_truth_point', 'obj.validation_left_eye_distances', ...
                        %     'obj.validation_right_eye_distances');
                    end

                    % Draw validation results
                    for idx = 1:length(obj.validation_points)
                        left_samples = obj.validation_left_sample_store{idx};
                        right_samples = obj.validation_right_sample_store{idx};
                        left_distances = obj.validation_left_eye_distance_store{idx};
                        right_distances = obj.validation_right_eye_distance_store{idx};
                        ground_truth = obj.validation_points(idx, :);

                        if ~isempty(left_samples)
                            res = obj.calculator.calculate_error_by_sliding_window(...
                                ground_truth, left_samples, left_distances);

                            if ~isempty(res)
                                obj.draw_error_line(res.gt_point, res.min_error_es_point, obj.CRIMSON);
                                obj.draw_error_text(res.min_error, ground_truth, true);
                            end
                        end

                        if ~isempty(right_samples)
                            res = obj.calculator.calculate_error_by_sliding_window(...
                                ground_truth, right_samples, right_distances);
                            if ~isempty(res)
                                obj.draw_error_line(ground_truth, res.min_error_es_point, obj.CRIMSON);
                                obj.draw_error_text(res.min_error, ground_truth, false);
                            end
                        end
                    end

                    obj.draw_legend();
                    obj.draw_recali_and_continue_tips();
                    obj.drawing_validation_result = true;
                end
            else
                % Collect samples for current validation point
                if obj.validation_timer == 0
                    % clear the screen first
                    obj.clearCalibrationSceen();
                    % Play sound here
                    obj.playBeepSound();
                    % Start timer and play sound
                    obj.validation_timer = GetSecs;
                end

                time_elapsed = GetSecs - obj.validation_timer;
                if time_elapsed > 1.5
                    % Move to next point
                    obj.calibration_drawing_list(end) = [];
                    obj.validation_timer = 0;
                    if isempty(obj.calibration_drawing_list)
                        obj.n_validation = obj.n_validation + 1;
                    end
                    % Stop sound here
                else
                    % Draw current point and collect samples
                    point = obj.validation_points(obj.calibration_drawing_list(end), :);
                    obj.draw_animation(point, time_elapsed);

                    % Get gaze samples
                    [status, left_sample, right_sample, ts] = estimateGaze(obj.tracker);

                    if time_elapsed > 0 && time_elapsed <= 1.5
                        left_gaze = [left_sample(1)*double(obj.config.screen_width_pix/1920), ...
                            left_sample(2)*double(obj.config.screen_height_pix/1080)];
                        right_gaze = [right_sample(1)*double(obj.config.screen_width_pix/1920), ...
                            right_sample(2)*double(obj.config.screen_height_pix/1080)];

                        if left_sample(14) == 1
                            obj.validation_left_sample_store{obj.calibration_drawing_list(end)} = ...
                                [obj.validation_left_sample_store{obj.calibration_drawing_list(end)}; left_gaze];
                            obj.validation_left_eye_distance_store{obj.calibration_drawing_list(end)} = ...
                                [obj.validation_left_eye_distance_store{obj.calibration_drawing_list(end)}; abs(left_sample(6))/10];
                        end

                        if right_sample(14) == 1
                            obj.validation_right_sample_store{obj.calibration_drawing_list(end)} = ...
                                [obj.validation_right_sample_store{obj.calibration_drawing_list(end)}; right_gaze];
                            obj.validation_right_eye_distance_store{obj.calibration_drawing_list(end)} = ...
                                [obj.validation_right_eye_distance_store{obj.calibration_drawing_list(end)}; abs(right_sample(6))/10];
                        end
                    end
                end
            end
        end

        function repeat_calibration_point(obj)
            % Determine which points need recalibration
            for idx = 1:size(obj.validation_points, 1)
                left_samples = obj.validation_left_sample_store{idx};
                right_samples = obj.validation_right_sample_store{idx};

                if length(left_samples) <= 5 || length(right_samples) <= 5
                    % Not enough samples - clear and recalibrate
                    obj.validation_left_sample_store{idx} = [];
                    obj.validation_left_eye_distance_store{idx} = [];
                    obj.validation_right_sample_store{idx} = [];
                    obj.validation_right_eye_distance_store{idx} = [];
                    obj.calibration_drawing_list = [obj.calibration_drawing_list, idx];
                else
                    % Check error threshold
                    left_res = obj.calculator.calculate_error_by_sliding_window(...
                        obj.validation_points(idx, :), left_samples, ...
                        obj.validation_left_eye_distance_store{idx});
                    right_res = obj.calculator.calculate_error_by_sliding_window(...
                        obj.validation_points(idx, :), right_samples, ...
                        obj.validation_right_eye_distance_store{idx});

                    if left_res.min_error > obj.error_threshold || ...
                            right_res.min_error > obj.error_threshold
                        % Error too high - recalibrate
                        obj.validation_left_sample_store{idx} = [];
                        obj.validation_left_eye_distance_store{idx} = [];
                        obj.validation_right_sample_store{idx} = [];
                        obj.validation_right_eye_distance_store{idx} = [];
                        obj.calibration_drawing_list = [obj.calibration_drawing_list, idx];
                    end
                end
            end

            if isempty(obj.calibration_drawing_list)
                obj.n_validation = 2;
            end
        end

        function draw_previewer(obj)
            % Draw eye preview images
            [status, left_img, right_img, rects, pupils, glints] = facePreviewerGetImages(obj.tracker);
            % [left_img, right_img] = getPreviewImages(obj.tracker)
            % Resize and rotate images
            left_img = imresize(left_img, obj.previewer_size);
            right_img = imresize(right_img, obj.previewer_size);

            % Create textures
            left_tex = Screen('MakeTexture', obj.window, left_img);
            right_tex = Screen('MakeTexture', obj.window, right_img);

            % Draw textures
            left_rect = [
                double(obj.previewer_positions.left(1)), ...
                double(obj.previewer_positions.left(2)), ...
                double(obj.previewer_positions.left(1)+obj.previewer_size(1)), ...
                double(obj.previewer_positions.left(2)+obj.previewer_size(2))];
            right_rect = [
                double(obj.previewer_positions.right(1)), ...
                double(obj.previewer_positions.right(2)), ...
                double(obj.previewer_positions.right(1)+obj.previewer_size(1)), ...
                double(obj.previewer_positions.right(2)+obj.previewer_size(2))];

            % Screen('DrawTexture', obj.window, left_tex, [], [79 284 591 796]);
            % Screen('DrawTexture', obj.window, right_tex, [], [1329 284 1841 796]);

            Screen('DrawTexture', obj.window, left_tex, [], left_rect);
            Screen('DrawTexture', obj.window, right_tex, [], right_rect);

            % Release textures
            Screen('Close', [left_tex, right_tex]);
        end

        function playBeepSound(obj)
            try
                % Now initialize
                PsychPortAudio('Verbosity', 0);
                InitializePsychSound(0);

                % Rest of your sound playback code...
                wavFile = fullfile(fileparts(mfilename('fullpath')), 'asset', 'beep.wav');
                [y, freq] = audioread(wavFile);
                pahandle = PsychPortAudio('Open', [], [], 0, freq, size(y, 2));
                PsychPortAudio('FillBuffer', pahandle, y');
                PsychPortAudio('Start', pahandle);
                WaitSecs(size(y,1)/freq);
                PsychPortAudio('Close', pahandle);

            catch ME
                rethrow(ME);
            end
        end

        function clearCalibrationSceen(obj)
            Screen('FillRect', obj.window, [255 255 255]);
            Screen('Flip', obj.window);
        end
    end
end