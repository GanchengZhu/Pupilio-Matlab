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
        % Constants - screen-space layout (matches Python SDK)
        SCREEN_CENTER_X = 960.0;
        SCREEN_CENTER_Y = 540.0;
        SCALE_X = 7.0;
        SCALE_Y = 10.0;
        BEST_RANGE_R = 80.0;
        BOUNDARY_R = 320.0;
        K_Z_RADIUS = 1.0;
        MIN_FACE_R = 10.0;
        Z_OPTIMAL_BASE = -500.0;
        Z_SAFE_MIN = -600.0;
        Z_SAFE_MAX = -400.0;
        LINE_THICK_BOUND = 6;
        LINE_THICK_BEST = 3;

        % Colors
        BLACK = [0, 0, 0];
        RED = [255, 0, 0];
        GREEN = [0, 255, 0];
        BLUE = [0, 0, 255];
        WHITE = [255, 255, 255];
        CRIMSON = [220, 20, 60];
        CORAL = [240, 128, 128];
        GRAY = [128, 128, 128];
        YELLOW = [255, 255, 0];

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

        % True when config.cali_mode == NO_CALI (0). Under no-cali mode the
        % routine still runs the head-position phase so the participant can
        % verify the tracker sees their face, then exits without targets or
        % validation.
        no_cali_mode = false;

        % When true, the position-adjustment phase is skipped on entry.
        % Set by the ESC fallback path so re-entry doesn't re-show the
        % position screen after the participant already went through it.
        skip_pos_adjust = false;

        % Set when ESC is pressed during the routine so the post-loop handler
        % can switch the tracker to no-calibration mode and re-enter.
        abort_with_fallback = false;
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

            % initialize face previewer
            if obj.config.face_previewing
                udp_address = '127.0.0.1';  % Localhost
                port = 5000;                % Example port number
                facePreviewerInit(obj.tracker, udp_address, port);
                facePreviewerStart(obj.tracker);
            end
        end

        function load_resources(obj)
            % Load clock number textures (placeholder)
            for n = 0:9
                % In a real implementation, you would load actual images here
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
            obj.just_pos_sound_once = false;
            obj.preparing_hands_free_start = 0;
            obj.no_cali_mode = false;
            obj.skip_pos_adjust = false;
            obj.abort_with_fallback = false;
        end

        function tf = isNoCaliMode(obj)
            tf = (double(obj.config.cali_mode) == 0);
        end

        function fallback_to_no_cali_and_restart(obj, bg_color, hands_free)
            if nargin < 2 || isempty(bg_color),   bg_color = obj.WHITE;   end
            if nargin < 3 || isempty(hands_free), hands_free = false;    end

            fprintf('[CalibrationGraphics] ESC pressed; switching to no-calibration mode.\n');

            try
                setCalibrationMode(obj.tracker, 0);
            catch ME
                warning('setCalibrationMode(0) failed: %s', ME.message);
                obj.stop_all_sounds();
                return;
            end

            obj.config.cali_mode         = 0;
            obj.tracker.config.cali_mode = 0;

            obj.abort_with_fallback = false;

            if hands_free
                obj.draw_hands_free(false, bg_color, true);
            else
                obj.draw(false, bg_color, true);
            end
        end

        function cleanup_after_calibration(obj)
            %CLEANUP_AFTER_CALIBRATION Stop the leftover native sampling thread.
            %   Mirrors the Python SDK's calibration_draw tail. Without this,
            %   pupil_io_estimate_gaze may keep returning ET_CALI_CONTINUE
            %   after startSampling() because the DLL is still in the
            %   calibration state.
            try
                if getSamplingStatus(obj.tracker)
                    % fprintf(['[CalibrationGraphics] Calibration left sampling active; ' ...
                    %          'stopping it so startSampling() can proceed.\n']);
                    try
                        stopSampling(obj.tracker);
                    catch ME
                        % The wrapper may throw if the native side reports no
                        % thread. That's benign here; suppress it.
                        if ~contains(ME.message, 'No sampling thread')
                            warning('[CalibrationGraphics] stopSampling failed: %s', ME.message);
                        end
                    end
                end
            catch ME
                warning('[CalibrationGraphics] getSamplingStatus failed: %s', ME.message);
            end
        end

        function stop_all_sounds(obj)
            try
                clear sound;  %#ok<CLSOUND>
            catch
            end
        end

        function draw_error_line(obj, ground_truth_point, estimated_point, error_color)
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

            Screen('TextSize', obj.window, obj.font_size);
        end

        function draw_recali_and_continue_tips(obj)
            legend_texts = {...
                obj.config.instruction_calibration_over, ...
                obj.config.instruction_recalibration};

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

            Screen('TextSize', obj.window, obj.font_size);
        end

        function draw_legend(obj)
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

            Screen('TextSize', obj.window, obj.font_size);
        end

        function draw_animation(obj, point, time_elapsed)
            index = mod(floor(time_elapsed * (obj.animation_frequency * 20)), 20) + 1;
            width = obj.animation_sizes{index}(1);
            height = obj.animation_sizes{index}(2);

            Screen('DrawTexture', obj.window, obj.animation_textures{index}, [], ...
                [point(1) - double(width/2), point(2) - double(height/2), ...
                point(1) + double(width/2), point(2) + double(height/2)]);
        end

        function draw(obj, validate, bg_color, skip_pos_adjust)
            if nargin < 2
                validate = false;
            end
            if nargin < 3
                bg_color = obj.WHITE;
            end
            if nargin < 4
                skip_pos_adjust = false;
            end

            obj.initialize_variables();
            obj.no_cali_mode = obj.isNoCaliMode();
            obj.skip_pos_adjust = skip_pos_adjust;

            obj.need_validation = validate && ~obj.no_cali_mode;

            if obj.skip_pos_adjust
                obj.phase_adjust_position = false;
                if obj.no_cali_mode
                    obj.phase_calibration = true;
                else
                    obj.calibration_preparing = true;
                end
            end

            trackerCalibrationInit(obj.tracker);

            targetIFI = 1/60;
            obj.waitframes = round(targetIFI/obj.ifi);
            if obj.waitframes < 1
                obj.waitframes = 1;
            end

            obj.vbl = Screen('Flip', obj.window);

            while ~obj.exit
                user_response_continue = false;
                user_response_recali = false;

                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown
                    user_response_continue = keyCode(KbName('Return')) || keyCode(KbName('space'));
                    user_response_recali = keyCode(KbName('r'));

                    if keyCode(KbName('ESCAPE'))
                        obj.exit = true;
                        obj.abort_with_fallback = true;
                    elseif keyCode(KbName('q'))
                        obj.exit = true;
                        obj.abort_with_fallback = false;
                    end

                    clearKeyboardEvents();
                end

                if user_response_continue
                    if obj.phase_adjust_position
                        obj.phase_adjust_position = false;
                        if obj.no_cali_mode
                            obj.phase_calibration = true;
                        else
                            obj.calibration_preparing = true;
                        end

                    elseif obj.calibration_preparing
                        obj.phase_adjust_position = false;
                        obj.calibration_preparing = false;
                        obj.phase_calibration = true;

                    elseif obj.validation_preparing
                        obj.phase_validation = true;
                        obj.validation_preparing = false;

                    elseif obj.phase_validation && obj.drawing_validation_result
                        obj.phase_validation = false;
                    end
                elseif user_response_recali && obj.drawing_validation_result
                    obj.phase_validation = false;
                    obj.drawing_validation_result = false;
                    obj.draw(obj.need_validation, bg_color);
                    return;
                end

                Screen('FillRect', obj.window, bg_color);

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

                    obj.graphics_finished = true;
                    obj.exit = true;
                end

                obj.vbl = Screen('Flip', obj.window, obj.vbl + (obj.waitframes - 0.5) * obj.ifi);
            end

            if obj.abort_with_fallback && ~obj.isNoCaliMode()
                obj.fallback_to_no_cali_and_restart(bg_color, false);
            end

            obj.cleanup_after_calibration();
        end

        function draw_hands_free(obj, validate, bg_color, skip_pos_adjust)
            if nargin < 2
                validate = false;
            end
            if nargin < 3
                bg_color = obj.WHITE;
            end
            if nargin < 4
                skip_pos_adjust = false;
            end

            obj.initialize_variables();
            obj.no_cali_mode = obj.isNoCaliMode();
            obj.skip_pos_adjust = skip_pos_adjust;
            obj.need_validation = validate && ~obj.no_cali_mode;
            obj.preparing_hands_free_start = 0;
            obj.hands_free = true;

            if obj.skip_pos_adjust
                obj.phase_adjust_position = false;
                if obj.no_cali_mode
                    obj.phase_calibration = true;
                else
                    obj.calibration_preparing = true;
                end
            end

            targetIFI = 1/60;
            obj.waitframes = round(targetIFI/obj.ifi);
            if obj.waitframes < 1
                obj.waitframes = 1;
            end
            obj.vbl = Screen('Flip', obj.window);

            while ~obj.exit
                [keyIsDown, ~, keyCode] = KbCheck;
                if keyIsDown
                    if keyCode(KbName('ESCAPE'))
                        obj.exit = true;
                        obj.abort_with_fallback = true;
                    elseif keyCode(KbName('q'))
                        obj.exit = true;
                        obj.abort_with_fallback = false;
                    end
                    clearKeyboardEvents();
                end

                Screen('FillRect', obj.window, bg_color);

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

                obj.vbl = Screen('Flip', obj.window, obj.vbl + (obj.waitframes - 0.5) * obj.ifi);
            end

            if obj.abort_with_fallback && ~obj.isNoCaliMode()
                obj.fallback_to_no_cali_and_restart(bg_color, true);
            end

            obj.cleanup_after_calibration();
        end

        function draw_calibration_point(obj)
            if obj.calibration_timer == 0
                obj.clearCalibrationSceen();
                obj.playBeepSound();
                obj.calibration_timer = GetSecs;
            end

            time_elapsed = GetSecs - obj.calibration_timer;
            status = getCalibrationStatus(obj.tracker, obj.calibration_point_index);

            if status == ET_ReturnCode.ET_CALI_CONTINUE
                obj.calibration_point_index = obj.calibration_point_index;

            elseif status == ET_ReturnCode.ET_CALI_NEXT_POINT
                if obj.calibration_point_index + 1 == length(obj.calibration_points)
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
                    obj.calibration_point_index = obj.calibration_point_index + 1;
                    obj.calibration_timer = 0;
                end

            elseif status == ET_ReturnCode.ET_SUCCESS
                obj.phase_calibration = false;
                obj.validation_preparing = false;
                if obj.need_validation && ~obj.hands_free
                    obj.validation_preparing = true;
                elseif obj.hands_free && obj.need_validation
                    obj.phase_calibration = false;
                    obj.validation_preparing = false;
                    obj.phase_validation = true;
                else
                    Screen('FillRect', obj.window, obj.WHITE);
                    obj.exit = true;
                    obj.graphics_finished = true;
                    return;
                end
            end

            if obj.calibration_point_index < length(obj.calibration_points)
                point = obj.calibration_points(obj.calibration_point_index+1,:);
                point = double(point);
                px = double(point(1));
                py = double(point(2));
                obj.draw_animation([px, py], time_elapsed);
            end
        end

        function draw_calibration_preparing(obj)
            text = obj.config.instruction_enter_calibration;
            obj.draw_text_center(text);
        end

        function draw_validation_preparing(obj)
            text = obj.config.instruction_enter_validation;
            obj.draw_text_center(text);
        end

        function draw_adjust_position(obj)
            %DRAW_ADJUST_POSITION  Mirror Python SDK's _draw_adjust_position.
            %
            %   Draws a circular boundary around the screen centre, a
            %   "best range" circle inside it, and a face image positioned
            %   from the tracker's reported face position. The face circle
            %   radius scales with distance (z), and both its fill colour and
            %   the boundary colour react to how far the participant is from
            %   the optimal z-range and how far they have drifted from
            %   screen centre.
            %
            %   In hands-free mode, holding a good position for the countdown
            %   advances the routine automatically; drifting out resets the
            %   countdown.

            if ~obj.just_pos_sound_once
                % Play the "adjust position" cue once. If you have a MATLAB
                % equivalent of self._sound_pos, play it here.
                obj.just_pos_sound_once = true;
            end

            [status, face_position] = getFacePosition(obj.tracker);

            % ----------------------------------------------------------
            % Sanity: no face at all
            % ----------------------------------------------------------
            has_face = ~isempty(face_position) && ...
                       all(~isnan(face_position(1:3)));

            if ~has_face
                % Red boundary box (participant not visible to the tracker)
                obj.draw_boundary_rect(obj.RED);

                % Yellow "best range" circle
                Screen('FrameOval', obj.window, double(obj.YELLOW), ...
                    double(obj.oval_rect(obj.SCREEN_CENTER_X, obj.SCREEN_CENTER_Y, obj.BEST_RANGE_R)), ...
                    double(obj.LINE_THICK_BEST));

                % Instruction: move head to the centre of the box
                obj.draw_text_centered_at( ...
                    obj.config.instruction_head_center, ...
                    obj.SCREEN_CENTER_X, ...
                    obj.SCREEN_CENTER_Y + obj.BEST_RANGE_R + 20);

                if obj.hands_free
                    obj.hands_free_adjust_head_start_timestamp = 0;
                end
                return;
            end

            % ----------------------------------------------------------
            % Face-to-screen projection
            % ----------------------------------------------------------
            if obj.config.active_eye == -1 || strcmp(obj.config.active_eye, 'left')
                face_x_offset = 32.0;
            elseif obj.config.active_eye == 1 || strcmp(obj.config.active_eye, 'right')
                face_x_offset = -32.0;
            else
                face_x_offset = 0.0;
            end

            face_px_x = obj.SCREEN_CENTER_X + (face_position(1) - 172.08 + face_x_offset) * obj.SCALE_X;

            % y offset depends on hardware: 200 Hz sensor uses a different
            % vertical reference. Matches Python: 110 for 200 Hz, 130 otherwise.
            if obj.config.sampling_rate == 200
                y_offset = 110.0;
            else
                y_offset = 130.0;
            end
            face_px_y = obj.SCREEN_CENTER_Y + (face_position(2) - y_offset) * obj.SCALE_Y;

            face_mm_z = face_position(3);

            % ----------------------------------------------------------
            % Colour: red outside safe z-range, green→red gradient inside
            % ----------------------------------------------------------
            instruction_text = '';

            if face_mm_z > obj.Z_SAFE_MAX || face_mm_z < obj.Z_SAFE_MIN
                face_rgb = obj.RED;
                if face_mm_z > obj.Z_SAFE_MAX
                    instruction_text = obj.config.instruction_face_far;
                else
                    instruction_text = obj.config.instruction_face_near;
                end
            else
                ratio = min(abs(face_mm_z - obj.Z_OPTIMAL_BASE) / 100.0, 1.0);
                face_rgb = [ ...
                    int32(obj.RED(1) * ratio + obj.GREEN(1) * (1 - ratio)), ...
                    int32(obj.RED(2) * ratio + obj.GREEN(2) * (1 - ratio)), ...
                    0 ];
            end

            % ----------------------------------------------------------
            % Face circle radius scales with distance from optimal z
            % ----------------------------------------------------------
            face_radius = max(obj.BEST_RANGE_R + ...
                              (face_mm_z - obj.Z_OPTIMAL_BASE) * obj.K_Z_RADIUS, ...
                              obj.MIN_FACE_R);

            % ----------------------------------------------------------
            % Inside boundary? (distance from centre + radius <= BOUNDARY_R)
            % ----------------------------------------------------------
            dx = face_px_x - obj.SCREEN_CENTER_X;
            dy = face_px_y - obj.SCREEN_CENTER_Y;
            is_inside_bound = (sqrt(dx^2 + dy^2) + face_radius) <= obj.BOUNDARY_R;

            if ~is_inside_bound && isempty(instruction_text)
                instruction_text = obj.config.instruction_head_center;
            end

            if is_inside_bound
                bound_color = obj.GREEN;
            else
                bound_color = obj.RED;
            end

            % ----------------------------------------------------------
            % Draw: boundary, face image, best-range circle, instruction
            % ----------------------------------------------------------
            obj.draw_boundary_rect(bound_color);

            if face_mm_z > obj.Z_SAFE_MAX || face_mm_z < obj.Z_SAFE_MIN || ~is_inside_bound
                face_img_path = fullfile(obj.currentFolder, 'asset', 'frowning-face.png');
            else
                face_img_path = fullfile(obj.currentFolder, 'asset', 'smiling-face.png');
            end

            r_size = round(face_radius * 3);
            obj.draw_face_image(face_img_path, ...
                face_px_x - r_size/2, face_px_y - r_size/2, r_size, r_size);

            Screen('FrameOval', obj.window, obj.YELLOW, ...
                obj.oval_rect(obj.SCREEN_CENTER_X, obj.SCREEN_CENTER_Y, obj.BEST_RANGE_R), ...
                obj.LINE_THICK_BEST);

            if ~isempty(instruction_text)
                text_y = face_px_y + face_radius + 20;
                obj.draw_text_centered_at(instruction_text, face_px_x, text_y);
            end

            % ----------------------------------------------------------
            % Hands-free auto-advance
            % ----------------------------------------------------------
            if obj.hands_free
                in_zone = (obj.Z_SAFE_MIN <= face_mm_z && face_mm_z <= obj.Z_SAFE_MAX && ...
                           is_inside_bound);

                if in_zone && obj.hands_free_adjust_head_wait_time <= 0
                    obj.phase_adjust_position = false;
                    if obj.no_cali_mode
                        obj.phase_calibration = true;
                    else
                        obj.calibration_preparing = true;
                    end
                elseif in_zone
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
            if obj.preparing_hands_free_start == 0
                obj.preparing_hands_free_start = GetSecs;
            end

            time_elapsed = GetSecs - obj.preparing_hands_free_start;
            if time_elapsed <= 9.0
                text = obj.config.instruction_hands_free_calibration;
                obj.draw_text_center(text);

                remaining = ceil(10 - time_elapsed);
                DrawFormattedText(obj.window, num2str(remaining), ...
                    'center', double(obj.config.screen_height_pix/2 - 150), obj.BLACK);
            else
                obj.calibration_preparing = false;
                obj.phase_calibration = true;
            end
        end

        function draw_validation_point(obj)
            if isempty(obj.calibration_drawing_list)
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

                    if obj.config.enable_validation_result_saving
                        calibrationDir = fullfile(pwd, 'calibration', obj.config.session_name);
                        if ~exist(calibrationDir, 'dir')
                            mkdir(calibrationDir);
                        end
                    end

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
                if obj.validation_timer == 0
                    obj.clearCalibrationSceen();
                    obj.playBeepSound();
                    obj.validation_timer = GetSecs;
                end

                time_elapsed = GetSecs - obj.validation_timer;
                if time_elapsed > 1.5
                    obj.calibration_drawing_list(end) = [];
                    obj.validation_timer = 0;
                    if isempty(obj.calibration_drawing_list)
                        obj.n_validation = obj.n_validation + 1;
                    end
                else
                    point = obj.validation_points(obj.calibration_drawing_list(end), :);
                    obj.draw_animation(point, time_elapsed);

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
            for idx = 1:size(obj.validation_points, 1)
                left_samples = obj.validation_left_sample_store{idx};
                right_samples = obj.validation_right_sample_store{idx};

                if length(left_samples) <= 5 || length(right_samples) <= 5
                    obj.validation_left_sample_store{idx} = [];
                    obj.validation_left_eye_distance_store{idx} = [];
                    obj.validation_right_sample_store{idx} = [];
                    obj.validation_right_eye_distance_store{idx} = [];
                    obj.calibration_drawing_list = [obj.calibration_drawing_list, idx];
                else
                    left_res = obj.calculator.calculate_error_by_sliding_window(...
                        obj.validation_points(idx, :), left_samples, ...
                        obj.validation_left_eye_distance_store{idx});
                    right_res = obj.calculator.calculate_error_by_sliding_window(...
                        obj.validation_points(idx, :), right_samples, ...
                        obj.validation_right_eye_distance_store{idx});

                    if left_res.min_error > obj.error_threshold || ...
                            right_res.min_error > obj.error_threshold
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
            [left_img, right_img] = getPreviewImages(obj.tracker);

            if isempty(left_img) || isempty(right_img)
                return;
            end

            left_img = imresize(left_img, obj.previewer_size);
            right_img = imresize(right_img, obj.previewer_size);

            left_tex = Screen('MakeTexture', obj.window, left_img);
            right_tex = Screen('MakeTexture', obj.window, right_img);

            left_rect = [
                double(obj.previewer_positions.left(1)), ...
                double(obj.previewer_positions.left(2)), ...
                double(obj.previewer_positions.left(1) + obj.previewer_size(1)), ...
                double(obj.previewer_positions.left(2) + obj.previewer_size(2))];
            right_rect = [
                double(obj.previewer_positions.right(1)), ...
                double(obj.previewer_positions.right(2)), ...
                double(obj.previewer_positions.right(1) + obj.previewer_size(1)), ...
                double(obj.previewer_positions.right(2) + obj.previewer_size(2))];

            Screen('DrawTexture', obj.window, left_tex, [], left_rect);
            Screen('DrawTexture', obj.window, right_tex, [], right_rect);

            Screen('Close', [left_tex, right_tex]);
        end

        function playBeepSound(obj)
            try
                wavFile = fullfile(fileparts(mfilename('fullpath')), 'asset', 'beep.wav');
                if exist(wavFile, 'file')
                    [y, fs] = audioread(wavFile);
                    sound(y, fs);
                else
                    fs = 8000;
                    t = 0:1/fs:0.2;
                    y = 0.5 * sin(2*pi*1000*t);
                    sound(y, fs);
                end
            catch ME
                warning('Sound playback failed: %s', ME.message);
            end
        end

        function r = oval_rect(~, cx, cy, radius)
            %OVAL_RECT  Bounding rect for a circle centred at (cx, cy).
            r = double([cx - radius, cy - radius, cx + radius, cy + radius]);
        end

        function draw_boundary_rect(obj, color)
            %DRAW_BOUNDARY_RECT  Square boundary around screen centre.
            rect = [ ...
                double(obj.SCREEN_CENTER_X - obj.BOUNDARY_R), ...
                double(obj.SCREEN_CENTER_Y - obj.BOUNDARY_R), ...
                double(obj.SCREEN_CENTER_X + obj.BOUNDARY_R), ...
                double(obj.SCREEN_CENTER_Y + obj.BOUNDARY_R)];
            Screen('FrameRect', obj.window, double(color), rect, double(obj.LINE_THICK_BOUND));
        end

        function draw_face_image(obj, img_path, x, y, w, h)
            %DRAW_FACE_IMAGE  Load and blit a face image at the given rect.
            if ~exist(img_path, 'file')
                return;
            end
            try
                [face_img, ~, alpha] = imread(img_path);
                if size(face_img, 3) == 3 && ~isempty(alpha)
                    face_img(:,:,4) = alpha;
                end
                tex = Screen('MakeTexture', obj.window, face_img);
                destRect = double([x, y, x + w, y + h]);
                Screen('DrawTexture', obj.window, tex, [], destRect);
                % Do NOT close the texture here. Closing it mid-frame is what was
                % causing the "Invalid Window (or Texture) Index" cascade on the
                % following FrameOval call. Let PTB manage the texture lifetime.
            catch ME
                warning('draw_face_image failed: %s', ME.message);
            end
        end

        function draw_text_centered_at(obj, text, cx, cy)
            %DRAW_TEXT_CENTERED_AT  Draw a single line of text centred at (cx, cy).
            Screen('TextSize', obj.window, obj.font_size);
            try
                text = char(text);
            catch
                text = unicode2native(text, 'UTF-8');
            end
            bounds = Screen('TextBounds', obj.window, text);
            text_w = double(bounds(3));
            text_h = double(bounds(4));
            DrawFormattedText(obj.window, text, ...
                double(cx - text_w/2), double(cy - text_h/2), obj.BLACK);
        end

        function clearCalibrationSceen(obj)
            Screen('FillRect', obj.window, [255 255 255]);
            Screen('Flip', obj.window);
        end
    end
end
