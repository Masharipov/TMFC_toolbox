function [masks] = tmfc_create_masks(SPM_paths,subject_paths,anat_paths,func_paths,options,seg_paths)

% =======[ Task-Modulated Functional Connectivity Denoise Toolbox ]========
% 
% Creates binary masks for GM (DVARS), WM/CSF (aCompCor & Phys regressors),
% and the whole brain (GSR).
%
% =========================================================================
% Copyright (C) 2026 Ruslan Masharipov
% License: GPL-3.0-or-later
% Contact: masharipov@ihb.spb.ru

% Detect PCT availability
hasPCT = (exist('parfor','builtin')==5) && license('test','Distrib_Computing_Toolbox');

% Create mask subfolders
%--------------------------------------------------------------------------
tmfc_dir = fileparts(which('TMFC_denoise.m'));

nSub = numel(SPM_paths);
segment_paths = cell(nSub,1);
glm_paths     = cell(nSub,1);
mask_paths    = cell(nSub,1);

if nargin<6
    seg_paths = [];
end

auto_existing_seg = ischar(seg_paths) && strcmpi(seg_paths,'auto');
manual_existing_seg = isstruct(seg_paths);

if manual_existing_seg && numel(seg_paths) ~= nSub
    error(['The number of existing segmentation entries (' num2str(numel(seg_paths)) ...
           ') must match the number of subjects (' num2str(nSub) ').']);
end

mask_folder_name = tmfc_mask_folder_name(options);

if ~isfield(options,'reuse_existing_masks')
    options.reuse_existing_masks = 1;
end

use_existing_seg = auto_existing_seg || manual_existing_seg;

for iSub = 1:nSub
    GLM_subfolder = fileparts(SPM_paths{iSub});
    segment_paths{iSub,1} = fullfile(GLM_subfolder,'TMFC_denoise','Segment');
    glm_paths{iSub,1} = fullfile(GLM_subfolder,'TMFC_denoise',mask_folder_name);
    mask_paths{iSub,1} = fullfile(glm_paths{iSub,1},'Masks');
    if ~exist(segment_paths{iSub},'dir'); mkdir(segment_paths{iSub}); end
    if ~exist(mask_paths{iSub},'dir'); mkdir(mask_paths{iSub}); end
    clear GLM_subfolder
end
masks.glm_paths = glm_paths; 
masks.mask_paths = mask_paths;

% Try to reuse existing final masks with identical mask parameters
%--------------------------------------------------------------------------
if options.reuse_existing_masks == 1

    reused_masks = false(nSub,1);
    prev_mask_dirs = cell(nSub,1);

    for iSub = 1:nSub
        prev_mask_dirs{iSub} = tmfc_find_existing_mask_dir(subject_paths{iSub},SPM_paths{iSub},mask_folder_name);

        if ~isempty(prev_mask_dirs{iSub})
            reused_masks(iSub) = tmfc_check_existing_final_masks(prev_mask_dirs{iSub},options);
        end
    end

    if all(reused_masks)

        disp('Existing final masks with identical mask parameters were found for all subjects.');
        disp('Copying existing masks and skipping mask creation.');

        for iSub = 1:nSub
            tmfc_copy_existing_final_masks(prev_mask_dirs{iSub},mask_paths{iSub},options);
        end

        if sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none')
            masks.WM  = cell(nSub,1);
            masks.CSF = cell(nSub,1);
            for iSub = 1:nSub
                masks.WM{iSub,1}  = fullfile(mask_paths{iSub},'rw_WM_mask_eroded_no_brainstem.nii');
                masks.CSF{iSub,1} = fullfile(mask_paths{iSub},'rw_CSF_mask_eroded_only_ventricles.nii');
            end
        end

        if options.DVARS == 1
            masks.GM = cell(nSub,1);
            for iSub = 1:nSub
                masks.GM{iSub,1} = fullfile(mask_paths{iSub},'rw_GM_mask.nii');
            end
        end

        if ~strcmpi(options.GSR,'none')
            masks.WB = cell(nSub,1);
            for iSub = 1:nSub
                masks.WB{iSub,1} = fullfile(mask_paths{iSub},'rw_Whole_brain_mask.nii');
            end
        end

        return

    elseif any(reused_masks)

        fprintf('Reusable final masks were found for %d/%d subjects only.\n',sum(reused_masks),nSub);
        disp('For safety, mask creation will be run for all subjects.');

    else

        disp('No complete reusable final masks found. Creating masks.');

    end
end

% Copy structural T1 files
%--------------------------------------------------------------------------
for iSub = 1:nSub
    anat_paths{iSub} = regexprep(anat_paths{iSub}, ',\d+$', '');

    [anat_dir, anat_name, anat_ext] = fileparts(anat_paths{iSub});

    switch lower(anat_ext)
        case '.nii'
            anat_copy_paths{iSub,1} = fullfile(segment_paths{iSub},[anat_name,anat_ext]);
            if ~exist(anat_copy_paths{iSub},'file')
                copyfile(anat_paths{iSub},anat_copy_paths{iSub});
            end
            anat_file{iSub,1} = [anat_name,'.nii'];

            % Segmentation files
            source_GM{iSub,1}             = fullfile(anat_dir,['c1' anat_name '.nii']);
            source_WM{iSub,1}             = fullfile(anat_dir,['c2' anat_name '.nii']);
            source_CSF{iSub,1}            = fullfile(anat_dir,['c3' anat_name '.nii']);
            source_bias_corrected{iSub,1} = fullfile(anat_dir,['m'  anat_name '.nii']);
            source_forward_field{iSub,1}  = fullfile(anat_dir,['y_' anat_name '.nii']);

        case '.img'
            anat_file_hdr{iSub,1} = [anat_name,'.hdr'];
            anat_copy_paths{iSub,1} = fullfile(segment_paths{iSub},[anat_name,anat_ext]);
            anat_copy_paths_hdr{iSub,1} = fullfile(segment_paths{iSub},anat_file_hdr{iSub,1} );
            if ~exist(anat_copy_paths{iSub},'file')
                copyfile(anat_paths{iSub},anat_copy_paths{iSub});
            end
            if ~exist(anat_copy_paths_hdr{iSub},'file')
                try
                    copyfile(fullfile(anat_dir,anat_file_hdr{iSub}),anat_copy_paths_hdr{iSub});
                catch
                    error('Missing header file (.hdr) for %s', anat_paths{iSub});
                end
            end
            anat_file{iSub,1} = [anat_name,'.nii'];
            
            % Segmentation files
            source_GM{iSub,1}             = fullfile(anat_dir,['c1' anat_name '.nii']);
            source_WM{iSub,1}             = fullfile(anat_dir,['c2' anat_name '.nii']);
            source_CSF{iSub,1}            = fullfile(anat_dir,['c3' anat_name '.nii']);
            source_bias_corrected{iSub,1} = fullfile(anat_dir,['m'  anat_name '.nii']);
            source_forward_field{iSub,1}  = fullfile(anat_dir,['y_' anat_name '.nii']);

        case '.gz'
            % Extract inner extension from anat_name
            [~, inner_name, inner_ext] = fileparts(anat_name);
            anat_file{iSub,1} = [inner_name,'.nii'];

            switch lower(inner_ext)
                case '.nii'
                    anat_copy_paths{iSub,1} = fullfile(segment_paths{iSub},[inner_name,inner_ext]);
                    if ~exist(anat_copy_paths{iSub},'file')
                        gunzip(anat_paths{iSub},segment_paths{iSub}); 
                    end
                    
                    % Segmentation files
                    source_GM{iSub,1}             = fullfile(anat_dir,['c1' inner_name '.nii']);
                    source_WM{iSub,1}             = fullfile(anat_dir,['c2' inner_name '.nii']);
                    source_CSF{iSub,1}            = fullfile(anat_dir,['c3' inner_name '.nii']);
                    source_bias_corrected{iSub,1} = fullfile(anat_dir,['m'  inner_name '.nii']);
                    source_forward_field{iSub,1}  = fullfile(anat_dir,['y_' inner_name '.nii']);

                case '.img'
                    anat_copy_paths{iSub,1}     = fullfile(segment_paths{iSub},[inner_name,'.img']);
                    anat_copy_paths_hdr{iSub,1} = fullfile(segment_paths{iSub},[inner_name,'.hdr']);

                    if ~exist(anat_copy_paths{iSub},'file') 
                        gunzip(anat_paths{iSub},segment_paths{iSub});
                    end

                    if ~exist(anat_copy_paths_hdr{iSub},'file')
                        src_hdr_plain = fullfile(anat_dir,[inner_name,'.hdr']);
                        src_hdr_gz = [src_hdr_plain,'.gz'];
                        if exist(src_hdr_plain,'file')
                            copyfile(src_hdr_plain,anat_copy_paths_hdr{iSub});
                        elseif exist(src_hdr_gz,'file')
                            gunzip(src_hdr_gz,segment_paths{iSub});
                        else
                            error('Missing header file (.hdr) for %s', anat_paths{iSub});
                        end
                    end
                    
                    % Segmentation files
                    source_GM{iSub,1}             = fullfile(anat_dir,['c1' inner_name '.nii']);
                    source_WM{iSub,1}             = fullfile(anat_dir,['c2' inner_name '.nii']);
                    source_CSF{iSub,1}            = fullfile(anat_dir,['c3' inner_name '.nii']);
                    source_bias_corrected{iSub,1} = fullfile(anat_dir,['m'  inner_name '.nii']);
                    source_forward_field{iSub,1}  = fullfile(anat_dir,['y_' inner_name '.nii']);

                otherwise
                    error('Unknown compressed structural format: %s', anat_paths{iSub});
            end

        otherwise
            error('Unknown format of structural image: %s', anat_paths{iSub});
    end
    clear anat_dir anat_name anat_ext inner_name inner_ext
end

% Segment T1 image
%--------------------------------------------------------------------------
spm('defaults','fmri');
spm_jobman('initcfg');
spm_get_defaults('cmdline',true);

existing_seg_available = false(nSub,1);

jSub = 0;
for iSub = 1:nSub
    forward_field{iSub,1} = fullfile(segment_paths{iSub},['y_',anat_file{iSub}]);
    bias_corrected{iSub,1} = fullfile(segment_paths{iSub},['m',anat_file{iSub}]);
    GM{iSub,1} = fullfile(segment_paths{iSub},['c1',anat_file{iSub}]);
    WM{iSub,1} = fullfile(segment_paths{iSub},['c2',anat_file{iSub}]);
    CSF{iSub,1} = fullfile(segment_paths{iSub},['c3',anat_file{iSub}]);

    % Try to copy existing segmentation files (automatically)
    if auto_existing_seg

        existing_seg_available(iSub) = ...
            exist(source_GM{iSub},'file') && ...
            exist(source_WM{iSub},'file') && ...
            exist(source_CSF{iSub},'file') && ...
            exist(source_forward_field{iSub},'file');

        if existing_seg_available(iSub)

            GM{iSub,1}            = tmfc_copy_seg_file(source_GM{iSub},segment_paths{iSub});
            WM{iSub,1}            = tmfc_copy_seg_file(source_WM{iSub},segment_paths{iSub});
            CSF{iSub,1}           = tmfc_copy_seg_file(source_CSF{iSub},segment_paths{iSub});
            forward_field{iSub,1} = tmfc_copy_seg_file(source_forward_field{iSub},segment_paths{iSub});

            if exist(source_bias_corrected{iSub},'file')
                bias_corrected{iSub,1} = tmfc_copy_seg_file(source_bias_corrected{iSub},segment_paths{iSub});
            else
                bias_corrected{iSub,1} = anat_copy_paths{iSub};
            end

        end
    
    % Try to copy segmentation files specified by user
    elseif manual_existing_seg

        if isfield(seg_paths,'GM') && isfield(seg_paths,'WM') && ...
           isfield(seg_paths,'CSF') && isfield(seg_paths,'def')

            if ~isempty(seg_paths(iSub).GM) && ~isempty(seg_paths(iSub).WM) && ...
               ~isempty(seg_paths(iSub).CSF) && ~isempty(seg_paths(iSub).def) && ...
               exist(regexprep(seg_paths(iSub).GM, ',\d+$', ''),'file') && ...
               exist(regexprep(seg_paths(iSub).WM, ',\d+$', ''),'file') && ...
               exist(regexprep(seg_paths(iSub).CSF,',\d+$', ''),'file') && ...
               exist(regexprep(seg_paths(iSub).def,',\d+$', ''),'file')

                existing_seg_available(iSub) = true;

                GM{iSub,1}            = tmfc_copy_seg_file(seg_paths(iSub).GM, segment_paths{iSub});
                WM{iSub,1}            = tmfc_copy_seg_file(seg_paths(iSub).WM, segment_paths{iSub});
                CSF{iSub,1}           = tmfc_copy_seg_file(seg_paths(iSub).CSF,segment_paths{iSub});
                forward_field{iSub,1} = tmfc_copy_seg_file(seg_paths(iSub).def,segment_paths{iSub});

                if isfield(seg_paths,'m') && ~isempty(seg_paths(iSub).m) && ...
                   exist(regexprep(seg_paths(iSub).m,',\d+$',''),'file')
                    bias_corrected{iSub,1} = tmfc_copy_seg_file(seg_paths(iSub).m,segment_paths{iSub});
                elseif isfield(seg_paths,'bias_corrected') && ~isempty(seg_paths(iSub).bias_corrected) && ...
                       exist(regexprep(seg_paths(iSub).bias_corrected,',\d+$',''),'file')
                    bias_corrected{iSub,1} = tmfc_copy_seg_file(seg_paths(iSub).bias_corrected,segment_paths{iSub});
                else
                    bias_corrected{iSub,1} = anat_copy_paths{iSub};
                end

            end
        end
    end

    if existing_seg_available(iSub)
        continue
    end

    if ~exist(bias_corrected{iSub},'file') || ~exist(GM{iSub},'file') || ~exist(WM{iSub},'file') || ~exist(CSF{iSub},'file') || ~exist(forward_field{iSub},'file')
        matlabbatch{1}.spm.spatial.preproc.channel.vols = anat_copy_paths(iSub);
        matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {fullfile(fileparts(which('spm.m')),'tpm','TPM.nii,1')};
        matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {fullfile(fileparts(which('spm.m')),'tpm','TPM.nii,2')};
        matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {fullfile(fileparts(which('spm.m')),'tpm','TPM.nii,3')};
        matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {fullfile(fileparts(which('spm.m')),'tpm','TPM.nii,4')};
        matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {fullfile(fileparts(which('spm.m')),'tpm','TPM.nii,5')};
        matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {fullfile(fileparts(which('spm.m')),'tpm','TPM.nii,6')};
        matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
        matlabbatch{1}.spm.spatial.preproc.warp.vox = NaN;
        matlabbatch{1}.spm.spatial.preproc.warp.bb = [NaN NaN NaN
                                                      NaN NaN NaN];
        jSub = jSub + 1;
        batch{jSub} = matlabbatch;
        clear matlabbatch
    end
end

if use_existing_seg
    fprintf('Existing complete SPM segmentation found for %d/%d subjects.\n', ...
        sum(existing_seg_available), nSub);

    if any(~existing_seg_available)
        fprintf('SPM segmentation will be run for %d subject(s) with missing c1/c2/c3/y_ files.\n', ...
            sum(~existing_seg_available));
    end
end

if jSub == 1
    spm_jobman('run',batch{1});
elseif jSub > 1
    % Waitbar
    tmfc_progress('init', jSub, 'Segmentation');
    % Parallel mode, PCT only 
    if options.parallel == 1 && hasPCT
        % Init parpool
        if isempty(gcp('nocreate')), parpool; end
        % DataQueue requires R2017a+ 
        D = [];
        try
            D = parallel.pool.DataQueue;
            afterEach(D, @(~) tmfc_progress('tick'));                     
        end
        % Init SPM
        spmSetup = parallel.pool.Constant(@() init_spm());
        parfor iSub = 1:jSub % ---- Parallel mode ----
            spmSetup.Value;
            spm_jobman('run',batch{iSub});
            try, send(D,[]); end % Update waitbar
        end
    else
        for iSub = 1:jSub    % ---- Serial mode ----
            spm_jobman('run',batch{iSub});
            tmfc_progress('tick'); % Update waitbar
        end
    end
    try tmfc_progress('done'); end % Close waitbar
end
clear batch

% Apply thresholds to tissue probability maps
%--------------------------------------------------------------------------
w = waitbar(0,'Please wait...','Name','Applying tissue probability thresholds');
for iSub = 1:nSub
    skull_stripped{iSub,1} = fullfile(mask_paths{iSub},'Skull_stripped_T1.nii');
    WB_mask{iSub,1} = fullfile(mask_paths{iSub},'Whole_brain_mask.nii');
    GM_mask{iSub,1} = fullfile(mask_paths{iSub},'GM_mask.nii');
    WM_mask{iSub,1} = fullfile(mask_paths{iSub},'WM_mask.nii');
    CSF_mask{iSub,1} = fullfile(mask_paths{iSub},'CSF_mask.nii');
    % Skull-stripped T1
    if ~exist(skull_stripped{iSub},'file')        
        input_images{1,1} = bias_corrected{iSub};
        input_images{2,1} = GM{iSub};
        input_images{3,1} = WM{iSub};
        input_images{4,1} = CSF{iSub};
        spm_imcalc(input_images,skull_stripped{iSub}, ...
            ['i1.*(((i2>0)+(i3>' num2str(options.WMmask.prob) ')+(i4>' num2str(options.CSFmask.prob) '))>0)'],{0,0,1,4});
        clear input_images
    end
    % Whole-brain binary mask
    if ~exist(WB_mask{iSub},'file')           
        input_images{1,1} = GM{iSub};
        input_images{2,1} = WM{iSub};
        input_images{3,1} = CSF{iSub};
        spm_imcalc(input_images,WB_mask{iSub}, ...
            ['((i1>0)+(i2>' num2str(options.WMmask.prob) ')+(i3>' num2str(options.CSFmask.prob) '))>0'],{0,0,0,2});
        clear input_images
    end
    % GM binary mask
    if ~exist(GM_mask{iSub},'file')           
        spm_imcalc(GM{iSub},GM_mask{iSub},['i1>' num2str(options.GMmask.prob)],{0,0,0,2});
    end
    % WM binary mask
    if ~exist(WM_mask{iSub},'file')           
        spm_imcalc(WM{iSub},WM_mask{iSub},['i1>' num2str(options.WMmask.prob)],{0,0,0,2});
    end
    % CSF binary mask 
    if ~exist(CSF_mask{iSub},'file')             
        spm_imcalc(CSF{iSub},CSF_mask{iSub},['i1>' num2str(options.CSFmask.prob)],{0,0,0,2});
    end
    try; waitbar(iSub/nSub,w,['Subject No. ' num2str(iSub)]); end % Update waitbar
end
try, if exist('w','var') && ishghandle(w), close(w); end, end

%==========================================================================
% Creating WM and CSF masks
%--------------------------------------------------------------------------
if sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none')

    % Erode WM masks
    %----------------------------------------------------------------------
    if options.WMmask.erode == 0
        for iSub = 1:nSub
            WM_eroded{iSub,1} = fullfile(mask_paths{iSub},'WM_mask_eroded.nii');
            copyfile(WM_mask{iSub},WM_eroded{iSub,1}); % Erode = 0: WM_mask_eroded is just a copy of WM_mask (no erosion)
        end
    else
        w = waitbar(0,'Please wait...','Name','Erosion of WM masks');
        for iSub = 1:nSub
            WM_eroded{iSub,1} = fullfile(mask_paths{iSub},'WM_mask_eroded.nii');
            if options.WMmask.erode > 0
                if ~exist(WM_eroded{iSub},'file')
                    V = spm_vol(WM_mask{iSub});
                    ima = spm_read_vols(V);
                    for iCycle = 1:options.WMmask.erode
                        ima = spm_erode(ima);
                    end
                    V.fname = WM_eroded{iSub,1};
                    spm_write_vol(V,ima);
                    clear V ima
                end
            end
            try; waitbar(iSub/nSub,w,['Subject No. ' num2str(iSub)]); end % Update waitbar
        end
        try, if exist('w','var') && ishghandle(w), close(w); end, end
    end
    
    % Dilate liberal GM mask
    %----------------------------------------------------------------------
    if options.GMmask.dilate == 0
        for iSub = 1:nSub
            GM_dilated{iSub,1} = GM_mask{iSub};
        end
    else
        w = waitbar(0,'Please wait...','Name','Dilation of GM masks');
        for iSub = 1:nSub
            GM_dilated{iSub,1} = fullfile(mask_paths{iSub},'GM_mask_dilated.nii');
            if options.GMmask.dilate > 0
                if ~exist(GM_dilated{iSub},'file')
                    V = spm_vol(GM_mask{iSub});
                    ima = spm_read_vols(V);
                    for iCycle = 1:options.GMmask.dilate
                        ima = spm_dilate(ima);
                    end
                    V.fname = GM_dilated{iSub,1};
                    spm_write_vol(V,ima);
                    clear V ima
                end
            end
            try; waitbar(iSub/nSub,w,['Subject No. ' num2str(iSub)]); end % Update waitbar
        end
        try, if exist('w','var') && ishghandle(w), close(w); end, end
    end
    
    % Subtract dilated GM masks from CSF mask
    %----------------------------------------------------------------------
    w = waitbar(0,'Please wait...','Name','Subtract dilated GM masks from CSF masks');
    for iSub = 1:nSub
        CSF_mask_GM_removed{iSub,1} = fullfile(mask_paths{iSub},'CSF_mask_GM_removed.nii');
        if ~exist(CSF_mask_GM_removed{iSub},'file')        
            input_images{1,1} = CSF_mask{iSub};
            input_images{2,1} = GM_dilated{iSub};
            spm_imcalc(input_images,CSF_mask_GM_removed{iSub},'(i1-i2)>0',{0,0,0,2});
            clear input_images
        end
        try; waitbar(iSub/nSub,w,['Subject No. ' num2str(iSub)]); end % Update waitbar
    end
    try, if exist('w','var') && ishghandle(w), close(w); end, end
    
    % Erode CSF masks
    %----------------------------------------------------------------------
    if options.CSFmask.erode == 0
        for iSub = 1:nSub
            CSF_eroded{iSub,1} = fullfile(mask_paths{iSub},'CSF_mask_eroded.nii');
            copyfile(CSF_mask_GM_removed{iSub},CSF_eroded{iSub,1}); % Erode = 0: CSF_mask_eroded is just a copy of CSF_mask_GM_removed (no erosion)
        end
    else
        w = waitbar(0,'Please wait...','Name','Erosion of CSF masks');
        for iSub = 1:nSub
            CSF_eroded{iSub,1} = fullfile(mask_paths{iSub},'CSF_mask_eroded.nii');
            if options.CSFmask.erode > 0
                if ~exist(CSF_eroded{iSub},'file')
                    V = spm_vol(CSF_mask_GM_removed{iSub});
                    ima = spm_read_vols(V);
                    for iCycle = 1:options.CSFmask.erode
                        ima = spm_erode(ima);
                    end
                    V.fname = CSF_eroded{iSub,1};
                    spm_write_vol(V,ima);
                    clear V ima
                end
            end
            try; waitbar(iSub/nSub,w,['Subject No. ' num2str(iSub)]); end % Update waitbar
        end
        try, if exist('w','var') && ishghandle(w), close(w); end, end
    end
    
    % Normalization and resampling to fMRI resolution
    %----------------------------------------------------------------------
    jSub = 0;
    for iSub = 1:nSub
        V = spm_vol(func_paths(iSub).fname{1});
        [BB,vx] = spm_get_bbox(V);
        vx = abs(vx);
        coreg = 0;
        wWM_eroded{iSub,1} = fullfile(mask_paths{iSub},   'w_WM_mask_eroded.nii');
        wCSF_eroded{iSub,1} = fullfile(mask_paths{iSub},  'w_CSF_mask_eroded.nii');
        wskull_stripped{iSub} = fullfile(mask_paths{iSub},'w_Skull_stripped_T1.nii');
        if ~exist(wWM_eroded{iSub},'file') || ~exist(wCSF_eroded{iSub},'file') || ~exist(wskull_stripped{iSub},'file')
            matlabbatch{1}.spm.spatial.normalise.write.subj.def = forward_field(iSub);
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample{1,1} = WM_eroded{iSub};
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample{2,1} = CSF_eroded{iSub};
            if ~exist(wskull_stripped{iSub},'file')
                matlabbatch{1}.spm.spatial.normalise.write.subj.resample{3,1} = skull_stripped{iSub};
                coreg = 1;
            end
            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = BB;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = vx;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w_';
            matlabbatch{2}.spm.spatial.coreg.write.ref{1,1} = func_paths(iSub).fname{1};
            matlabbatch{2}.spm.spatial.coreg.write.source{1,1} = wWM_eroded{iSub,1};
            matlabbatch{2}.spm.spatial.coreg.write.source{2,1} = wCSF_eroded{iSub,1};
            if coreg == 1
                matlabbatch{2}.spm.spatial.coreg.write.source{3,1} = wskull_stripped{iSub};
            end
            matlabbatch{2}.spm.spatial.coreg.write.roptions.interp = 4;
            matlabbatch{2}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
            matlabbatch{2}.spm.spatial.coreg.write.roptions.mask = 0;
            matlabbatch{2}.spm.spatial.coreg.write.roptions.prefix = 'r';
            jSub = jSub + 1;
            batch{jSub} = matlabbatch;
            clear matlabbatch
        end
        wWM_eroded{iSub,1} = fullfile(mask_paths{iSub},   'rw_WM_mask_eroded.nii');
        wCSF_eroded{iSub,1} = fullfile(mask_paths{iSub},  'rw_CSF_mask_eroded.nii');
        wskull_stripped{iSub} = fullfile(mask_paths{iSub},'rw_Skull_stripped_T1.nii');
        clear V BB vx coreg
    end
    
    if jSub == 1
        spm_jobman('run',batch{1});
    elseif jSub > 1
        % Waitbar
        tmfc_progress('init', jSub, 'Normalization: WM and CSF masks');
        % Parallel mode, PCT only 
        if options.parallel == 1 && hasPCT
            % Init parpool
            if isempty(gcp('nocreate')), parpool; end
            % DataQueue requires R2017a+ 
            D = [];
            try
                D = parallel.pool.DataQueue;
                afterEach(D, @(~) tmfc_progress('tick'));                     
            end
            % Init SPM
            spmSetup = parallel.pool.Constant(@() init_spm());
            parfor iSub = 1:jSub % ---- Parallel mode ----
                spmSetup.Value;
                spm_jobman('run',batch{iSub});
                try; send(D,[]); end % Update waitbar
            end
        else
            for iSub = 1:jSub    % ---- Serial mode ----
                spm_jobman('run',batch{iSub});
                tmfc_progress('tick'); % Update waitbar
            end
        end
        try tmfc_progress('done'); end % Close waitbar
    end
    clear batch
    
    % Remove brainstem voxels from WM mask and apply implicit SPM mask
    %----------------------------------------------------------------------
    w = waitbar(0,'Please wait...','Name','Removing brainstem from WM masks');
    for iSub = 1:nSub
        wWM_eroded_final{iSub,1} = fullfile(mask_paths{iSub},'rw_WM_mask_eroded_no_brainstem.nii');
        if ~exist(wWM_eroded_final{iSub},'file')  
            SPM = load(SPM_paths{iSub}).SPM;
            input_images{1,1} = wWM_eroded{iSub};
            input_images{2,1} = fullfile(tmfc_dir,'functions','masks','Harvard_Oxford_Brainstem_mask.nii');
            input_images{3,1} = fullfile(SPM.swd,SPM.VM.fname); 
            spm_imcalc(input_images,wWM_eroded_final{iSub},'(i1-i2).*i3>0.5',{0,0,0,2});
            clear input_images SPM
        end
        try; waitbar(iSub/nSub,w,['Subject No. ' num2str(iSub)]); end % Update waitbar
    end
    try, if exist('w','var') && ishghandle(w), close(w); end, end
    
    % Remove non-ventricle voxels from CSF masks and apply the implicit SPM mask
    %----------------------------------------------------------------------
    w = waitbar(0,'Please wait...','Name','Removing non-ventricle voxels from CSF masks');
    for iSub = 1:nSub
        wCSF_eroded_final{iSub,1} = fullfile(mask_paths{iSub},'rw_CSF_mask_eroded_only_ventricles.nii');
        if ~exist(wCSF_eroded_final{iSub},'file')
            SPM = load(SPM_paths{iSub}).SPM;
            input_images{1,1} = wCSF_eroded{iSub};
            input_images{2,1} = fullfile(tmfc_dir,'functions','masks','ALVIN_mask.nii');
            input_images{3,1} = fullfile(SPM.swd,SPM.VM.fname); 
            spm_imcalc(input_images,wCSF_eroded_final{iSub},'(i1.*(i2>50).*i3)>0.5',{0,0,0,2});
            clear input_images SPM
        end
        try; waitbar(iSub/nSub,w,['Subject No. ' num2str(iSub)]); end % Update waitbar
    end

    % Save paths
    %----------------------------------------------------------------------
    masks.WM = wWM_eroded_final;
    masks.CSF = wCSF_eroded_final;
    try, if exist('w','var') && ishghandle(w), close(w); end, end
end

%==========================================================================
% Creating GM masks
%--------------------------------------------------------------------------
if options.DVARS == 1

    % Normalization and resampling to fMRI resolution
    %----------------------------------------------------------------------
    jSub = 0;
    for iSub = 1:nSub
        V = spm_vol(func_paths(iSub).fname{1});
        [BB,vx] = spm_get_bbox(V);
        vx = abs(vx);
        coreg = 0;
        wGM_mask{iSub,1} = fullfile(mask_paths{iSub},     'w_GM_mask.nii');
        wskull_stripped{iSub} = fullfile(mask_paths{iSub},'w_Skull_stripped_T1.nii');
        if ~exist(wGM_mask{iSub},'file') || ~exist(wskull_stripped{iSub},'file')
            SPM = load(SPM_paths{iSub}).SPM;
            matlabbatch{1}.spm.spatial.normalise.write.subj.def = forward_field(iSub);
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample{1,1} = GM_mask{iSub};
            if ~exist(wskull_stripped{iSub},'file')
                matlabbatch{1}.spm.spatial.normalise.write.subj.resample{2,1} = skull_stripped{iSub};
                coreg = 1;
            end
            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = BB;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = vx;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w_';
            matlabbatch{2}.spm.spatial.coreg.write.ref{1,1} = func_paths(iSub).fname{1};
            matlabbatch{2}.spm.spatial.coreg.write.source{1,1} = wGM_mask{iSub,1};
            if coreg == 1
                matlabbatch{2}.spm.spatial.coreg.write.source{2,1} = wskull_stripped{iSub};
            end
            matlabbatch{2}.spm.spatial.coreg.write.roptions.interp = 4;
            matlabbatch{2}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
            matlabbatch{2}.spm.spatial.coreg.write.roptions.mask = 0;
            matlabbatch{2}.spm.spatial.coreg.write.roptions.prefix = 'r';
            wGM_mask{iSub,1} = fullfile(mask_paths{iSub},     'rw_GM_mask.nii');
            matlabbatch{3}.spm.util.imcalc.input{1,1} = wGM_mask{iSub};
            matlabbatch{3}.spm.util.imcalc.input{2,1} = fullfile(SPM.swd,SPM.VM.fname); 
            matlabbatch{3}.spm.util.imcalc.output = 'rw_GM_mask';
            matlabbatch{3}.spm.util.imcalc.outdir = mask_paths(iSub);
            matlabbatch{3}.spm.util.imcalc.expression = '(i1.*i2)>0.5';
            matlabbatch{3}.spm.util.imcalc.var = struct('name', {}, 'value', {});
            matlabbatch{3}.spm.util.imcalc.options.dmtx = 0;
            matlabbatch{3}.spm.util.imcalc.options.mask = 0;
            matlabbatch{3}.spm.util.imcalc.options.interp = 0;
            matlabbatch{3}.spm.util.imcalc.options.dtype = 2;
            jSub = jSub + 1;
            batch{jSub} = matlabbatch;
            clear matlabbatch SPM
        end
        wGM_mask{iSub,1} = fullfile(mask_paths{iSub},     'rw_GM_mask.nii');
        wskull_stripped{iSub} = fullfile(mask_paths{iSub},'rw_Skull_stripped_T1.nii');
        clear V BB vx coreg
    end

    if jSub == 1
        spm_jobman('run',batch{1});
    elseif jSub > 1
        % Waitbar
        tmfc_progress('init', jSub, 'Creating GM masks');
        % Parallel mode, PCT only 
        if options.parallel == 1 && hasPCT
            % Init parpool
            if isempty(gcp('nocreate')), parpool; end
            % DataQueue requires R2017a+ 
            D = [];
            try
                D = parallel.pool.DataQueue;
                afterEach(D, @(~) tmfc_progress('tick'));                     
            end
            % Init SPM
            spmSetup = parallel.pool.Constant(@() init_spm());
            parfor iSub = 1:jSub % ---- Parallel mode ----
                spmSetup.Value;
                spm_jobman('run',batch{iSub});
                try; send(D,[]); end % Update waitbar
            end
        else
            for iSub = 1:jSub    % ---- Serial mode ----
                spm_jobman('run',batch{iSub});
                tmfc_progress('tick'); % Update waitbar
            end
        end
        try tmfc_progress('done'); end % Close waitbar
    end
    clear batch

    % Save paths
    %----------------------------------------------------------------------
    masks.GM = wGM_mask;
end

%==========================================================================
% Creating whole-brain masks
%--------------------------------------------------------------------------
if ~strcmpi(options.GSR,'none')

    % Normalization and resampling to fMRI resolution
    %----------------------------------------------------------------------
    jSub = 0;
    for iSub = 1:nSub
        V = spm_vol(func_paths(iSub).fname{1});
        [BB,vx] = spm_get_bbox(V);
        vx = abs(vx);
        coreg = 0;
        wWB_mask{iSub,1} = fullfile(mask_paths{iSub},     'w_Whole_brain_mask.nii');
        wskull_stripped{iSub} = fullfile(mask_paths{iSub},'w_Skull_stripped_T1.nii');
        if ~exist(wWB_mask{iSub},'file') || ~exist(wskull_stripped{iSub},'file')
            SPM = load(SPM_paths{iSub}).SPM;
            matlabbatch{1}.spm.spatial.normalise.write.subj.def = forward_field(iSub);
            matlabbatch{1}.spm.spatial.normalise.write.subj.resample{1,1} = WB_mask{iSub};
            if ~exist(wskull_stripped{iSub},'file')
                matlabbatch{1}.spm.spatial.normalise.write.subj.resample{2,1} = skull_stripped{iSub};
                coreg = 1;
            end
            matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = BB;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = vx;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
            matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w_';
            matlabbatch{2}.spm.spatial.coreg.write.ref{1,1} = func_paths(iSub).fname{1};
            matlabbatch{2}.spm.spatial.coreg.write.source{1,1} = wWB_mask{iSub,1};
            if coreg == 1
                matlabbatch{2}.spm.spatial.coreg.write.source{2,1} = wskull_stripped{iSub};
            end
            matlabbatch{2}.spm.spatial.coreg.write.roptions.interp = 4;
            matlabbatch{2}.spm.spatial.coreg.write.roptions.wrap = [0 0 0];
            matlabbatch{2}.spm.spatial.coreg.write.roptions.mask = 0;
            matlabbatch{2}.spm.spatial.coreg.write.roptions.prefix = 'r';
            wWB_mask{iSub,1} = fullfile(mask_paths{iSub},     'rw_Whole_brain_mask.nii');
            matlabbatch{3}.spm.util.imcalc.input{1,1} = wWB_mask{iSub};
            matlabbatch{3}.spm.util.imcalc.input{2,1} = fullfile(SPM.swd,SPM.VM.fname); 
            matlabbatch{3}.spm.util.imcalc.output = 'rw_Whole_brain_mask';
            matlabbatch{3}.spm.util.imcalc.outdir = mask_paths(iSub);
            matlabbatch{3}.spm.util.imcalc.expression = '(i1.*i2)>0.5';
            matlabbatch{3}.spm.util.imcalc.var = struct('name', {}, 'value', {});
            matlabbatch{3}.spm.util.imcalc.options.dmtx = 0;
            matlabbatch{3}.spm.util.imcalc.options.mask = 0;
            matlabbatch{3}.spm.util.imcalc.options.interp = 0;
            matlabbatch{3}.spm.util.imcalc.options.dtype = 2;
            jSub = jSub + 1;
            batch{jSub} = matlabbatch;
            clear matlabbatch SPM
        end
        wWB_mask{iSub,1} = fullfile(mask_paths{iSub},     'rw_Whole_brain_mask.nii');
        wskull_stripped{iSub} = fullfile(mask_paths{iSub},'rw_Skull_stripped_T1.nii');
        clear V BB vx
    end

    if jSub == 1
        spm_jobman('run',batch{1});
    elseif jSub > 1
        % Waitbar
        tmfc_progress('init', jSub, 'Creating whole-brain masks');
        % Parallel mode, PCT only 
        if options.parallel == 1 && hasPCT
            % Init parpool
            if isempty(gcp('nocreate')), parpool; end
            % DataQueue requires R2017a+ 
            D = [];
            try
                D = parallel.pool.DataQueue;
                afterEach(D, @(~) tmfc_progress('tick'));                     
            end
            % Init SPM
            spmSetup = parallel.pool.Constant(@() init_spm());
            parfor iSub = 1:jSub % ---- Parallel mode ----
                spmSetup.Value;
                spm_jobman('run',batch{iSub});
                try; send(D,[]); end % Update waitbar
            end
        else
            for iSub = 1:jSub    % ---- Serial mode ----
                spm_jobman('run',batch{iSub});
                tmfc_progress('tick'); % Update waitbar
            end
        end
        try tmfc_progress('done'); end % Close waitbar
    end
    clear batch

    % Save paths
    %----------------------------------------------------------------------
    masks.WB = wWB_mask;
end
end

% SPM initialization
%--------------------------------------------------------------------------
function c = init_spm()
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_get_defaults('cmdline', true);
    c = onCleanup(@() []); 
end

% Copy segmentation files
%--------------------------------------------------------------------------
function dst = tmfc_copy_seg_file(src,dst_dir)

src = regexprep(src, ',\d+$', '');

if ~exist(src,'file')
    error('File not found: %s', src);
end

[src_dir,src_name,src_ext] = fileparts(src);

if ~ismember(lower(src_ext),{'.nii','.img'})
    error('Unsupported segmentation file format: %s', src);
end

dst = fullfile(dst_dir,[src_name src_ext]);

if ~exist(dst,'file')
    copyfile(src,dst);
end

% Copy Analyze header if needed
if strcmpi(src_ext,'.img')
    src_hdr = fullfile(src_dir,[src_name '.hdr']);
    dst_hdr = fullfile(dst_dir,[src_name '.hdr']);

    if ~exist(src_hdr,'file')
        error('Missing header file: %s', src_hdr);
    end

    if ~exist(dst_hdr,'file')
        copyfile(src_hdr,dst_hdr);
    end
end

end

% Mask folder name
%--------------------------------------------------------------------------
function mask_folder_name = tmfc_mask_folder_name(options)

mask_folder_name = ['[WM' num2str(round(options.WMmask.prob*100)) 'e' num2str(options.WMmask.erode) ...
                    ']_[CSF' num2str(round(options.CSFmask.prob*100)) 'e' num2str(options.CSFmask.erode) ...
                    ']_[GM' num2str(round(options.GMmask.prob*100)) 'd' num2str(options.GMmask.dilate) ']'];

end

% Find existing mask directory
%--------------------------------------------------------------------------
function prev_mask_dir = tmfc_find_existing_mask_dir(subject_path,current_SPM_path,mask_folder_name)

prev_mask_dir = '';

current_GLM_dir = fileparts(current_SPM_path);
current_tmfc_dir = fullfile(current_GLM_dir,'TMFC_denoise');

tmfc_dirs = tmfc_find_dirs_by_name(subject_path,'TMFC_denoise');

for iDir = 1:numel(tmfc_dirs)

    candidate_tmfc_dir = tmfc_dirs{iDir};

    % Skip current GLM's TMFC_denoise folder
    if strcmpi(candidate_tmfc_dir,current_tmfc_dir)
        continue
    end

    candidate_mask_dir = fullfile(candidate_tmfc_dir,mask_folder_name,'Masks');

    if exist(candidate_mask_dir,'dir')
        prev_mask_dir = candidate_mask_dir;
        return
    end
end

end

% Recursively find folders by name
%--------------------------------------------------------------------------
function out_dirs = tmfc_find_dirs_by_name(root_dir,target_name)

out_dirs = {};

if ~exist(root_dir,'dir')
    return
end

items = dir(root_dir);

for iItem = 1:numel(items)

    name = items(iItem).name;

    if ~items(iItem).isdir || strcmp(name,'.') || strcmp(name,'..')
        continue
    end

    full_dir = fullfile(root_dir,name);

    if strcmpi(name,target_name)
        out_dirs{end+1,1} = full_dir; 
        continue
    end

    % Optional: skip folders that are usually large and irrelevant
    if strcmpi(name,'Raw') || strcmpi(name,'DICOM') || strcmpi(name,'dicom')
        continue
    end

    nested_dirs = tmfc_find_dirs_by_name(full_dir,target_name);

    if ~isempty(nested_dirs)
        out_dirs = [out_dirs; nested_dirs(:)]; 
    end
end

end

% Check existing final masks
%--------------------------------------------------------------------------
function mask_ok = tmfc_check_existing_final_masks(prev_mask_dir,options)

mask_ok = true;

need_WM_CSF = sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none');
need_GM     = options.DVARS == 1;
need_WB     = ~strcmpi(options.GSR,'none');

if need_WM_CSF
    if ~exist(fullfile(prev_mask_dir,'rw_WM_mask_eroded_no_brainstem.nii'),'file') || ...
       ~exist(fullfile(prev_mask_dir,'rw_CSF_mask_eroded_only_ventricles.nii'),'file')
        mask_ok = false;
        return
    end
end

if need_GM
    if ~exist(fullfile(prev_mask_dir,'rw_GM_mask.nii'),'file')
        mask_ok = false;
        return
    end
end

if need_WB
    if ~exist(fullfile(prev_mask_dir,'rw_Whole_brain_mask.nii'),'file')
        mask_ok = false;
        return
    end
end

end

% Copy existing final masks
%--------------------------------------------------------------------------
function tmfc_copy_existing_final_masks(prev_mask_dir,new_mask_dir,options)

need_WM_CSF = sum(options.aCompCor)~=0 || ~strcmpi(options.WM_CSF,'none');
need_GM     = options.DVARS == 1;
need_WB     = ~strcmpi(options.GSR,'none');

if ~exist(new_mask_dir,'dir')
    mkdir(new_mask_dir);
end

if need_WM_CSF
    copyfile(fullfile(prev_mask_dir,'rw_WM_mask_eroded_no_brainstem.nii'), ...
             fullfile(new_mask_dir,'rw_WM_mask_eroded_no_brainstem.nii'));

    copyfile(fullfile(prev_mask_dir,'rw_CSF_mask_eroded_only_ventricles.nii'), ...
             fullfile(new_mask_dir,'rw_CSF_mask_eroded_only_ventricles.nii'));
end

if need_GM
    copyfile(fullfile(prev_mask_dir,'rw_GM_mask.nii'), ...
             fullfile(new_mask_dir,'rw_GM_mask.nii'));
end

if need_WB
    copyfile(fullfile(prev_mask_dir,'rw_Whole_brain_mask.nii'), ...
             fullfile(new_mask_dir,'rw_Whole_brain_mask.nii'));
end

end
