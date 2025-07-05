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


classdef DefaultConfig
    %DEFAULTCONFIG Configuration class for eye tracking system
    %   Comprehensive configuration with multi-language support and validation

    properties
        % Tracking parameters
        look_ahead int32 {mustBePositive} = 2  % Prediction steps (1-5)

        % Screen properties
        screen_width_pix int32 {mustBePositive} = 1920
        screen_height_pix int32 {mustBePositive} = 1080
        screen_width_cm double {mustBePositive} = 34.13  % cm
        screen_height_cm double {mustBePositive} = 19.32 % cm

        % Calibration settings
        cali_mode int32 {mustBeMember(cali_mode,[2,5])} = 2  % 2 or 5 point
        enable_kappa_verification logical = true
        cali_target_img_maximum_size int32 {mustBeInRange(cali_target_img_maximum_size,20,100)} = 60
        cali_target_img_minimum_size int32 {mustBeInRange(cali_target_img_minimum_size,10,50)} = 30
        cali_target_animation_frequency int32 {mustBePositive} = 2  % Hz

        % System settings
        enable_debug_logging logical = false
        face_previewing logical = true
        enable_validation_result_saving logical = true
        lang char {mustBeMember(lang,{'zh', 'en', 'fr', 'es', 'jp', 'ko',...
            'zh-CN','zh-HK', 'zh-TW', 'zh-SG', 'zh-MO','en-US','fr-FR','es-ES','jp-JP','ko-KR'})} = 'zh-CN'

        current_dir = fileparts(mfilename('fullpath'));

        % Resource paths (auto-set)
        calibration_instruction_sound_path char
        cali_target_beep char
        cali_frowning_face_img char
        cali_smiling_face_img char
        cali_target_img char
        log_directory char
        session_name char

        % Localized strings
        instruction_face_far char
        instruction_face_near char
        instruction_head_center char
        instruction_enter_calibration char
        instruction_hands_free_calibration char
        instruction_enter_validation char
        legend_target char
        legend_left_eye char
        legend_right_eye char
        instruction_calibration_over char
        instruction_recalibration char
    end

    methods
        function obj = DefaultConfig()
            % Constructor - sets default paths and localization
            obj = obj.initializePaths();
            obj = obj.setLocalization(obj.lang);
        end
    
        % Property set methods
        function obj = set.look_ahead(obj, value)
            validateattributes(value, {'int32'}, {'positive', 'scalar'});
            obj.look_ahead = value;
        end

        function obj = set.screen_width_pix(obj, value)
            validateattributes(value, {'int32'}, {'positive', 'scalar'});
            obj.screen_width_pix = value;
        end

        function obj = set.screen_height_pix(obj, value)
            validateattributes(value, {'int32'}, {'positive', 'scalar'});
            obj.screen_height_pix = value;
        end

        function obj = set.screen_width_cm(obj, value)
            validateattributes(value, {'double'}, {'positive', 'scalar'});
            obj.screen_width_cm = value;
        end

        function obj = set.screen_height_cm(obj, value)
            validateattributes(value, {'double'}, {'positive', 'scalar'});
            obj.screen_height_cm = value;
        end

        function obj = set.cali_mode(obj, value)
            validateattributes(value, {'int32'}, {'scalar'});
            mustBeMember(value, [2, 5]);
            obj.cali_mode = value;
        end

        function obj = set.enable_kappa_verification(obj, value)
            validateattributes(value, {'logical'}, {'scalar'});
            obj.enable_kappa_verification = value;
        end

        function obj = set.cali_target_img_maximum_size(obj, value)
            validateattributes(value, {'int32'}, {'scalar'});
            mustBeInRange(value, 20, 100);
            obj.cali_target_img_maximum_size = value;
        end

        function obj = set.cali_target_img_minimum_size(obj, value)
            validateattributes(value, {'int32'}, {'scalar'});
            mustBeInRange(value, 10, 50);
            obj.cali_target_img_minimum_size = value;
        end

        function obj = set.cali_target_animation_frequency(obj, value)
            validateattributes(value, {'int32'}, {'positive', 'scalar'});
            obj.cali_target_animation_frequency = value;
        end

        function obj = set.enable_debug_logging(obj, value)
            validateattributes(value, {'logical'}, {'scalar'});
            obj.enable_debug_logging = value;
        end

        function obj = set.face_previewing(obj, value)
            validateattributes(value, {'logical'}, {'scalar'});
            obj.face_previewing = value;
        end

        function obj = set.enable_validation_result_saving(obj, value)
            validateattributes(value, {'logical'}, {'scalar'});
            obj.enable_validation_result_saving = value;
        end

        function obj = set.lang(obj, value)
            validLangs = {'zh', 'en', 'fr', 'es', 'jp', 'ko', 'zh-CN',...
                         'zh-HK', 'zh-TW', 'zh-MO','zh-SG',...
                         'en-US','fr-FR','es-ES','jp-JP','ko-KR'};
            mustBeMember(value, validLangs);
            obj.lang = value;
            obj = obj.setLocalization(value); % Update localization when language changes
        end

        function obj = set.current_dir(obj, value)
            validateattributes(value, {'char'}, {});
            obj.current_dir = value;
        end

        function obj = set.session_name(obj, value)
            validateattributes(value, {'char'}, {});
            obj.session_name = value;
        end

        function obj = set.calibration_instruction_sound_path(obj, value)
            validateattributes(value, {'char'}, {});
            obj.calibration_instruction_sound_path = value;
        end

        function obj = set.cali_target_beep(obj, value)
            validateattributes(value, {'char'}, {});
            obj.cali_target_beep = value;
        end

        function obj = set.cali_frowning_face_img(obj, value)
            validateattributes(value, {'char'}, {});
            obj.cali_frowning_face_img = value;
        end

        function obj = set.cali_smiling_face_img(obj, value)
            validateattributes(value, {'char'}, {});
            obj.cali_smiling_face_img = value;
        end

        function obj = set.cali_target_img(obj, value)
            validateattributes(value, {'char'}, {});
            obj.cali_target_img = value;
        end

        function obj = set.log_directory(obj, value)
            validateattributes(value, {'char'}, {});
            obj.log_directory = value;
        end

        % Localized strings setters
        function obj = set.instruction_face_far(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_face_far = value;
        end

        function obj = set.instruction_face_near(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_face_near = value;
        end

        function obj = set.instruction_head_center(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_head_center = value;
        end

        function obj = set.instruction_enter_calibration(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_enter_calibration = value;
        end

        function obj = set.instruction_hands_free_calibration(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_hands_free_calibration = value;
        end

        function obj = set.instruction_enter_validation(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_enter_validation = value;
        end

        function obj = set.legend_target(obj, value)
            validateattributes(value, {'char'}, {});
            obj.legend_target = value;
        end

        function obj = set.legend_left_eye(obj, value)
            validateattributes(value, {'char'}, {});
            obj.legend_left_eye = value;
        end

        function obj = set.legend_right_eye(obj, value)
            validateattributes(value, {'char'}, {});
            obj.legend_right_eye = value;
        end

        function obj = set.instruction_calibration_over(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_calibration_over = value;
        end

        function obj = set.instruction_recalibration(obj, value)
            validateattributes(value, {'char'}, {});
            obj.instruction_recalibration = value;
        end
    

        function obj = initializePaths(obj)
            % Initialize all file paths
            obj.current_dir = fileparts(mfilename('fullpath'));
            assetDir = fullfile(obj.current_dir, 'assets');
    
            % Resource files
            obj.calibration_instruction_sound_path = fullfile(assetDir, 'calibration_instruction.wav');
            obj.cali_target_beep = fullfile(assetDir, 'beep.wav');
            obj.cali_frowning_face_img = fullfile(assetDir, 'frowning-face.png');
            obj.cali_smiling_face_img = fullfile(assetDir, 'smiling-face.png');
            obj.cali_target_img = fullfile(assetDir, 'windmill.png');
    
            % Log directory (create if doesn't exist)
            obj.log_directory = fullfile(getenv('HOME'), 'Pupilio', 'logs');
            if ~exist(obj.log_directory, 'dir')
                mkdir(obj.log_directory);
            end
        end

        function obj = setLocalization(obj, lang)
            %SETLOCALIZATION Update all language strings for the GUI/object.   
            % {'zh', 'en', 'fr', 'es', 'jp', 'ko', 
            % 'zh-CN','zh-TW','en-US','fr-FR','es-ES','jp-JP','ko-KR'}
            if any(strcmp(lang, {'zh-CN', 'zh-SG', 'zh'}))
                obj = simplified_chinese(obj);
            elseif any(strcmp(lang, {'zh-HK', 'zh-TW', 'zh-MO'}))
                obj = traditional_chinese(obj);
            elseif startsWith(lang, 'en')
                obj = english(obj);
            elseif startsWith(lang, 'fr')
                obj = french(obj);
            elseif strcmp(lang, 'es')
                obj = spanish(obj);
            elseif strcmp(lang, 'jp')
                obj = japanese(obj);
            elseif strcmp(lang, 'ko')
                obj = korean(obj);
            elseif strcmp(lang, 'es-ES')
                obj = spanish(obj);
            elseif strcmp(lang, 'jp-JP')
                obj = japanese(obj);
            elseif strcmp(lang, 'ko-KR')
                obj = korean(obj);
            else
                error('Unsupported language: %s', lang);
            end
        end
    
        function validatePaths(config)
            %VALIDATEPATHS Check all required files exist
            requiredFiles = {
                config.calibration_instruction_sound_path
                config.cali_target_beep
                config.cali_frowning_face_img
                config.cali_smiling_face_img
                config.cali_target_img
                };
    
            missingFiles = {};
            for i = 1:length(requiredFiles)
                if ~exist(requiredFiles{i}, 'file')
                    missingFiles{end+1} = requiredFiles{i}; %#ok<AGROW>
                end
            end
    
            if ~isempty(missingFiles)
                error('Missing required files:\n%s', strjoin(missingFiles, '\n'));
            end
        end
    
        function obj = simplified_chinese(obj)
            % Simplified Chinese instructions
            obj.instruction_face_far = '请后移一些';
            obj.instruction_face_near = '请靠近一些';
            obj.instruction_head_center = '请将头移动到方框中央';
    
            obj.instruction_enter_calibration = ['屏幕上会出现两个点，请依次注视这些点' newline ...
                '按回车键或鼠标左键(或触击屏幕)开始校准'];
    
            obj.instruction_hands_free_calibration = '倒计时结束后屏幕上会出现几个点，请依次注视这些点';
    
            obj.instruction_enter_validation = ['屏幕上会出现五个点，请依次注视这些点' newline ...
                '按回车键或鼠标左键(或触击屏幕)开始验证'];
    
            obj.legend_target = '目标点';
            obj.legend_left_eye = '左眼注视点';
            obj.legend_right_eye = '右眼注视点';
            obj.instruction_calibration_over = '按"回车键"或鼠标左键(触击屏幕)继续';
            obj.instruction_recalibration = '按"R"键或鼠标右键(长按屏幕)重新校准';
        end
    
        function obj = english(obj)
            % English instructions
            obj.instruction_face_far = 'Move farther back';
            obj.instruction_face_near = 'Move closer';
            obj.instruction_head_center = 'Move your head to the center of the box';
    
            obj.instruction_enter_calibration = ['Two points will appear on screen, please look at them in sequence' newline ...
                'Press Enter or left-click the mouse (or touch the screen) to start calibration'];
    
            obj.instruction_hands_free_calibration = 'Following the countdown, several points will appear on screen, please look at them in sequence';
    
            obj.instruction_enter_validation = ['Five points will appear on screen, please look at them in sequence' newline ...
                'Press Enter or left-click the mouse (or touch the screen) to start validation.'];
    
            obj.legend_target = 'Target';
            obj.legend_left_eye = 'Left Eye Gaze';
            obj.legend_right_eye = 'Right Eye Gaze';
            obj.instruction_calibration_over = 'Press "Enter" or left-click (click the screen) to continue.';
            obj.instruction_recalibration = 'Press "R" or right-click (long press the screen) to recalibrate.';
        end
    
        function obj = french(obj)
            % French instructions
            obj.instruction_face_far = 'Veuillez vous éloigner';
            obj.instruction_face_near = 'Veuillez vous rapprocher';
            obj.instruction_head_center = 'Veuillez centrer votre tête dans l''image';
    
            obj.instruction_enter_calibration = ['Deux points apparaîtront à l''écran, veuillez les regarder dans l''ordre' newline ...
                'Appuyez sur Entrée ou cliquez à gauche (cliquez sur l''écran) pour commencer l''étalonnage'];
    
            obj.instruction_hands_free_calibration = 'Après le compte à rebours, plusieurs points apparaîtront à l''écran, veuillez les regarder dans l''ordre.';
    
            obj.instruction_enter_validation = ['Cinq points apparaîtront à l''écran, veuillez les regarder.' newline ...
                'Appuyez sur Entrée ou cliquez sur l''écran (ou cliquez à gauche) pour commencer la validation.'];
    
            obj.legend_target = 'Point cible';
            obj.legend_left_eye = 'Point de focus œil gauche';
            obj.legend_right_eye = 'Point de focus œil droit';
            obj.instruction_calibration_over = 'Appuyez sur "Entrée" ou cliquez à gauche (cliquez sur l''écran) pour continuer.';
            obj.instruction_recalibration = 'Appuyez sur "R" ou cliquez à droite (maintenez l''écran) pour recalibrer.';
        end
    
        function obj = spanish(obj)
            % Spanish instructions
            obj.instruction_face_far = 'Por favor, retroceda';
            obj.instruction_face_near = 'Por favor, acérquese';
            obj.instruction_head_center = 'Por favor, centre su cabeza en la pantalla';
    
            obj.instruction_enter_calibration = ['Aparecerán dos puntos en la pantalla, por favor mírelos en orden' newline ...
                'Presione Enter o haga clic con el botón izquierdo (haga clic en la pantalla) para comenzar la calibración'];
    
            obj.instruction_hands_free_calibration = 'Después de la cuenta regresiva, aparecerán varios puntos en la pantalla, por favor mírelos en orden.';
    
            obj.instruction_enter_validation = ['Aparecerán cinco puntos en la pantalla, por favor mírelos.' newline ...
                'Presione Enter o haga clic en la pantalla (o haga clic con el botón izquierdo) para comenzar la validación.'];
    
            obj.legend_target = 'Punto objetivo';
            obj.legend_left_eye = 'Punto de enfoque ojo izquierdo';
            obj.legend_right_eye = 'Punto de enfoque ojo derecho';
            obj.instruction_calibration_over = ['Presione "Enter" o haga clic con el botón ' newline 'izquierdo (haga clic en la pantalla) para continuar.'];
            obj.instruction_recalibration = ['Presione "R" o haga clic con el botón derecho ' newline '(mantenga presionada la pantalla) para recalibrar.'];
        end
    
        function obj = traditional_chinese(obj)
            % Traditional Chinese instructions
            obj.instruction_face_far = '請後移一些';
            obj.instruction_face_near = '請靠近一些';
            obj.instruction_head_center = '請將頭移到畫面中央';
    
            obj.instruction_enter_calibration = ['畫面上會出現兩個點，請按順序注視這些點' newline ...
                '按下回車鍵或鼠標左鍵(點擊螢幕)開始校準'];
    
            obj.instruction_hands_free_calibration = '倒數計時後畫面會顯示幾個點，請按順序注視這些點。';
    
            obj.instruction_enter_validation = ['畫面上會出現五個點，請注視這些點。' newline ...
                '按下回車鍵或點擊螢幕（或者鼠標左鍵）開始驗證。'];
    
            obj.legend_target = '目標點';
            obj.legend_left_eye = '左眼注視點';
            obj.legend_right_eye = '右眼注視點';
            obj.instruction_calibration_over = '按下"回車鍵"或鼠標左鍵(點擊螢幕)繼續。';
            obj.instruction_recalibration = '按下"R"鍵或鼠標右鍵(長按螢幕)重新校準。';
        end
    
        function obj = japanese(obj)
            % Japanese instructions
            obj.instruction_face_far = 'もっと後ろに移動してください';
            obj.instruction_face_near = 'もっと近づいてください';
            obj.instruction_head_center = '画面の中央に頭を移動してください';
    
            obj.instruction_enter_calibration = ['画面に2つの点が表示されますので、その順番で注視してください' newline ...
                'Enterキーまたは左クリック（画面をクリック）でキャリブレーションを開始します'];
    
            obj.instruction_hands_free_calibration = 'カウントダウン後、画面にいくつかの点が表示されますので、その順番で注視してください。';
    
            obj.instruction_enter_validation = ['画面に5つの点が表示されますので、それらを注視してください。' newline ...
                'Enterキーまたは左クリック（画面をクリック）で検証を開始します。'];
    
            obj.legend_target = 'ターゲットポイント';
            obj.legend_left_eye = '左目の注視点';
            obj.legend_right_eye = '右目の注視点';
            obj.instruction_calibration_over = '「Enterキー」または左クリック（画面をクリック）で続行します。';
            obj.instruction_recalibration = '「R」キーまたは右クリック（画面を長押し）で再キャリブレーションします。';
        end
    
        function obj = korean(obj)
            % Korean instructions
            obj.instruction_face_far = '조금 더 뒤로 가주세요';
            obj.instruction_face_near = '조금 더 가까이 가세요';
            obj.instruction_head_center = '화면 중앙에 머리를 위치시켜 주세요';
    
            obj.instruction_enter_calibration = ['화면에 두 개의 점이 나타나면 순서대로 주시하세요' newline ...
                'Enter 키 또는 왼쪽 클릭(화면 클릭)으로 교정 시작'];
    
            obj.instruction_hands_free_calibration = '카운트다운 후 화면에 여러 점이 나타납니다. 순서대로 주시해주세요.';
    
            obj.instruction_enter_validation = ['화면에 다섯 개의 점이 나타납니다. 그 점들을 주시해주세요.' newline ...
                'Enter 키 또는 왼쪽 클릭(화면 클릭)으로 검증을 시작합니다.'];
    
            obj.legend_target = '목표 점';
            obj.legend_left_eye = '왼쪽 눈 주시점';
            obj.legend_right_eye = '오른쪽 눈 주시점';
            obj.instruction_calibration_over = '「Enter 키」 또는 왼쪽 클릭(화면 클릭)으로 계속 진행합니다.';
            obj.instruction_recalibration = '「R」 키 또는 오른쪽 클릭(화면 길게 누르기)으로 재교정합니다.';
        end
    end
end