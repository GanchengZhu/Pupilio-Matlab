function [left_preview, right_preview] = processPreviewImages(tracker, ...
    left_img, right_img, eye_rects, pupil_centers, glint_centers)
    % Constants
    IMG_HEIGHT = 1024;
    IMG_WIDTH = 1280;
    FRAME_WARNING = 255;  % White for warning
    FRAME_SUCCESS = 150;  % Gray for success
    FRAME_COLOR = FRAME_SUCCESS;
    FRAME_WIDTH = 8;
    
    % Keep images grayscale
    imgs = {left_img, right_img};
    
    % Create grayscale canvas for eye patches
    canvas_size = [IMG_WIDTH - IMG_HEIGHT, IMG_WIDTH/2];
    eyes_canvas = {
        {128 * ones(canvas_size, 'uint8'), 128 * ones(canvas_size, 'uint8')}, ...
        {128 * ones(canvas_size, 'uint8'), 128 * ones(canvas_size, 'uint8')}
    };
    
    preview_imgs = zeros(2, IMG_WIDTH, IMG_WIDTH, 'uint8');
    
    % Organize rects and centers
    rects = {
        {eye_rects(1:4), eye_rects(5:8)}, ...
        {eye_rects(9:12), eye_rects(13:16)}
    };
    
    pupil_center_list = {
        {pupil_centers(1:2), pupil_centers(3:4)}, ...
        {pupil_centers(5:6), pupil_centers(7:8)}
    };
    
    glint_center_list = {
        {glint_centers(1:2), glint_centers(3:4)}, ...
        {glint_centers(5:6), glint_centers(7:8)}
    };
    
    % Determine which eye to mask
    if (tracker.config.active_eye == -1)
        patch_mask_index = 2;
    elseif (tracker.config.active_eye == 1)
        patch_mask_index = 1;
    else
        patch_mask_index = -1;
    end
    
    % Process each image
    eye_patches = cell(1, 2);
    for img_idx = 1:2
        img = imgs{img_idx};
        [img_h, img_w] = size(img);
        patches = cell(1, 2);
        
        for patch_idx = 1:2
            rect = rects{img_idx}{patch_idx};
            x1 = int32(rect(1)); y1 = int32(rect(2));
            w = int32(rect(3)); h = int32(rect(4));
            x2 = x1 + w; y2 = y1 + h;
            
            % Check for invalid rect
            if x1 < 1 || y1 < 1 || x2 > img_w || y2 > img_h || x1 > x2 || y1 > y2
                FRAME_COLOR = FRAME_WARNING;
                patch = zeros(96, 96, 'uint8');  % Default empty patch
            elseif w == 0 || h == 0
                patch = zeros(96, 96, 'uint8');  % Empty eye-patch
            else
                patch = img(y1:y2, x1:x2);  % Extract eye patch
            end
            
            % Get pupil and glint centers
            pupil_xy = pupil_center_list{img_idx}{patch_idx};
            glint_xy = glint_center_list{img_idx}{patch_idx};
            
            % Draw pupil and glint if valid
            [patch_h, patch_w] = size(patch);
            if x1 <= pupil_xy(1) && pupil_xy(1) < x2 && y1 <= pupil_xy(2) && pupil_xy(2) < y2
                pupil_x = int32(pupil_xy(1) - x1);
                pupil_y = int32(pupil_xy(2) - y1);
                % Draw white pupil circle
                patch = drawCircle(patch, pupil_x, pupil_y, 5, 255);
            elseif ~(patch_mask_index == patch_idx)
                FRAME_COLOR = FRAME_WARNING;
            end
            
            if x1 <= glint_xy(1) && glint_xy(1) < x2 && y1 <= glint_xy(2) && glint_xy(2) < y2
                glint_x = int32(glint_xy(1) - x1);
                glint_y = int32(glint_xy(2) - y1);
                % Draw gray glint circle
                patch = drawCircle(patch, glint_x, glint_y, 3, 200);
            elseif ~(patch_mask_index == patch_idx)
                FRAME_COLOR = FRAME_WARNING;
            end
            
            % Draw rectangle if valid
            if ~(w == 0 || h == 0)
                patch = drawRectangle(patch, [1, 1, patch_w-1, patch_h-1], FRAME_COLOR, 6);
            end
            
            patches{patch_idx} = patch;
        end
        eye_patches{img_idx} = patches;
    end
    
    % Arrange eye patches on canvas
    margin = 10;
    for canvas_idx = 1:2
        for rect_idx = 1:2
            if canvas_idx > length(eye_patches) || rect_idx > length(eye_patches{canvas_idx})
                continue;
            end
            
            patch = eye_patches{canvas_idx}{rect_idx};
            [patch_h, patch_w] = size(patch);
            [canvas_h, canvas_w] = size(eyes_canvas{canvas_idx}{rect_idx});
            
            % Calculate scale
            scale = min([(canvas_w - 2 * margin) / patch_w, (canvas_h - 2 * margin) / patch_h]);
            new_w = int32(patch_w * scale);
            new_h = int32(patch_h * scale);
            
            % Resize patch
            resized_patch = imresize(patch, [new_h, new_w]);
            
            % Calculate position
            start_x = floor((canvas_w - new_w) / 2);
            start_y = floor((canvas_h - new_h) / 2);
            
            % Place on canvas if not masked
            if ~(rect_idx == patch_mask_index)
                eyes_canvas{canvas_idx}{rect_idx}(start_y+1:start_y+new_h, start_x+1:start_x+new_w) = resized_patch;
            end
        end
    end
    
    % Create final preview images
    for idx = 1:2
        original_img = imgs{idx};
        eye1_canvas = eyes_canvas{idx}{1};
        eye2_canvas = eyes_canvas{idx}{2};
        
        % Draw frames around canvases
        eye1_canvas = drawRectangle(eye1_canvas, [1, 1, size(eye1_canvas, 2)-1, size(eye1_canvas, 1)-1], FRAME_COLOR, 2);
        eye2_canvas = drawRectangle(eye2_canvas, [1, 1, size(eye2_canvas, 2)-1, size(eye2_canvas, 1)-1], FRAME_COLOR, 2);
        
        % Draw frame around original image
        original_img = drawRectangle(original_img, [1, 1, size(original_img, 2)-1, size(original_img, 1)-1], FRAME_COLOR, FRAME_WIDTH);
        
        % Place original image in preview
        preview_imgs(idx, 1:IMG_HEIGHT, 1:IMG_WIDTH) = original_img;
        
        % Combine eye canvases
        [canvas_h, canvas_w] = size(eye1_canvas);
        combined_canvas = zeros(canvas_h, 2 * canvas_w, 'uint8');
        combined_canvas(:, 1:canvas_w) = eye1_canvas;
        combined_canvas(:, canvas_w+1:2*canvas_w) = eye2_canvas;
        
        % Place combined canvas in preview
        preview_imgs(idx, IMG_HEIGHT+1:IMG_HEIGHT+canvas_h, 1:2*canvas_w) = combined_canvas;
    end

    % get the left and right previews
    left_preview = squeeze(preview_imgs(1, :, :));
    right_preview = squeeze(preview_imgs(2, :, :));
end

% Helper function to draw a circle
function img = drawCircle(img, cx, cy, radius, color)
    [h, w] = size(img);
    [x, y] = meshgrid(1:w, 1:h);
    mask = (x - cx).^2 + (y - cy).^2 <= radius^2;
    img(mask) = color;
end

% Helper function to draw a rectangle
function img = drawRectangle(img, rect, color, lineWidth)
    x1 = rect(1);
    y1 = rect(2);
    x2 = rect(3);
    y2 = rect(4);
    [h, w] = size(img);
    
    % Create vertical lines
    for i = 0:lineWidth-1
        x_left = min(max(x1 + i, 1), w);
        x_right = min(max(x2 - i, 1), w);
        y_range = min(max(y1, 1), h):min(max(y2, 1), h);
        img(y_range, x_left) = color;
        img(y_range, x_right) = color;
    end
    
    % Create horizontal lines
    for i = 0:lineWidth-1
        y_top = min(max(y1 + i, 1), h);
        y_bottom = min(max(y2 - i, 1), h);
        x_range = min(max(x1, 1), w):min(max(x2, 1), w);
        img(y_top, x_range) = color;
        img(y_bottom, x_range) = color;
    end
end