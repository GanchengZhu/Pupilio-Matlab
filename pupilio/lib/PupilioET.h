#pragma once

// Use C-compatible headers
#include <stdint.h>    // Instead of <cstdint>
#include <stdbool.h>   // For bool type in C

// DLL export/import macros
#ifdef PUPILIO_DLL_EXPORTS
    #define PUPILIO_DLL_API __declspec(dllexport)
#else
    #define PUPILIO_DLL_API __declspec(dllimport)
#endif

// Function declarations
#ifdef __cplusplus
extern "C" {
#endif

PUPILIO_DLL_API const char* mlif_pupil_io_get_version();
PUPILIO_DLL_API int mlif_pupil_io_set_eye_mode(int mode);
PUPILIO_DLL_API int mlif_pupil_io_set_log(int valid, char* log_Path);
PUPILIO_DLL_API int mlif_pupil_io_init();
PUPILIO_DLL_API int mlif_pupil_io_recalibrate();
PUPILIO_DLL_API int mlif_pupil_io_set_cali_mode(int mode, float* cali_points);
PUPILIO_DLL_API int mlif_pupil_io_set_kappa_filter(int kappa_filter);
PUPILIO_DLL_API int mlif_pupil_io_face_pos(float* eyepos);
PUPILIO_DLL_API int mlif_pupil_io_cali(const int cali_point_id);
PUPILIO_DLL_API int mlif_pupil_io_est(float* pt, long long* timeStamp);
PUPILIO_DLL_API int mlif_pupil_io_est_lr(float* pt_l, float* pt_r, long long* timeStamp);
PUPILIO_DLL_API int mlif_pupil_io_release();
PUPILIO_DLL_API int mlif_pupil_io_get_previewer(unsigned char** img_1, unsigned char** img2,
                                               float* eye_rects, float* pupil_centers, float* glint_centers);
PUPILIO_DLL_API int mlif_pupil_io_previewer_init(char* udp_address, int port);
PUPILIO_DLL_API int mlif_pupil_io_previewer_start();
PUPILIO_DLL_API int mlif_pupil_io_previewer_stop();
PUPILIO_DLL_API int mlif_pupil_io_create_session(const char* session_name);
PUPILIO_DLL_API int mlif_pupil_io_set_filter_enable(bool status);
PUPILIO_DLL_API int mlif_pupil_io_start_sampling();
PUPILIO_DLL_API int mlif_pupil_io_stop_sampling();
PUPILIO_DLL_API int mlif_pupil_io_sampling_status(bool* status);  // Changed from bool& to bool*
PUPILIO_DLL_API int mlif_pupil_io_send_trigger(uint64_t trigger_code);
PUPILIO_DLL_API int mlif_pupil_io_save_data_to(char* path);
PUPILIO_DLL_API int mlif_pupil_io_clear_cache();
PUPILIO_DLL_API int mlif_pupil_io_get_current_gaze(float* left, float* right, float* bino);
PUPILIO_DLL_API int mlif_pupil_io_set_look_ahead(int look_ahead);
PUPILIO_DLL_API const char* mlif_get_version();

#ifdef __cplusplus
}
#endif

