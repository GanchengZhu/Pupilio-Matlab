#pragma once

#ifdef __cplusplus
#include <cstdint>
#else
#include <stdint.h>
#include <stdbool.h>
#endif

#define PUPILIO_DLL_EXPORTS
#ifdef PUPILIO_DLL_EXPORTS
#define PUPILIO_DLL_API __declspec(dllexport)
#else
#define PUPILIO_DLL_API __declspec(dllimport)
#endif


enum PupilioReturn {
    PUPILIO_ET_SUCCESS = 0,
    PUPILIO_ET_CALI_CONTINUE = 1,
    PUPILIO_ET_CALI_NEXT_POINT = 2,
    PUPILIO_ET_INVALID_PATH = 3,
    PUPILIO_ET_INVALID_PARAM = 4,
    PUPILIO_ET_ALREADY_SET = 8,
    PUPILIO_ET_FAILED = 9,
    PUPILIO_ET_EXCEPTION = 10,
};

extern "C" {
PUPILIO_DLL_API const char *pupil_io_get_version();
//int PUPILIO_DLL_API pupil_io_set_simulation_mode(bool enable);
int PUPILIO_DLL_API pupil_io_set_eye_mode(int mode);
int PUPILIO_DLL_API pupil_io_set_log(int valid, char *log_Path);
int PUPILIO_DLL_API pupil_io_init();
int PUPILIO_DLL_API pupil_io_recalibrate();
int PUPILIO_DLL_API pupil_io_set_cali_mode(int mode, float *cali_points);

int PUPILIO_DLL_API pupil_io_set_kappa_filter(int kappa_filter);
//int PUPILIO_DLL_API pupil_io_set_camera_param(float* camera_param);

int PUPILIO_DLL_API pupil_io_face_pos(float *eyepos);
int PUPILIO_DLL_API pupil_io_cali(const int cali_point_id);
int PUPILIO_DLL_API pupil_io_est(float *pt, long long *timeStamp);
int PUPILIO_DLL_API pupil_io_est_lr(float *pt_l, float *pt_r, long long *timeStamp);
int PUPILIO_DLL_API pupil_io_estimate_gaze(float *pt_l, float *pt_r, float *bino, long long *timeStamp);
int PUPILIO_DLL_API pupil_io_release();
//int PUPILIO_DLL_API pupil_io_face_image(char **image_data, int *width, int *height);,
int PUPILIO_DLL_API pupil_io_get_previewer(unsigned char **img_1, unsigned char **img2,
                                                     float *eye_rects, float *pupil_centers, float *glint_centers);

int PUPILIO_DLL_API pupil_io_previewer_init(const char *udp_address, int port, bool draw_preview_annotation);
int PUPILIO_DLL_API pupil_io_previewer_start();
int PUPILIO_DLL_API pupil_io_previewer_stop();

int PUPILIO_DLL_API pupil_io_create_session(const char *session_name);

int PUPILIO_DLL_API pupil_io_set_filter_enable(bool status);
int PUPILIO_DLL_API pupil_io_start_sampling();
int PUPILIO_DLL_API pupil_io_stop_sampling();
int PUPILIO_DLL_API pupil_io_sampling_status(bool *status);
int PUPILIO_DLL_API pupil_io_send_trigger(uint64_t trigger_code);
int PUPILIO_DLL_API pupil_io_save_data_to(char *path);
int PUPILIO_DLL_API pupil_io_clear_cache();

int PUPILIO_DLL_API pupil_io_get_current_gaze(float *left, float *right, float *bino);

int PUPILIO_DLL_API pupil_io_set_look_ahead(int look_ahead);
int PUPILIO_DLL_API pupil_io_get_camera_mode(
        int* mode,
        int* left_roi,
        int* right_roi);

PUPILIO_DLL_API const char *get_version();


int PUPILIO_DLL_API pupil_io_event_detection(const char *data_path,
                                                       char *output_dir,
                                                       const char *which_eye,
                                                       int minimum_duration,
                                                       float dispersion_threshold);


int PUPILIO_DLL_API pupil_io_est_full(
        float* pt,
        long long* timestamp);

int PUPILIO_DLL_API pupil_io_set_camera_mode(int* mode);

//int PUPILIO_DLL_API pupil_io_set_camera_param(float* camera_param);


}

