function [ROI_set] = tmfc_select_ROIs_GUI(tmfc)

% ========= Task-Modulated Functional Connectivity (TMFC) toolbox =========
%
% Opens a GUI window for selecting ROI masks. Creates group mean binary 
% mask based on 1st-level masks (see SPM.VM) and applies it to all selected
% ROIs. Empty ROIs will be removed. Masked ROIs will be limited to only
% voxels which have data for all subjects. The dimensions, orientation, and
% voxel sizes of the masked ROI images will be adjusted according to the
% group mean binary mask.
%
% FORMAT [ROI_set] = tmfc_select_ROIs_GUI(tmfc)
%
%   tmfc.subjects.path     - List of paths to SPM.mat files for N subjects
%   tmfc.project_path      - The path where all results will be saved
%
% =========================================================================
%
% Copyright (C) 2023 Ruslan Masharipov
% 
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with this program. If not, see <https://www.gnu.org/licenses/>.
%
% Contact email: masharipov@ihb.spb.ru


% Enter a name for the ROI set
% !!! PUT CODE HERE FOR ROI SET NAME (from tmfc_ROI_SET)
% TEMPORARY CODE:
ROI_set.set_name = '300_ROIs';

% Select ROIs
[paths] = spm_select(inf,'any','Select ROI masks',{},pwd);
for i = 1:size(paths,1)
    ROI_set.ROIs(i).path = deblank(paths(i,:));
    [~, ROI_set.ROIs(i).name, ~] = fileparts(deblank(paths(i,:)));
end
% !!! YOU CAN ALSO ADD ALL NECESSARY SUPPLEMENTARY CODE FROM tmfc_select_ROIs_GUI_OLD

% Create 'Masked_ROIs' folder
if ~isfolder([tmfc.project_path filesep 'Masked_ROIs' filesep ROI_set.set_name])
    mkdir([tmfc.project_path filesep 'Masked_ROIs' filesep ROI_set.set_name]);
end

% Create group mean binary mask
for i = 1:length(tmfc.subjects)
    sub_mask{i,1} = [tmfc.subjects(i).path(1:end-7) 'mask.nii'];
end
group_mask = [tmfc.project_path filesep 'Masked_ROIs' filesep ROI_set.set_name filesep 'group_mean_mask.nii'];
spm_imcalc(sub_mask,group_mask,'prod(X)',{1,0,1,2});

% Calculate ROI size before masking
w = waitbar(0,'Please wait...','Name','Calculating raw ROI sizes');
group_mask = spm_vol(group_mask);
N = numel(ROI_set.ROIs);
for i = 1:N
    ROI_mask = spm_vol(ROI_set.ROIs(i).path);           
    Y = zeros(group_mask.dim(1:3));
    % Loop through slices
    for p = 1:group_mask.dim(3)
        % Adjust dimensions, orientation, and voxel sizes to group mask
        B = spm_matrix([0 0 -p 0 0 0 1 1 1]);
        X = zeros(1,prod(group_mask.dim(1:2))); 
        M = inv(B * inv(group_mask.mat) * ROI_mask.mat);
        d = spm_slice_vol(ROI_mask, M, group_mask.dim(1:2), 1);
        d(isnan(d)) = 0;
        X(1,:) = d(:)';
        Y(:,:,p) = reshape(X,group_mask.dim(1:2));
    end
    % Raw ROI size (in voxels)
    ROI_set.ROIs(i).raw_size = nnz(Y);
    try
        waitbar(i/N,w,['ROI № ' num2str(i,'%.f')]);
    end
end

try
    close(w)
end

% Mask the ROI images by the goup mean binary mask
w = waitbar(0,'Please wait...','Name','Masking ROIs by group mean mask');
input_images{1,1} = group_mask.fname;
for i = 1:N
    input_images{2,1} = ROI_set.ROIs(i).path;
    ROI_mask = [tmfc.project_path filesep 'Masked_ROIs' filesep ROI_set.set_name filesep ROI_set.ROIs(i).name '_masked.nii'];
    spm_imcalc(input_images,ROI_mask,'(i1>0).*(i2>0)',{0,0,1,2});
    try
        waitbar(i/N,w,['ROI № ' num2str(i,'%.f')]);
    end
end

try
    close(w)
end

% Calculate ROI size after masking
w = waitbar(0,'Please wait...','Name','Calculating masked ROI sizes');
for i = 1:N
    ROI_set.ROIs(i).masked_size = nnz(spm_read_vols(spm_vol([tmfc.project_path filesep 'Masked_ROIs' filesep ROI_set.set_name filesep ROI_set.ROIs(i).name '_masked.nii'])));
    ROI_set.ROIs(i).masked_size_percents = 100*ROI_set.ROIs(i).masked_size/ROI_set.ROIs(i).raw_size;
    try
        waitbar(i/N,w,['ROI № ' num2str(i,'%.f')]);
    end
end

try
    close(w)
end

% Remove empty ROIs
% !!! FIND EMPTY ROIs (see ROI_set.ROIs.masked_size == 0)
% !!! ADD GUI HERE WHERE WE NOTIFY USER THAT EMPTY ROIs WILL BE REMOVED
% !!! SHOW WHICH ROIs WILL BE REMOVED
% !!! REMOVE EMPTY ROIs FROM THE ROI_set variable

% Remove cropped ROIs
% !!! ADD GUI HERE WHERE USER CAN REMOVW HIGHLY CROPPED IMAGES 
% !!! REMOVE THESE ROIs FROM THE ROI_set variable

% !!! UPDATE TMFC variable if function was called via TMFC GUI

end