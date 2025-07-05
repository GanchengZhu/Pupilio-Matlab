function [] = uniTestConfiguration(lang)
    % testing tracker configuration setting
    config = DefaultConfig();

    % Tracking parameters
    config.look_ahead = 3;
    config.enable_debug_logging = 0;
    config.log_directory = 'log_et';

    % calibration parameters
    config.face_previewing = false;
    config.cali_mode = 2; % 5-point calibration
    config.enable_kappa_verification = 0;
    config.enable_validation_result_saving = false;
    % char {mustBeMember(lang,{'zh', 'en', 'fr', 'es', 'ja', 'ko', 'zh-CN',
    % 'zh-TW','en-US','fr-FR','es-ES','jp-JP','ko-KR'})} = 'zh-CN'
    config.lang = lang;
    config.cali_target_img_maximum_size  = 60;
    config.cali_target_img_minimum_size  = 30;
    config.cali_target_animation_frequency = 2;

    % Screen properties
    config.screen_width_pix = 1024;
    config.screen_height_pix = 768;
    config.screen_width_cm = 34; % cm
    config.screen_height_cm  = 19; % cm

    % Resource paths (auto-set)
    % calibration_instruction_sound_path char
    % cali_target_beep char
    % cali_frowning_face_img char
    % cali_smiling_face_img char
    % cali_target_img char
    % log_directory char
    % session_name char

    [suc, tk] = initializeTracker(config);  % initialize
    pause(0.1);
    tk.config
    if suc
        releaseTracker(tk);  % release the tracker
    end
end