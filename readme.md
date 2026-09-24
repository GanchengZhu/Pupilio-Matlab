
<div align="left">

# Pupil.IO Matlab Integration 

</div>

**Pupilio-Matlab** is a lightweight Matlab package developed by Hangzhou Shenning Technology Co., Ltd., designed to drive and control the Pupil.IO Eye Tracker. It offers a user-friendly interface for ease of use, providing functionalities for eye-tracking data recording, calibration, and validation. Pupilio seamlessly integrates with platforms such as PsychToolBox.

## The Pupil.IO eye-tracker

<div align="left">
  <a href="https://raw.githubusercontent.com/GanchengZhu/Pupilio/refs/heads/master/docs/_static/images/intro/about/pupilio_c.PNG">
    <img width="390" height="351" src="https://raw.githubusercontent.com/GanchengZhu/Pupilio/refs/heads/master/docs/_static/images/intro/about/pupilio_c.PNG">
  </a>
</div>

[Pupil.IO](https://www.deep-gaze.com/) is a high-speed, high-precision eye-tracking system featuring an all-in-one (AIO) plug-and-play design that is ideal for both scientific research and clinical applications. With minimal setup (just power on and start tracking), it delivers lab-grade accuracy in a compact, user-friendly form factor.

- **Precision Tracking**: Capture high-frequency eye movement and pupil dynamics with lab-grade accuracy.
- **Seamless Compatibility**: Native integration with PsychoPy, PyGame, and other Python experimental platforms.
- **Multi-Modal Synchronization**: Native support for LabStreamingLayer (LSL) to synchronize gaze, pupil dynamics, and event markers with EEG, fNIRS, and EMG via LabRecorder.
- **Intuitive Workflow**: Simplified calibration, validation, and recording with minimal setup.

### Specifications
| Specifications | AIO (Commercial) | PRO (Research) | DVS-2K\*\* (Premiere Research) |
| :--- | :--- | :--- | :--- |
| Sampling Rate | 200 Hz | 400 Hz | 2000 Hz |
| Tracking Accuracy | 0.5-1.0 deg | 0.3-0.8 deg | 0.3-0.8 deg |
| Spatial Resolution | 0.05 deg | 0.08 deg | 0.02 deg |
| System Latency | 25 ms | 12 ms | 5 ms |
| Tracking Algorithm | Neural Network | Neural Network | Neural Network |
| Development Support | C++/Python/Matlab | C++/Python/Matlab | C++/Python/Matlab |
| Operating System | Windows 11 | Windows 11 | Windows 11 |
| Head Box | 40x40cm @ 70cm | 40x40cm @ 70cm | 40x40cm @ 70cm |
| Psychology Experiment Software | PsychoPy/PsychToolBox | PsychoPy/PsychToolBox | PsychoPy/PsychToolBox |
| Research Support | Yes | Yes | Yes |

\*\* DVS-2K edition available in Q4 2026. Final specifications subject to product manual.

## Installation

Copy the "pupilio" folder to your computer and addpath to this folder.

# Quick Start

Here is a minimal example to get started with Pupilio in MATLAB. It initializes the tracker, runs calibration, records for a few seconds, and saves the data to a CSV file.

## Minimal Working Example

```matlab
% Initialize tracker with default configuration
config = DefaultConfig();
config.lang = "en-US";
config.cali_mode = 2;
config.face_previewing = 1;
config.look_ahead = 2;
config.sampling_rate = 400;

[success, tracker] = initializeTracker(config);
if ~success
    error('Tracker initialization failed');
end

% Create a session
createSession(tracker, 'quick_start');

% Open a Psychtoolbox window
PsychDefaultSetup(2);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'Verbosity', 0);
screenNum = max(Screen('Screens'));
[window, windowRect] = Screen('OpenWindow', screenNum, [128 128 128]);

% Calibrate (with validation)
cali = CalibrationGraphics(tracker, window);
cali.draw(true);

% Start recording
startSampling(tracker);
WaitSecs(0.1);   % 100 ms warm-up

% Display a message and record for 5 seconds
DrawFormattedText(window, 'Recording... will stop in 5 seconds', ...
    'center', 'center', [0 0 0]);
Screen('Flip', window);
WaitSecs(5);

% Stop recording
stopSampling(tracker);
WaitSecs(0.2);

% Save the recorded data
dataDir = fullfile(pwd, 'data');
if ~exist(dataDir, 'dir')
    mkdir(dataDir);
end
saveDataTo(tracker, fullfile(dataDir, 'quick_start.csv'));

% Release the tracker and close the window
releaseTracker(tracker);
sca;
```

## Step-by-Step Explanation

| Step | Purpose |
| --- | --- |
| `DefaultConfig()` | Creates a configuration object with sensible defaults. Override any field (`lang`, `cali_mode`, `look_ahead`, `sampling_rate`, ...) before passing it to `initializeTracker`. |
| `initializeTracker(config)` | Loads `PupilioET.dll`, applies the configuration, and brings the tracker to a ready state. Returns `success` and a `tracker` handle. |
| `createSession(tracker, name)` | Opens a named session. Data is buffered in a temporary folder and written out by `saveDataTo`. |
| `CalibrationGraphics(...); cali.draw(true)` | Runs the full calibration UI, with validation enabled (`true`). Pass `false` to skip validation. |
| `startSampling` / `stopSampling` | Begin and end recording. Call `WaitSecs(0.1)` after `startSampling` to let the buffer fill before the first sample is used. |
| `saveDataTo(tracker, path)` | Writes the buffered samples to a CSV file. The parent directory must exist. |
| `releaseTracker(tracker); sca;` | Frees tracker resources and closes the Psychtoolbox window. Always run both, even on error. |

## Common Configuration Options

```matlab
config.cali_mode       = 2;       % 0 = skip, 2 = two-point, 4 = four-point, 5 = five-point
config.look_ahead      = 2;       % heuristic filter window (0-4)
config.active_eye      = 0;       % 0 = binocular, -1 = left only, 1 = right only
config.sampling_rate   = 400;     % 200 or 400 Hz; auto-falls back to 200 if unsupported
config.face_previewing = 1;       % show live face preview during calibration
config.lang            = "en-US"; % UI language (en-US, zh-CN, zh-HK, fr-FR, es-ES, jp-JP, ko-KR)
```

## Notes

- **Cleanup on error.** Wrap the body in `try` / `catch` and put `releaseTracker` + `sca` in the `catch` block, as shown in the longer demos (`picture_viewing_task.m`, `video_viewing_task.m`). This prevents the tracker from being left open if an exception occurs mid-run.

- **File encoding.** Set `config.lang` explicitly. Psychtoolbox's default text encoding can garble non-ASCII strings on some Windows installations.

- **Track a different stimulus.** Replace the 5-second wait with your own drawing loop — read gaze with `estimateGaze(tracker)` or `getCurrentGaze(tracker)` on each frame. See `picture_viewing_task.m` for a complete example with gaze cursors.

- **Event markers.** Call `setTrigger(tracker, code)` to stamp a marker into the recorded stream at any point (e.g. stimulus onset).

## Configuration Reference

| Parameter | Type | Default | Description |
| --- | --- | --- | --- |
| `cali_mode` | `int32` | `2` | Calibration target count. `0` skips calibration, `2` two-point, `4` four-point, `5` five-point. |
| `look_ahead` | `int32` | `2` | Heuristic filter window size (0-4). |
| `sampling_rate` | `int32` | `0` | `0` = auto-select. `200` or `400` Hz. Auto-falls back to 200 if unsupported. |
| `active_eye` | `int32` | `0` | `0` = binocular, `-1` = left only, `1` = right only. |
| `enable_kappa_verification` | `logical` | `true` | Enable kappa-angle verification after calibration. |
| `face_previewing` | `logical` | `true` | Show live camera preview during calibration. |
| `lang` | `char` | `'zh-CN'` | UI language. See list below. |
| `enable_debug_logging` | `logical` | `false` | Write debug logs to `log_directory`. |
| `enable_validation_result_saving` | `logical` | `true` | Save validation results to disk after calibration. |

### Supported Languages

| Code | Language |
| --- | --- |
| `en-US` | English |
| `zh-CN` | Simplified Chinese |
| `zh-HK` | Traditional Chinese (Hong Kong) |
| `zh-TW` | Traditional Chinese (Taiwan) |
| `fr-FR` | French |
| `es-ES` | Spanish |
| `jp-JP` | Japanese |
| `ko-KR` | Korean |

## Typical Workflow

```text
┌──────────────────┐
│  DefaultConfig   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ initializeTracker│
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ createSession    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ CalibrationGraphics ────► cali.draw(validate)
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  startSampling   │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  Experiment Loop │  ◄─── estimateGaze / setTrigger
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  stopSampling    │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│  saveDataTo      │
└────────┬─────────┘
         │
         ▼
┌──────────────────┐
│ releaseTracker   │
│      sca         │
└──────────────────┘
```

## Troubleshooting

> **Tracker initialization failed**
>
> - Verify `PupilioET.dll` exists at `lib/PupilioET.dll` relative to `initializeTracker.m`.
> - Confirm the tracker is connected and powered on.
> - Check that no other application is holding the device open.

> **Calibration window does not appear**
>
> - Ensure Psychtoolbox is installed: `PsychtoolboxVersion`.
> - Try `Screen('Preference', 'SkipSyncTests', 1)` as shown in the example.

> **Sampling returns zeros**
>
> - Call `startSampling` and wait at least one frame (`WaitSecs(0.1)`) before reading.
> - Verify `gazeSuccess` from `estimateGaze` is nonzero before using the returned values.

## See Also

- [`picture_viewing_task.m`](./picture_viewing_task.m) — full example with gaze cursors and image stimuli.
- [`video_viewing_task.m`](./video_viewing_task.m) — video playback with real-time gaze tracking.
- [`fixation_stability.m`](./fixation_stability.m) — minimal gaze-cursor demo.
- [`DefaultConfig.m`](./DefaultConfig.m) — complete configuration reference.
- [`CalibrationMode.m`](./CalibrationMode.m) — calibration mode enumeration.

---


## Support

If you encounter any issues or have questions, please open an issue on GitHub or contact [zhugc2016@gmail.com](mailto:zhugc2016@gmail.com).

## License

Pupilio is a proprietary software developed by Hangzhou Shenning Technology Co., Ltd. All rights reserved. Unauthorized use, distribution, or modification is prohibited without explicit permission. For licensing inquiries, please contact [zhugc2016@gmail.com](mailto:zhugc2016@gmail.com).

## Acknowledgments
Pupilio is developed and maintained by Hangzhou Shenning Technology Co., Ltd. Special thanks to the community for their valuable feedback and support.

*Last updated: 2026-06-21*

