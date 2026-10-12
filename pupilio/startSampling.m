function [success, status] = startSampling(trackerHandler)
    if nargin < 1 || isempty(trackerHandler)
        error('Tracker handler required.');
    end
    
    if ~isfield(trackerHandler, 'isInitialized') || ~trackerHandler.isInitialized
        error('Tracker not initialized.');
    end
    
    [s, isSampling] = getSamplingStatus(trackerHandler);
    if s && isSampling
        error('Sampling is already running; call stopSampling first.');
    end
    
    LIB_NAME = trackerHandler.libName;
    SUCCESS_CODE = 0;

    try
        status = calllib(LIB_NAME, 'pupil_io_start_sampling');
        pause(0.05);
        success = (status == SUCCESS_CODE);
        if success
            trackerHandler.isSampling = true;
            fprintf('[%s] Sampling started\n', LIB_NAME);
        else
            warning('[%s] Sampling start failed (Status: %d)', LIB_NAME, status);
        end
    catch ME
        success = false;
        status = -1;
        fprintf('[%s] Critical sampling error: %s\n', LIB_NAME, ME.message);
    end
end

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