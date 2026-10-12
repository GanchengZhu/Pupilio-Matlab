// PupilioET.h - Simplified for MATLAB loadlibrary
// All functions are in extern "C" block

#ifndef PUPILIOET_H
#define PUPILIOET_H

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

// Return codes - defined as macros to avoid enum parsing issues
#define PUPILIO_ET_SUCCESS 0
#define PUPILIO_ET_CALI_CONTINUE 1
#define PUPILIO_ET_CALI_NEXT_POINT 2
#define PUPILIO_ET_INVALID_PATH 3
#define PUPILIO_ET_INVALID_PARAM 4
#define PUPILIO_ET_ALREADY_SET 8
#define PUPILIO_ET_FAILED 9
#define PUPILIO_ET_EXCEPTION 10

#ifdef __cplusplus
extern "C" {
#endif

// ---- Version ----
PUPILIO_DLL_API const char* pupil_io_get_version();

// ---- Configuration ----
PUPILIO_DLL_API int pupil_io_set_eye_mode(int mode);
PUPILIO_DLL_API int pupil_io_set_log(int valid, char* log_Path);
PUPILIO_DLL_API int pupil_io_set_cali_mode(int mode, float* cali_points);
PUPILIO_DLL_API int pupil_io_set_kappa_filter(int kappa_filter);
PUPILIO_DLL_API int pupil_io_set_look_ahead(int look_ahead);
PUPILIO_DLL_API int pupil_io_set_filter_enable(int status);

// ---- Init / Release ----
PUPILIO_DLL_API int pupil_io_init();
PUPILIO_DLL_API int pupil_io_release();
PUPILIO_DLL_API int pupil_io_recalibrate();

// ---- Camera Mode ----
PUPILIO_DLL_API int pupil_io_get_camera_mode(int* mode, int* left_roi, int* right_roi);
PUPILIO_DLL_API int pupil_io_set_camera_mode(int* mode);

// ---- Face Position ----
PUPILIO_DLL_API int pupil_io_face_pos(float* eyepos);

// ---- Calibration ----
PUPILIO_DLL_API int pupil_io_cali(int cali_point_id);

// ---- Gaze Estimation ----
PUPILIO_DLL_API int pupil_io_est(float* pt, long long* timeStamp);
PUPILIO_DLL_API int pupil_io_est_lr(float* pt_l, float* pt_r, long long* timeStamp);
PUPILIO_DLL_API int pupil_io_estimate_gaze(float* pt_l, float* pt_r, float* bino, long long* timeStamp);
PUPILIO_DLL_API int pupil_io_est_full(float* pt, long long* timestamp);
PUPILIO_DLL_API int pupil_io_get_current_gaze(float* left, float* right, float* bino);

// ---- Previewer ----
PUPILIO_DLL_API int pupil_io_get_previewer(unsigned char** img_1, unsigned char** img_2,
                                           float* eye_rects, float* pupil_centers, float* glint_centers);
PUPILIO_DLL_API int pupil_io_previewer_init(const char* udp_address, int port, int draw_preview_annotation);
PUPILIO_DLL_API int pupil_io_previewer_start();
PUPILIO_DLL_API int pupil_io_previewer_stop();

// ---- Sampling ----
PUPILIO_DLL_API int pupil_io_start_sampling();
PUPILIO_DLL_API int pupil_io_stop_sampling();
PUPILIO_DLL_API int pupil_io_sampling_status(int* status);

// ---- Session & Data ----
PUPILIO_DLL_API int pupil_io_create_session(const char* session_name);
PUPILIO_DLL_API int pupil_io_send_trigger(unsigned long long trigger_code);
PUPILIO_DLL_API int pupil_io_save_data_to(char* path);
PUPILIO_DLL_API int pupil_io_clear_cache();

// ---- Event Detection ----
PUPILIO_DLL_API int pupil_io_event_detection(const char* data_path,
                                             char* output_dir,
                                             const char* which_eye,
                                             int minimum_duration,
                                             float dispersion_threshold);

// ---- Camera Param ----
//PUPILIO_DLL_API int pupil_io_set_camera_param(float* camera_param);

#ifdef __cplusplus
}
#endif

#endif // PUPILIOET_H