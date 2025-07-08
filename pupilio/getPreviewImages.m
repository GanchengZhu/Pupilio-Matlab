function  [left_preview, right_preview] = getPreviewImages(trackerHandler)
    % Dimensions of the preview images
    IMG_HEIGHT = 1024;
    IMG_WIDTH = 1280;
    
    % Initialize arrays for preview images and tracking data
    preview_left_img = zeros(IMG_HEIGHT, IMG_WIDTH, 'uint8');
    preview_right_img = zeros(IMG_HEIGHT, IMG_WIDTH, 'uint8');
    eye_rects = zeros(1, 16, 'single');  % 4 eyes * 4 coordinates each
    pupil_centers = zeros(1, 8, 'single');  % 4 eyes * 2 coordinates each
    glint_centers = zeros(1, 8, 'single');  % 4 eyes * 2 coordinates each
    
    % Call the native library to get eye tracking data
    % (This would need to be replaced with actual MATLAB-compatible native calls)
    [preview_left_img, preview_right_img, eye_rects, pupil_centers, glint_centers] = ...
    facePreviewerGetImages(trackerHandler);

    % Process the images
    [left_preview, right_preview] = processPreviewImages(trackerHandler, ...
        preview_left_img, preview_right_img, eye_rects, pupil_centers, glint_centers);
end