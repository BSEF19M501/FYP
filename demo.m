%%
clc
fprintf('##############################################################\n')
fprintf('Demo for fast dense descriptor extraction code for the papers:\n\n - J.R.R. Uijlings, I.C. Duta, E. Sangineto, and N. Sebe\n   "Video Classification with Densely Extracted HOG/HOF/MBH Features:\n   An Evaluation of the Accuracy/Computational Efficiency Trade-off"\n   In International Journal of Multimedia Information Retrieval (IJMIR), 2015.\n - I.C. Duta, J.R.R. Uijlings, T.A. Nguyen, K. Aizawa, A.G. Hauptmann, B. Ionescu, N. Sebe\n   "Histograms of Motion Gradients for Real-time Video Classification" \n   In International Workshop on Content-based Multimedia Indexing (CBMI), 2016.\n\n');
fprintf('Please cite our works when using this code!\n\n');
fprintf('This code requires the Matlab vision toolbox.\n');
fprintf('##############################################################\n\n')
% pause(1);
% Setup a global variable which contains the path of video files
global DATAopts
DATAopts.videoPath = '%s';

%settings
blockSize = [8 8 6]; % block size is 8 by 8 pixels by 6 frames, but we will vary the number of frames
numBlocks = [3 3 2]; % 3 x3 spatial blocks and 2 temporal blocks
numOr = 8; % Quantization in 8 orientations
flowMethod = 'Horn-Schunck'; % the optical flow choice

% videosFolder = 'E:\bsef19m501\RealTime_dense_descriptors-master\Videos';

runCode();

allVidsPCA();

% runSVM();
% 
run_disp_SVM();
% 
% runSVM2();

% run_SVM_without_19();

%runSVMHyperparameterTuning();

subjectNames = {'fyc', 'hy', 'ljg', 'lqf', 'lsl', 'ml', 'nhz', 'rj', 'syj', 'wl', 'wq', 'wyc', 'xch', 'xxj', 'yjf', 'zc', 'zdx', 'zjg', 'zl', 'zyf'};
sequenceNames = {'00_1', '00_2', '00_3', '00_4'};
  
% % Run complete code
% runCompleteCode(videoPath);

% fprintf('\nSVM Done!\n');

fprintf('\nDone!\n');

function [vid, videoReadTime] = loadVideo(videoPath)

    if ~exist(videoPath, 'file')
    error('Video file "%s" does not exist', videoPath);
    end

    if exist('mmread', 'file')
        % Under Linux, Fedora 20, mmread was almost 5x faster. Just download mmread from:
        % http://www.mathworks.co.uk/matlabcentral/fileexchange/8028-mmread
        % and make sure to set your path correctly
        fprintf('Using mmread to load video');
        tic;
        vid = VideoRead(videoPath);
        videoReadTime = toc;
        fprintf('... took %.2f seconds\n', videoReadTime);
    else
        fprintf('Using VideoReader from Matlab to load in video.\nWarning: We found that loading videos using native Matlab code (under Fedora 20) took more \ntime than the HOG features sampled at every frame. Instead, using the external library\nmmread loading a video is 8x faster. See comments in demo.m\n');
        tic
        vid = VideoReadNative(videoPath);
        videoReadTime = toc;
        fprintf('Loaded video in %.2f seconds\n', videoReadTime);
    end
end

function [hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo] = extractFeatures(vid, videoReadTime)
    
    % Parameters
    blockSize = [16 16 6];
    numBlocks = [2 2 1];
    numOr = 9;
    flowMethod = 'Horn-Schunck';

    % For-loop over the sampling rate for HOG
    fprintf('\nNow extracting HOG features. Timings below include loading the video (as in our paper):\n');
    hogDesc = cell(4, 1);
    hogInfo = cell(4, 1);
    idx = 1;
    for frameSampleRate = [1 2 3 6]
        tic
        % Subsample framerate of video
        sampledVid = vid(:, :, 1:frameSampleRate:end);

        % Get correct number of frames per block
        blockSize(3) = 6 / frameSampleRate;

        % Get HOG descriptors
        [hogDesc{idx}, hogInfo{idx}] = Video2DenseHOGVolumes(sampledVid, blockSize, numBlocks, numOr);
        idx = idx + 1;

        % Print statistics
        extractionTimeHOG(idx) = toc;
        totalDescriptorTime = extractionTimeHOG(idx) + videoReadTime;
        fprintf('HOG: frames/block: %d sample rate: %d sec/vid: %.2f frame/sec: %.2f\n', ...
            blockSize(3), frameSampleRate, totalDescriptorTime, size(vid, 3) / totalDescriptorTime);
    end

    % For-loop over the sampling rate for HOF
    fprintf('\nNow extracting HOF features. Timings below include loading the video (as in our paper):\n');
    hofDesc = cell(4, 1);
    hofInfo = cell(4, 1);
    idx = 1;
    for frameSampleRate = [1 2 3 6]
        tic
        % Subsample framerate of video
        sampledVid = vid(:, :, 1:frameSampleRate:end);

        % Get correct number of frames per block
        blockSize(3) = 6 / frameSampleRate;

        % Get HOG descriptors
        [hofDesc{idx}, hofInfo{idx}] = ...
            Video2DenseHOFVolumes(sampledVid, blockSize, numBlocks, numOr, flowMethod);
        idx = idx + 1;

        % Print statistics
        extractionTimeHOF(idx) = toc;
        totalDescriptorTime = extractionTimeHOF(idx) + videoReadTime;
        fprintf('HOF: frames/block: %d sample rate: %d sec/vid: %.2f frame/sec: %.2f\n', ...
            blockSize(3), frameSampleRate, totalDescriptorTime, size(vid, 3) / totalDescriptorTime);
    end

    % For-loop over the sampling rate for MBH
    fprintf('\nNow extracting MBH features. Timings below include loading the video (as in our paper):\n');
    MBHRowDesc = cell(4, 1);
    MBHColDesc = cell(4, 1);
    mbhInfo = cell(4, 1);
    idx = 1;
    for frameSampleRate = [1 2 3 6]
        tic
        % Subsample framerate of video
        sampledVid = vid(:, :, 1:frameSampleRate:end);

        % Get correct number of frames per block
        blockSize(3) = 6 / frameSampleRate;

        % Get HOG descriptors
        [MBHRowDesc{idx}, MBHColDesc{idx}, mbhInfo{idx}] = ...
            Video2DenseMBHVolumes(sampledVid, blockSize, numBlocks, numOr, flowMethod);
        idx = idx + 1;

        % Print statistics
        extractionTimeMBH(idx) = toc;
        totalDescriptorTime = extractionTimeMBH(idx) + videoReadTime;
        fprintf('MBH: frames/block: %d sample rate: %d sec/vid: %.2f frame/sec: %.2f\n', ...
            blockSize(3), frameSampleRate, totalDescriptorTime, size(vid, 3) / totalDescriptorTime);
    end

    % For-loop over the sampling rate for HMG
    fprintf('\nNow extracting HMG features. Timings below include loading the video (as in our paper):\n');
    hmgDesc = cell(4, 1);
    hmgInfo = cell(4, 1);
    idx = 1;
    for frameSampleRate = [1 2 3 6]
        tic
        % Subsample framerate of video
        sampledVid = vid(:, :, 1:frameSampleRate:end);

        % Get correct number of frames per block
        blockSize(3) = 6 / frameSampleRate;

        % Get HMG descriptors
        [hmgDesc{idx}, hmgInfo{idx}] = Video2DenseHMGVolumes(sampledVid, blockSize, numBlocks, numOr);
        idx = idx + 1;

        % Print statistics
        extractionTimeHMG(idx) = toc;
        totalDescriptorTime = extractionTimeHMG(idx) + videoReadTime;
        fprintf('HMG: frames/block: %d sample rate: %d sec/vid: %.2f frame/sec: %.2f\n', ...
            blockSize(3), frameSampleRate, totalDescriptorTime, size(vid, 3) / totalDescriptorTime);
    end
end

% Function to perform binning and L2 normalization on descriptors
function descriptors = performBinningAndNormalization(descriptors)
    numBins = 64; % Number of bins for histogram binning

    for idx = 1:numel(descriptors)
        descriptor = descriptors{idx};

        % Perform binning
        descriptor = histc(descriptor(:), linspace(0, 1, numBins+1));

        % Perform L2 normalization
        descriptor = descriptor / norm(descriptor, 2);

        % Update the descriptors
        descriptors{idx} = descriptor;
    end
end

function [hogDescNorm, hofDescNorm, mbhxDescNorm, mbhyDescNorm, hmgDescNorm] = BinAndNormalize(hogDesc, hofDesc, MBHRowDesc, MBHColDesc, hmgDesc)

    hogDescNorm = performBinningAndNormalization(hogDesc);
    hofDescNorm = performBinningAndNormalization(hofDesc);
    mbhxDescNorm = performBinningAndNormalization(MBHRowDesc);
    mbhyDescNorm = performBinningAndNormalization(MBHColDesc);
    hmgDescNorm = performBinningAndNormalization(hmgDesc);

end

function [hogFisherVector, hofFisherVector, mbhFisherVector, hmgFisherVector] = fisherVectorGenerator(vlfeatPath, hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo)

    % Add VLFeat library to the MATLAB path
    run(fullfile(vlfeatPath, 'toolbox/vl_setup'));
    
    % Set the desired size for the descriptors
    desiredSize = size(hogDesc{1});

    % Resize the HOG descriptors to the desired size
    resizedHOGDesc = resizeDescriptors(hogDesc, desiredSize);
    
    % Resize the HOF descriptors to the desired size
    resizedHOFDesc = resizeDescriptors(hofDesc, desiredSize);
    
    % Resize the MBH descriptors to the desired size
    resizedMBHRowDesc = resizeDescriptors(MBHRowDesc, desiredSize);
    resizedMBHColDesc = resizeDescriptors(MBHColDesc, desiredSize);
    
    % Resize the HMG descriptors to the desired size
    resizedHMGDesc = resizeDescriptors(hmgDesc, desiredSize);

    % Load the resized descriptors from disk
    HOG = single(cat(4, resizedHOGDesc{:}));
    HOF = single(cat(4, resizedHOFDesc{:}));
    MBHRow = single(cat(4, resizedMBHRowDesc{:}));
    MBHCol = single(cat(4, resizedMBHColDesc{:}));
    HMG = single(cat(4, resizedHMGDesc{:}));

    % Set the number of clusters
    K = 16;

    % Train the GMM for HOG
    HOG_2D = reshape(HOG, [], size(HOG, 4))';
    [hogMeans, hogCovariances, hogPriors] = vl_gmm(HOG_2D, K);

    % Compute the Fisher vector for HOG
    hogFisherVector = vl_fisher(HOG_2D, hogMeans, hogCovariances, hogPriors);

    % Train the GMM for HOF
    HOF_2D = reshape(HOF, [], size(HOF, 4))';
    [hofMeans, hofCovariances, hofPriors] = vl_gmm(HOF_2D, K);

    % Compute the Fisher vector for HOF
    hofFisherVector = vl_fisher(HOF_2D, hofMeans, hofCovariances, hofPriors);

    % Train the GMM for MBH
    MBH_2D = reshape(cat(3, MBHRow, MBHCol), [], size(MBHRow, 4) + size(MBHCol, 4))';
    [mbhMeans, mbhCovariances, mbhPriors] = vl_gmm(MBH_2D, K);

    % Compute the Fisher vector for MBH
    mbhFisherVector = vl_fisher(MBH_2D, mbhMeans, mbhCovariances, mbhPriors);

    % Train the GMM for HMG
    HMG_2D = reshape(HMG, [], size(HMG, 4))';
    [hmgMeans, hmgCovariances, hmgPriors] = vl_gmm(HMG_2D, K);

    % Compute the Fisher vector for HMG
    hmgFisherVector = vl_fisher(HMG_2D, hmgMeans, hmgCovariances, hmgPriors);

    % Save the GMM parameters to disk
    save('gmm_hog.mat', 'hogMeans', 'hogCovariances', 'hogPriors');
    save('gmm_hof.mat', 'hofMeans', 'hofCovariances', 'hofPriors');
    save('gmm_mbh.mat', 'mbhMeans', 'mbhCovariances', 'mbhPriors');
    save('gmm_hmg.mat', 'hmgMeans', 'hmgCovariances', 'hmgPriors');

    % Save the encoded features to a file
    save('hog_fisher_vector.mat', 'hogFisherVector');
    save('hof_fisher_vector.mat', 'hofFisherVector');
    save('mbh_fisher_vector.mat', 'mbhFisherVector');
    save('hmg_fisher_vector.mat', 'hmgFisherVector');

    fprintf('HOG Fisher vector dimensions: %dx%d\n', size(hogFisherVector, 1), size(hogFisherVector, 2));
    fprintf('HOF Fisher vector dimensions: %dx%d\n', size(hofFisherVector, 1), size(hofFisherVector, 2));
    fprintf('MBH Fisher vector dimensions: %dx%d\n', size(mbhFisherVector, 1), size(mbhFisherVector, 2));
    fprintf('HMG Fisher vector dimensions: %dx%d\n', size(hmgFisherVector, 1), size(hmgFisherVector, 2));
    
    fprintf('Fisher vector encoding done!\n');
end

function [hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector] = fisherVectorEncoder(vlfeatPath, hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo)
    % Add VLFeat library to the MATLAB path
    run(fullfile(vlfeatPath, 'toolbox/vl_setup'));
    
    % Set the desired size for the descriptors
    desiredSize = size(hogDesc{1});

    % Resize the HOG descriptors to the desired size
    resizedHOGDesc = resizeDescriptors(hogDesc, desiredSize);
    
    % Resize the HOF descriptors to the desired size
    resizedHOFDesc = resizeDescriptors(hofDesc, desiredSize);
    
    % Resize the MBHRow descriptors to the desired size
    resizedMBHRowDesc = resizeDescriptors(MBHRowDesc, desiredSize);
    
    % Resize the MBHCol descriptors to the desired size
    resizedMBHColDesc = resizeDescriptors(MBHColDesc, desiredSize);
    
    % Resize the HMG descriptors to the desired size
    resizedHMGDesc = resizeDescriptors(hmgDesc, desiredSize);

    % Load the resized descriptors from disk
    HOG = single(cat(4, resizedHOGDesc{:}));
    HOF = single(cat(4, resizedHOFDesc{:}));
    MBHRow = single(cat(4, resizedMBHRowDesc{:}));
    MBHCol = single(cat(4, resizedMBHColDesc{:}));
    HMG = single(cat(4, resizedHMGDesc{:}));

    % Set the number of clusters
    K = 256;

    % Train the GMM for HOG
    HOG_2D = reshape(HOG, [], size(HOG, 4))';
    [hogMeans, hogCovariances, hogPriors] = vl_gmm(HOG_2D, K);

    % Compute the Fisher vector for HOG
    hogFisherVector = vl_fisher(HOG_2D, hogMeans, hogCovariances, hogPriors);

    % Train the GMM for HOF
    HOF_2D = reshape(HOF, [], size(HOF, 4))';
    [hofMeans, hofCovariances, hofPriors] = vl_gmm(HOF_2D, K);

    % Compute the Fisher vector for HOF
    hofFisherVector = vl_fisher(HOF_2D, hofMeans, hofCovariances, hofPriors);

    % Train the GMM for MBHRow
    MBHRow_2D = reshape(MBHRow, [], size(MBHRow, 4))';
    [mbhRowMeans, mbhRowCovariances, mbhRowPriors] = vl_gmm(MBHRow_2D, K);

    % Compute the Fisher vector for MBHRow
    mbhRowFisherVector = vl_fisher(MBHRow_2D, mbhRowMeans, mbhRowCovariances, mbhRowPriors);
    
    % Train the GMM for MBHCol
    MBHCol_2D = reshape(MBHCol, [], size(MBHCol, 4))';
    [mbhColMeans, mbhColCovariances, mbhColPriors] = vl_gmm(MBHCol_2D, K);

    % Compute the Fisher vector for MBHCol
    mbhColFisherVector = vl_fisher(MBHCol_2D, mbhColMeans, mbhColCovariances, mbhColPriors);
    
    % Train the GMM for HMG
    HMG_2D = reshape(HMG, [], size(HMG, 4))';
    [hmgMeans, hmgCovariances, hmgPriors] = vl_gmm(HMG_2D, K);

    % Compute the Fisher vector for HMG
    hmgFisherVector = vl_fisher(HMG_2D, hmgMeans, hmgCovariances, hmgPriors);

    % Save the GMM parameters to disk
    save('gmm_hog.mat', 'hogMeans', 'hogCovariances', 'hogPriors');
    save('gmm_hof.mat', 'hofMeans', 'hofCovariances', 'hofPriors');
    save('gmm_mbh.mat', 'mbhRowMeans', 'mbhRowCovariances', 'mbhRowPriors', 'mbhColMeans', 'mbhColCovariances', 'mbhColPriors');
    save('gmm_hmg.mat', 'hmgMeans', 'hmgCovariances', 'hmgPriors');

    % Save the encoded features to a file
    save('hog_fisher_vector.mat', 'hogFisherVector');
    save('hof_fisher_vector.mat', 'hofFisherVector');
    save('mbh_row_fisher_vector.mat', 'mbhRowFisherVector');
    save('mbh_col_fisher_vector.mat', 'mbhColFisherVector');
    save('hmg_fisher_vector.mat', 'hmgFisherVector');

    % Print the dimensions of each Fisher vector
    fprintf('HOG Fisher vector dimensions: %dx%d\n', size(hogFisherVector, 1), size(hogFisherVector, 2));
    fprintf('HOF Fisher vector dimensions: %dx%d\n', size(hofFisherVector, 1), size(hofFisherVector, 2));
    fprintf('MBH Row Fisher vector dimensions: %dx%d\n', size(mbhRowFisherVector, 1), size(mbhRowFisherVector, 2));
    fprintf('MBH Col Fisher vector dimensions: %dx%d\n', size(mbhColFisherVector, 1), size(mbhColFisherVector, 2));
    fprintf('HMG Fisher vector dimensions: %dx%d\n', size(hmgFisherVector, 1), size(hmgFisherVector, 2));
    
    fprintf('Fisher vector encoding done!\n');
end

function [hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector] = encodeFisherVectors(vlfeatPath, hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo)

    % Add VLFeat library to the MATLAB path
    run(fullfile(vlfeatPath, 'toolbox/vl_setup'));
    
    % Perform Fisher Vector encoding for all descriptors
    fprintf('\nPerforming Fisher Vector encoding for all descriptors...\n');

    % After the HOG descriptor extraction loop
    save('HOG_descriptors.mat', 'hogDesc', 'hogInfo');

    % After the HOF descriptor extraction loop
    save('HOF_descriptors.mat', 'hofDesc', 'hofInfo');

    % After the MBH descriptor extraction loop
    save('MBH_descriptors.mat', 'MBHRowDesc', 'MBHColDesc', 'mbhInfo');

    % After the HMG descriptor extraction loop
    save('HMG_descriptors.mat', 'hmgDesc', 'hmgInfo');

    disp(size(hogDesc{1})); % Display the size of the first element in hogDesc
    disp(size(hofDesc{1})); % Display the size of the first element in hofDesc
    disp(size(MBHRowDesc{1})); % Display the size of the first element in hogDesc
    disp(size(MBHColDesc{1})); % Display the size of the first element in hofDesc
    disp(size(hmgDesc{1})); % Display the size of the first element in hogDesc

    for i = 1:numel(hogDesc)
        disp(size(hogDesc{i}));
    end

    for i = 1:numel(hofDesc)
        disp(size(hofDesc{i}));
    end

    for i = 1:numel(MBHRowDesc)
        disp(size(MBHRowDesc{i}));
    end

    for i = 1:numel(MBHColDesc)
        disp(size(MBHColDesc{i}));
    end

   % Set the desired size for the descriptors
    desiredSize = size(hogDesc{1});

    % Resize the HOG descriptors to the desired size
    resizedHOGDesc = resizeDescriptors(hogDesc, desiredSize);
    save('HOG_descriptors_resized.mat', 'resizedHOGDesc', 'hogInfo');
    disp(size(resizedHOGDesc{1}));

    % Resize the HOF descriptors to the desired size
    resizedHOFDesc = resizeDescriptors(hofDesc, desiredSize);
    save('HOF_descriptors_resized.mat', 'resizedHOFDesc', 'hofInfo');
    disp(size(resizedHOFDesc{1}));

    % Resize the MBHRow descriptors to the desired size
    resizedMBHRowDesc = resizeDescriptors(MBHRowDesc, desiredSize);
    save('MBHRow_descriptors_resized.mat', 'resizedMBHRowDesc', 'mbhInfo');
    disp(size(resizedMBHRowDesc{1}));

    % Resize the MBHCol descriptors to the desired size
    resizedMBHColDesc = resizeDescriptors(MBHColDesc, desiredSize);
    save('MBHCol_descriptors_resized.mat', 'resizedMBHColDesc', 'mbhInfo');
    disp(size(resizedMBHColDesc{1}));

    % Resize the HMG descriptors to the desired size
    resizedHMGDesc = resizeDescriptors(hmgDesc, desiredSize);
    save('HMG_descriptors_resized.mat', 'resizedHMGDesc', 'hmgInfo');
    disp(size(resizedHMGDesc{1}));

    % Load the resized descriptors from disk
    load('HOG_descriptors_resized.mat');
    HOG = single(cat(4, resizedHOGDesc{:}));

    % Set the number of clusters
    K = 1024;

    % Train the GMM for HOG
    HOG_2D = reshape(HOG, [], size(HOG, 4))';
    [means, covariances, priors] = vl_gmm(HOG_2D, K);

    % Save the GMM parameters to disk
    save('HOG_gmm.mat', 'means', 'covariances', 'priors');

    % Compute the Fisher vector for HOG
    hogFisherVector = vl_fisher(HOG_2D,means, covariances, priors);

    % Save the encoded features to a file
    save('hog_fisher_vector.mat', 'hogFisherVector');
    
    % Print a message
    fprintf('\nHOG Fisher vector encoding done!\n');

    % Load the resized descriptors from disk
    load('HOF_descriptors_resized.mat');
    HOF = single(cat(4, resizedHOFDesc{:}));

    % Train the GMM for HOF
    HOF_2D = reshape(HOF, [], size(HOF, 4))';
    [means, covariances, priors] = vl_gmm(HOF_2D, K);

    % Save the GMM parameters to disk
    save('HOF_gmm.mat', 'means', 'covariances', 'priors');

    % Compute the Fisher vector for HOF
    hofFisherVector = vl_fisher(HOF_2D, means, covariances, priors);

    % Save the encoded features to a file
    save('hof_fisher_vector.mat', 'hofFisherVector');

    % Print a message
    fprintf('HOF Fisher vector encoding done!\n');

    % Load the resized descriptors from disk
    load('MBHRow_descriptors_resized.mat');
    load('MBHCol_descriptors_resized.mat');
    MBHRow = single(cat(4, resizedMBHRowDesc{:}));
    MBHCol = single(cat(4, resizedMBHColDesc{:}));

    % Train the GMM for MBHRow
    MBHRow_2D = reshape(MBHRow, [], size(MBHRow, 4))';
    [means, covariances, priors] = vl_gmm(MBHRow_2D, K);

    % Save the GMM parameters to disk
    save('MBHRow_gmm.mat', 'means', 'covariances', 'priors');

    % Compute the Fisher vector for MBHRow
    mbhRowFisherVector = vl_fisher(MBHRow_2D, means, covariances, priors);

    % Save the encoded features to a file
    save('mbhRow_fisher_vector.mat', 'mbhRowFisherVector');

    % Train the GMM for MBHCol
    MBHCol_2D = reshape(MBHCol, [], size(MBHCol, 4))';
    [means, covariances, priors] = vl_gmm(MBHCol_2D, K);

    % Save the GMM parameters to disk
    save('MBHCol_gmm.mat', 'means', 'covariances', 'priors');

    % Compute the Fisher vector for MBHCol
    mbhColFisherVector = vl_fisher(MBHCol_2D, means, covariances, priors);

    % Save the encoded features to a file
    save('mbhCol_fisher_vector.mat', 'mbhColFisherVector');

    % Print a message
    fprintf('MBH Fisher vector encoding done!\n');

    % Load the resized descriptors from disk
    load('HMG_descriptors_resized.mat');
    HMG = single(cat(4, resizedHMGDesc{:}));

    % Train the GMM for HMG
    HMG_2D = reshape(HMG, [], size(HMG, 4))';
    [means, covariances, priors] = vl_gmm(HMG_2D, K);

    % Save the GMM parameters to disk
    save('HMG_gmm.mat', 'means', 'covariances', 'priors');

    % Compute the Fisher vector for HMG
    hmgFisherVector = vl_fisher(HMG_2D, means, covariances, priors);

    % Save the encoded features to a file
    save('hmg_fisher_vector.mat', 'hmgFisherVector');

    % Print a message
    fprintf('HMG Fisher vector encoding done!\n');

    % Print a message
    fprintf('Fisher vector encoding done!\n');
end

function resizedDesc = resizeDescriptors(desc, desiredSize)
    resizedDesc = cell(size(desc));
    for i = 1:numel(desc)
        resizedDesc{i} = imresize(desc{i}, desiredSize);
    end
end

function fisherVectorEncoding(vlfeatPath, hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo)

    % Add VLFeat library to the MATLAB path
    run(fullfile(vlfeatPath, 'toolbox/vl_setup'));

    % Perform Fisher Vector encoding for all descriptors
    fprintf('\nPerforming Fisher Vector encoding for all descriptors...\n');

    K = 3;

    % HOG Descriptor Encoding
    HOG = cat(4, hogDesc{:});
    HOG = reshape(HOG, [], size(HOG, 4))';
    [means, covariances, priors] = vl_gmm(single(HOG), K);
    hogFisherVector = vl_fisher(single(HOG), means, covariances, priors);
    save('hog_fisher_vector.mat', 'hogFisherVector');

    % HOF Descriptor Encoding
    HOF = cat(4, hofDesc{:});
    HOF = reshape(HOF, [], size(HOF, 4))';
    [means, covariances, priors] = vl_gmm(single(HOF), K);
    hofFisherVector = vl_fisher(single(HOF), means, covariances, priors);
    save('hof_fisher_vector.mat', 'hofFisherVector');

    % MBH Descriptor Encoding
    MBHRow = cat(4, MBHRowDesc{:});
    MBHRow = reshape(MBHRow, [], size(MBHRow, 4))';
    [means, covariances, priors] = vl_gmm(single(MBHRow), K);
    mbhxFisherVector = vl_fisher(single(MBHRow), means, covariances, priors);
    save('mbhx_fisher_vector.mat', 'mbhxFisherVector');

    MBHCol = cat(4, MBHColDesc{:});
    MBHCol = reshape(MBHCol, [], size(MBHCol, 4))';
    [means, covariances, priors] = vl_gmm(single(MBHCol), K);
    mbhyFisherVector = vl_fisher(single(MBHCol), means, covariances, priors);
    save('mbhy_fisher_vector.mat', 'mbhyFisherVector');

    % HMG Descriptor Encoding
    HMG = cat(4, hmgDesc{:});
    HMG = reshape(HMG, [], size(HMG, 4))';
    [means, covariances, priors] = vl_gmm(single(HMG), K);
    hmgFisherVector = vl_fisher(single(HMG), means, covariances, priors);
    save('hmg_fisher_vector.mat', 'hmgFisherVector');

    fprintf('\nFisher vector encoding done!\n');
end

function concatenated_vectors = concatenateFisherVectors(hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector)
    
% Concatenate the Fisher vectors
    concatenated_vectors = [hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector];

     % Save the concatenated vectors
    save('concatenated_vectors.mat', 'concatenated_vectors');

    % Display the cncatenated vectors
    fprintf('\nConcatenated Fisher Vectors:\n');
    disp(concatenated_vectors);
end

function concatenated_vectors = concatenateVectors(hogFisherVector, hofFisherVector, mbhFisherVector, hmgFisherVector)
    
% Concatenate the Fisher vectors
    concatenated_vectors = [hogFisherVector, hofFisherVector, mbhFisherVector, hmgFisherVector];

     % Save the concatenated vectors
    save('concatenated_vectors.mat', 'concatenated_vectors');

    % Display the cncatenated vectors
    fprintf('\nConcatenated Fisher Vectors:\n');
    disp(concatenated_vectors);
end

function normalized_vectors = normalizeVectors(concatenated_vectors)
    
    % Perform L2 normalization on the concatenated vectors
    normalized_vectors = normalize(concatenated_vectors, 'norm', 'l2');

    % Save the normalized vectors
    save('normalized_vectors.mat', 'normalized_vectors');

    % Display the normalized vectors
    fprintf('\nNormalized Vectors:\n');
    disp(normalized_vectors);
end

function saveConcatWithLabels(matrix, value, seq)
    filename = 'concat_with_labels.mat';

    disp([matrix, repmat(value, size(matrix, 1), 1), repmat(seq, size(matrix, 1), 1)]);

    % Check if the file exists
    if exist(filename, 'file') == 2
        % Load the existing matrix
        existingMatrix = load(filename);
        existingMatrix = existingMatrix.result;

        % Append the new values to the existing matrix
        result = [existingMatrix; matrix, repmat(value, size(matrix, 1), 1), repmat(seq, size(matrix, 1), 1)];
    else
        % Create a new matrix with the provided values
        result = [matrix, repmat(value, size(matrix, 1), 1), repmat(seq, size(matrix, 1), 1)];
    end

    % Save the resulting matrix in a MATLAB file
    save(filename, 'result');
end

function [pca_coefficients, pca_scores, pca_variances] = principalComponentAnalyzer(concatenated_vectors)

    % Perform PCA on the concatenated vectors
    [pca_coefficients, pca_scores, pca_variances] = pca(concatenated_vectors);

    % Print the PCA results
    disp('PCA Coefficients:');
    disp(pca_coefficients);
    
    disp('PCA Scores:');
    disp(pca_scores);
    
    disp('PCA Variances:');
    disp(pca_variances);

    % Save PCA results to a file
%     pca_results = struct('coefficients', pca_coefficients, 'scores', pca_scores, 'variances', pca_variances);
%     save('fisher_concat_pca.mat', 'pca_results');

% Save PCA scores to a file
    save('pca_scores.mat', 'pca_scores');
end

function [pcaCoefficients, pcaScores, pcaVariances] = dimensionalityReductionPCA(concatenatedVectors, desiredVariance)
    % Perform PCA
    [coefficients, scores, variances] = pca(concatenatedVectors);

    % Calculate the cumulative explained variance ratio
    explainedVarianceRatio = cumsum(variances) / sum(variances);

    % Find the index where the explained variance exceeds the desired variance
    numComponents = find(explainedVarianceRatio >= desiredVariance, 1, 'first');

    % Retain only the desired number of components
    pcaCoefficients = coefficients(:, 1:numComponents);
    pcaScores = scores(:, 1:numComponents);
    pcaVariances = variances(1:numComponents);

    % Print the PCA results
    disp('PCA Coefficients:');
    disp(pcaCoefficients);
    
    disp('PCA Scores:');
    disp(pcaScores);
    
    disp('PCA Variances:');
    disp(pcaVariances);

    % Save PCA results to a file
    pca_results = struct('coefficients', pcaCoefficients, 'scores', pcaScores, 'variances', pcaVariances);
    save('fisher_concat_pca_dr.mat', 'pca_results');

end

function pcaScores = doPCA(concatenatedVectors, desiredVariance)

    rng(42);  % Set the random seed to a fixed value (e.g., 42)
    maxIterations = 100000;

    % Set the 'MaxIter' option to increase the number of iterations
    options = struct('MaxIter', maxIterations);

    % Perform PCA
    [~, scores, ~] = pca(concatenatedVectors, 'Options', options);

    % Calculate the cumulative explained variance ratio
    variances = var(scores);
    explainedVarianceRatio = cumsum(variances) / sum(variances);

    % Find the index where the explained variance exceeds the desired variance
    numComponents = find(explainedVarianceRatio >= desiredVariance, 1, 'first');

    % Retain only the desired number of components
    pcaScores = scores(:, 1:numComponents);

    % Save PCA scores to a file
    save('pca_scores.mat', 'pcaScores');
end

function pcaScores = undergoPCA(concatenatedVectors, desiredVariance)

    rng(42);  % Set the random seed to a fixed value (e.g., 42)

    % Perform PCA
    [~, scores, variances] = pca(concatenatedVectors);

    % Calculate the cumulative explained variance ratio
    explainedVarianceRatio = cumsum(variances) / sum(variances);

    % Find the index where the explained variance exceeds the desired variance
    numComponents = find(explainedVarianceRatio >= desiredVariance, 1, 'first');

    % Display intermediate results
    disp('PCA Results:');
    disp('-----------------');
    disp('Explained Variance Ratio:');
    disp(explainedVarianceRatio);
    disp('-----------------');
    disp('Variance Explained by Each Component:');
    disp(variances);
    disp('-----------------');
    disp('Number of Components to Retain:');
    disp(numComponents);
    disp('-----------------');

    % Retain only the desired number of components
    pcaScores = scores(:, 1:numComponents);

    % Save PCA scores to a file
    save('pca_scores.mat', 'pcaScores');
end

function pcaScores = allVidsPCA()

    % Load the data from the mat file
    data = load('concat_with_labels.mat');
    
    % Extract the necessary columns for PCA
    pcaData = data.result(:, 1:end-2);

    % Perform PCA
    desiredVariance = 0.96;
    pcaScores = undergoPCA(pcaData, desiredVariance);

    % Append the last two columns to the PCA scores
    pcaScores = [pcaScores, data.result(:, end-1:end)];

    % Save the PCA scores to a file
    save('allvids_pca_scores.mat', 'pcaScores');

    disp(pcaScores);
end

function [pcaCoefficients, pcaScoresReduced, pcaVariances] = ApplyPCA(concatenatedVectors, desiredVariance)

    % Perform PCA
    [coefficients, scores, variances] = pca(concatenatedVectors);

    % Calculate the cumulative explained variance ratio
    explainedVarianceRatio = cumsum(variances) / sum(variances);

    % Find the index where the explained variance exceeds the desired variance
    numComponents = find(explainedVarianceRatio >= desiredVariance, 1, 'first');

    % Retain only the desired number of components
    pcaCoefficients = coefficients(:, 1:numComponents);
    pcaScoresReduced = scores(:, 1:numComponents) * pcaCoefficients'; % Reduce to 24x1
    pcaVariances = variances(1:numComponents);

    % Save PCA scores to a file
    save('pca_scores_reduced.mat', 'pcaScoresReduced');
end

function concatenated_vectors = concatenateFisherVectorsFromFiles()
    % Load the Fisher vectors
    hog_fisher_vector = load('hog_fisher_vector.mat');
    hof_fisher_vector = load('hof_fisher_vector.mat');
    mbhRow_fisher_vector = load('mbhRow_fisher_vector.mat');
    mbhCol_fisher_vector = load('mbhCol_fisher_vector.mat');
    hmg_fisher_vector = load('hmg_fisher_vector.mat');

    % Access the actual Fisher vector data
    hog_fisher_vector = hog_fisher_vector.hog_fisher_vector;
    hof_fisher_vector = hof_fisher_vector.hof_fisher_vector;
    mbhRow_fisher_vector = mbhRow_fisher_vector.mbhRow_fisher_vector;
    mbhCol_fisher_vector = mbhCol_fisher_vector.mbhCol_fisher_vector;
    hmg_fisher_vector = hmg_fisher_vector.hmg_fisher_vector;

    % Concatenate the Fisher vectors
    concatenated_vectors = [hog_fisher_vector, hof_fisher_vector, mbhRow_fisher_vector, mbhCol_fisher_vector, hmg_fisher_vector];
 
end

function [hogDescriptorPCA, hofDescriptorPCA, mbhxDescriptorPCA, mbhyDescriptorPCA, hmgDescriptorPCA] = performPCA()

    % Load the Fisher-encoded descriptors from disk
    load('hog_fisher_vector.mat');
    load('hof_fisher_vector.mat');
    load('mbhx_fisher_vector.mat');
    load('mbhy_fisher_vector.mat');
    load('hmg_fisher_vector.mat');
    
    % Apply PCA to each Fisher-encoded descriptor separately
    
    % HOG
    hogDescriptor = hogFisherVector;
    
    % Reshape the descriptor data to have each descriptor as a column
    [numSamples, numFeatures] = size(hogDescriptor);
    hogDescriptorReshaped = reshape(hogDescriptor, numSamples, numFeatures);
    
    % Apply PCA to the HOG descriptor
    [coeffHOG, scoreHOG, ~, ~, explainedHOG] = pca(hogDescriptorReshaped);
    
    % Keep a certain number of principal components (e.g., keep 90% of the variance)
    numPCHOG = find(cumsum(explainedHOG) >= 90, 1);
    
    % Apply Dimensionality Reduction to the HOG descriptor
    hogDescriptorPCA = scoreHOG(:, 1:numPCHOG);
    
    fprintf('\nHOG PCA done!\n');
    
    % HOF
    hofDescriptor = hofFisherVector;
    
    % Reshape the descriptor data to have each descriptor as a column
    [numSamples, numFeatures] = size(hofDescriptor);
    hofDescriptorReshaped = reshape(hofDescriptor, numSamples, numFeatures);
    
    % Apply PCA to the HOF descriptor
    [coeffHOF, scoreHOF, ~, ~, explainedHOF] = pca(hofDescriptorReshaped);
    
    % Keep a certain number of principal components (e.g., keep 90% of the variance)
    numPCHOF = find(cumsum(explainedHOF) >= 90, 1);
    
    % Apply Dimensionality Reduction to the HOF descriptor
    hofDescriptorPCA = scoreHOF(:, 1:numPCHOF);
    
    fprintf('\nHOF PCA done!\n');
    
    % MBHx
    mbhxDescriptor = mbhxFisherVector;
    
    % Reshape the descriptor data to have each descriptor as a column
    [numSamples, numFeatures] = size(mbhxDescriptor);
    mbhxDescriptorReshaped = reshape(mbhxDescriptor, numSamples, numFeatures);
    
    % Apply PCA to the MBHx descriptor
    [coeffMBHx, scoreMBHx, ~, ~, explainedMBHx] = pca(mbhxDescriptorReshaped);
    
    % Keep a certain number of principal components (e.g., keep 90% of the variance)
    numPCMBHx = find(cumsum(explainedMBHx) >= 90, 1);
    
    % Apply Dimensionality Reduction to the MBHx descriptor
    mbhxDescriptorPCA = scoreMBHx(:, 1:numPCMBHx);
    
    fprintf('\nMBHx PCA done!\n');
    
    % MBHy
    mbhyDescriptor = mbhyFisherVector;
    
    % Reshape the descriptor data to have each descriptor as a column
    [numSamples, numFeatures] = size(mbhyDescriptor);
    mbhyDescriptorReshaped = reshape(mbhyDescriptor, numSamples, numFeatures);
    
    % Apply PCA to the MBHy descriptor
    [coeffMBHy, scoreMBHy, ~, ~, explainedMBHy] = pca(mbhyDescriptorReshaped);
    
    % Keep a certain number of principal components (e.g., keep 90% of the variance)
    numPCMBHy = find(cumsum(explainedMBHy) >= 90, 1);
    
    % Apply Dimensionality Reduction to the MBHy descriptor
    mbhyDescriptorPCA = scoreMBHy(:, 1:numPCMBHy);
    
    fprintf('\nMBHy PCA done!\n');
    
    % HMG
    hmgDescriptor = hmgFisherVector;
    
    % Reshape the descriptor data to have each descriptor as a column
    [numSamples, numFeatures] = size(hmgDescriptor);
    hmgDescriptorReshaped = reshape(hmgDescriptor, numSamples, numFeatures);
    
    % Apply PCA to the HMG descriptor
    [coeffHMG, scoreHMG, ~, ~, explainedHMG] = pca(hmgDescriptorReshaped);
    
    % Keep a certain number of principal components (e.g., keep 90% of the variance)
    numPCHMG = find(cumsum(explainedHMG) >= 90, 1);
    
    % Apply Dimensionality Reduction to the HMG descriptor
    hmgDescriptorPCA = scoreHMG(:, 1:numPCHMG);
    
    fprintf('\nHMG PCA done!\n');
    
    % Save the PCA results to a file
    save('pca_results.mat', 'hogDescriptorPCA', 'hofDescriptorPCA', 'mbhxDescriptorPCA', 'mbhyDescriptorPCA', 'hmgDescriptorPCA');
    
    fprintf('\nPCA done!\n');
end

function [concatenatedDescriptors] = concatenateDescriptors(hogDescriptorPCA, hofDescriptorPCA, mbhxDescriptorPCA, mbhyDescriptorPCA, hmgDescriptorPCA)

    % Concatenate the PCAed descriptors
    concatenatedDescriptors = horzcat(hogDescriptorPCA, hofDescriptorPCA, mbhxDescriptorPCA, mbhyDescriptorPCA, hmgDescriptorPCA);

    % Save the concatenated descriptor to a file
    save('concatenated_descriptor.mat', 'concatenatedDescriptors');

    fprintf('\nConcatenation done!\n');

end

function storeDescriptors(concatenatedDescriptors, videoPath)

    [~, videoName, ~] = fileparts(videoPath);

    % Open the file in append mode
    fileID = fopen('concatenated_data.txt', 'a');

    % Write the concatenated descriptors and video name to the file
    fprintf(fileID, '%s\n', videoName);
    fprintf(fileID, '%f %f %f %f %f\n', concatenatedDescriptors');

    % Close the file
    fclose(fileID);
end

function encoded_labels = performLabelEncoding(subjectNames)
    % Unique subject names
    unique_names = unique(subjectNames);
    
    % Create a mapping between subject names and integer labels
    label_map = containers.Map(unique_names, 1:numel(unique_names));
    
    % Perform label encoding
    encoded_labels = cellfun(@(x) label_map(x), subjectNames);
    
    fprintf('\nEncoded Labels:\n');
    disp(encoded_labels);
end

function storePCAData(pcaScores, encodedLabel)
    pcaData = struct('pcaScores', pcaScores, 'encodedLabel', encodedLabel);
    
    % Check if the file already exists
    if exist('pca_labels.mat', 'file') == 2
        % Load existing data
        load('pca_labels.mat', 'pcaData');
        
        % Append new data
        pcaData = [pcaData; pcaData];
    end
    
    % Save the updated data
    save('pca_labels.mat', 'pcaData');
end

function createPCAWithLabels(matrix, encodedLabel)
    % Repeat the encodedLabel to create the second column
    col2 = repmat(encodedLabel, size(matrix, 1), 1);

    % Combine the matrix and the repeated encodedLabel column
    result = [matrix, col2];

    % Save the resulting matrix in a MATLAB file
    save('pca_with_labels.mat', 'result');
end

function savePCAWithLabels(matrix, value, seq)
    filename = 'pca_with_labels.mat';

    disp([matrix, repmat(value, size(matrix, 1), 1), repmat(seq, size(matrix, 1), 1)]);

    % Check if the file exists
    if exist(filename, 'file') == 2
        % Load the existing matrix
        existingMatrix = load(filename);
        existingMatrix = existingMatrix.result;

        % Append the new values to the existing matrix
        result = [existingMatrix; matrix, repmat(value, size(matrix, 1), 1), repmat(seq, size(matrix, 1), 1)];
    else
        % Create a new matrix with the provided values
        result = [matrix, repmat(value, size(matrix, 1), 1), repmat(seq, size(matrix, 1), 1)];
    end

    % Save the resulting matrix in a MATLAB file
    save(filename, 'result');
end

function runSVM()
    % Load the PCA scores and labels from the mat file
    data = load('allvids_pca_scores.mat');
    pcaScores = data.pcaScores;
    
    % Separate the last column (testing/training indicator) and second last column (labels)
    testingIndicator = pcaScores(:, end);
    labels = pcaScores(:, end-1);
    
    % Find the indices for testing and training data
    testingIndices = (testingIndicator == 4);
    
    % Separate training and testing data
    trainingData = pcaScores(~testingIndices, 1:end-2);
    trainingLabels = labels(~testingIndices);
    testingData = pcaScores(testingIndices, 1:end-2);
    testingLabels = labels(testingIndices);
    
    % Train the SVM classifier using fitcecoc
    model = fitcecoc(trainingData, trainingLabels);
    
    % Predict labels for testing data
    predictedLabels = predict(model, testingData);
    
    % Calculate the accuracy of the SVM classifier
    accuracy = sum(predictedLabels == testingLabels) / numel(testingLabels) * 100;
    
    % Display the accuracy of the SVM classifier
    disp('SVM Accuracy:');
    disp(accuracy);
end

function run_disp_SVM()
    % Load the PCA scores and labels from the mat file
    data = load('allvids_pca_scores.mat');
    pcaScores = data.pcaScores;
    
    % Separate the last column (testing/training indicator) and second last column (labels)
    testingIndicator = pcaScores(:, end);
    labels = pcaScores(:, end-1);
    
    % Find the indices for testing and training data
    testingIndices = (testingIndicator == 4);
    
    % Separate training and testing data
    trainingData = pcaScores(~testingIndices, 1:end-2);
    trainingLabels = labels(~testingIndices);
    testingData = pcaScores(testingIndices, 1:end-2);
    testingLabels = labels(testingIndices);
    
    % Train the SVM classifier using fitcecoc
    model = fitcecoc(trainingData, trainingLabels);
    
    % Predict labels for testing data
    predictedLabels = predict(model, testingData);
    
    % Calculate the accuracy of the SVM classifier
    accuracy = sum(predictedLabels == testingLabels) / numel(testingLabels) * 100;
    
    % Display the accuracy of the SVM classifier
    disp('SVM Accuracy:');
    disp(accuracy);
    
    % Print the results for all subjects
    disp('Subject Results:');
    subjects = unique(testingLabels);
    numSubjects = numel(subjects);
    for i = 1:numSubjects
        subject = subjects(i);
        subjectIndices = (testingLabels == subject);
        subjectPredictions = predictedLabels(subjectIndices);
        subjectAccuracy = sum(subjectPredictions == subject) / numel(subjectPredictions) * 100;
        disp(['Subject ' num2str(subject) ':']);
        disp(['Accuracy: ' num2str(subjectAccuracy)]);
        disp(['Predictions: ' mat2str(subjectPredictions)]);
    end
end

function run_SVM_without_19()
    % Load the PCA scores and labels from the mat file
    data = load('allvids_pca_scores.mat');
    pcaScores = data.pcaScores;
    
    % Separate the last column (testing/training indicator) and second last column (labels)
    testingIndicator = pcaScores(:, end);
    labels = pcaScores(:, end-1);
    
    % Find the indices for testing and training data
    testingIndices = (testingIndicator == 4) & (labels ~= 17); % Exclude subject number 19
    trainingIndices = ~testingIndices;
    
    % Separate training and testing data
    trainingData = pcaScores(trainingIndices, 1:end-2);
    trainingLabels = labels(trainingIndices);
    testingData = pcaScores(testingIndices, 1:end-2);
    testingLabels = labels(testingIndices);
    
    % Train the SVM classifier using fitcecoc
    model = fitcecoc(trainingData, trainingLabels);
    
    % Predict labels for testing data
    predictedLabels = predict(model, testingData);
    
    % Calculate the accuracy of the SVM classifier
    accuracy = sum(predictedLabels == testingLabels) / numel(testingLabels) * 100;
    
    % Display the accuracy of the SVM classifier
    disp('SVM Accuracy:');
    disp(accuracy);
    
    % Print the results for all subjects
    disp('Subject Results:');
    subjects = unique(testingLabels);
    numSubjects = numel(subjects);
    for i = 1:numSubjects
        subject = subjects(i);
        subjectIndices = (testingLabels == subject);
        subjectPredictions = predictedLabels(subjectIndices);
        subjectAccuracy = sum(subjectPredictions == subject) / numel(subjectPredictions) * 100;
        disp(['Subject ' num2str(subject) ':']);
        disp(['Accuracy: ' num2str(subjectAccuracy)]);
        disp(['Predictions: ' mat2str(subjectPredictions)]);
    end
end

function runSVM2()
    % Load the PCA scores and labels from the mat file
    data = load('allvids_pca_scores.mat');
    pcaScores = data.pcaScores;
    
    % Separate the last column (testing/training indicator) and second last column (labels)
    testingIndicator = pcaScores(:, end);
    labels = pcaScores(:, end-1);
    
    % Find the indices for testing and training data
    testingIndices = (testingIndicator == 4);
    
    % Separate training and testing data
    trainingData = pcaScores(~testingIndices, 1:end-2);
    trainingLabels = labels(~testingIndices);
    testingData = pcaScores(testingIndices, 1:end-2);
    testingLabels = labels(testingIndices);
    
    % Train the SVM classifier
    model = fitcecoc(trainingData, trainingLabels, 'Learners', templateSVM('Standardize', true));
    
    % Predict labels for testing data
    predictedLabels = predict(model, testingData);
    
    % Compare predicted labels with actual labels
    accuracy = sum(predictedLabels == testingLabels) / numel(testingLabels);
    
    % Display the accuracy of the SVM classifier
    disp('SVM Accuracy:');
    disp(accuracy);
    
    % Print the results for each subject
    subjectIDs = unique(testingLabels);
    disp('Results for each subject:');
    disp('------------------------');
    for i = 1:numel(subjectIDs)
        subjectID = subjectIDs(i);
        subjectIndices = (testingLabels == subjectID);
        subjectAccuracy = sum(predictedLabels(subjectIndices) == testingLabels(subjectIndices)) / sum(subjectIndices);
        disp(['Subject ' num2str(subjectID) ': Accuracy = ' num2str(subjectAccuracy)]);
    end
end

function runSVMHyperParametericTuning()
    % Load the PCA scores and labels from the mat file
    data = load('allvids_pca_scores.mat');
    pcaScores = data.pcaScores;
    
    % Separate the last column (testing/training indicator) and second last column (labels)
    testingIndicator = pcaScores(:, end);
    labels = pcaScores(:, end-1);
    
    % Find the indices for testing and training data
    testingIndices = (testingIndicator == 4);
    
    % Separate training and testing data
    trainingData = pcaScores(~testingIndices, 1:end-2);
    trainingLabels = labels(~testingIndices);
    testingData = pcaScores(testingIndices, 1:end-2);
    testingLabels = labels(testingIndices);
    
    % Define the range of hyperparameters to search
    CValues = [0.1, 1, 10];
    kernelValues = {'linear', 'rbf'};
    
    % Perform grid search
    bestAccuracy = 0;
    bestModel = [];
    for i = 1:numel(CValues)
        for j = 1:numel(kernelValues)
            % Train the SVM classifier with current hyperparameters
            model = fitcecoc(trainingData, trainingLabels, 'Learners', templateSVM('KernelFunction', kernelValues{j}, 'BoxConstraint', CValues(i)));
            
            % Predict labels for testing data
            predictedLabels = predict(model, testingData);
            
            % Calculate accuracy
            accuracy = sum(predictedLabels == testingLabels) / numel(testingLabels);
            
            % Check if current hyperparameters result in better accuracy
            if accuracy > bestAccuracy
                bestAccuracy = accuracy;
                bestModel = model;
            end
        end
    end
    
    % Display the best accuracy and hyperparameters
    disp('Best Accuracy:');
    disp(bestAccuracy);
    disp('Best Hyperparameters:');
    disp(bestModel);
end

function runSVMHyperparameterTuning()
    % Load the PCA scores and labels from the mat file
    data = load('allvids_pca_scores.mat');
    pcaScores = data.pcaScores;
    
    % Separate the last column (testing/training indicator) and second last column (labels)
    testingIndicator = pcaScores(:, end);
    labels = pcaScores(:, end-1);
    
    % Find the indices for testing and training data
    testingIndices = (testingIndicator == 4);
    
    % Separate training and testing data
    trainingData = pcaScores(~testingIndices, 1:end-2);
    trainingLabels = labels(~testingIndices);
    testingData = pcaScores(testingIndices, 1:end-2);
    testingLabels = labels(testingIndices);
    
    % Define the range of hyperparameters to tune
    CValues = [0.01, 0.1, 1, 10];
    kernelValues = {'linear', 'rbf', 'polynomial'};
    
    % Initialize variables to store best hyperparameters and accuracy
    bestAccuracy = 0;
    bestC = 0;
    bestKernel = '';
    
    % Hyperparameter tuning loop
    for i = 1:length(CValues)
        for j = 1:length(kernelValues)
            % Train the SVM classifier with current hyperparameters
            fprintf('Training SVM with C=%f, Kernel=%s\n', CValues(i), kernelValues{j});
            model = fitcsvm(trainingData, trainingLabels, 'KernelFunction', kernelValues{j}, 'BoxConstraint', CValues(i), 'Verbose', 1);
            
            % Predict labels for testing data
            predictedLabels = predict(model, testingData);
            
            % Compute accuracy
            accuracy = sum(predictedLabels == testingLabels) / numel(testingLabels);
            
            % Check if current hyperparameters give better accuracy
            if accuracy > bestAccuracy
                bestAccuracy = accuracy;
                bestC = CValues(i);
                bestKernel = kernelValues{j};
            end
            
            fprintf('Accuracy: %.2f%%\n\n', accuracy * 100);
        end
    end
    
    % Display the best hyperparameters and accuracy
    fprintf('Best Hyperparameters:\n');
    fprintf('C: %f\n', bestC);
    fprintf('Kernel: %s\n', bestKernel);
    fprintf('Best Accuracy: %.2f%%\n', bestAccuracy * 100);
end

function runCompleteCode(videoPath)

    % Load the video and get the read time
    [vid, videoReadTime] = loadVideo(videoPath); 

    % Extract features
    [hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo] = extractFeatures(vid, videoReadTime);

    % Set vlfeat path
    vlfeatPath = 'E:\bsef19m501\vlfeat-0.9.21-bin';

    % Perform FIsher Vector Encoding
    [hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector] = fisherVectorEncoder(vlfeatPath, hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo);

    % Concatenate after Fisher Vector Encoding
    concatenated_vectors = concatenateFisherVectors(hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector);

    %[pca_coefficients, pca_scores, pca_variances] = principalComponentAnalyzer(concatenated_vectors);
    % Assuming you have the concatenated_vectors matrix and desired variance value
    desiredVariance = 0.95;

    % Perform PCA with desired variance
    [pcaCoefficients, pcaScores, pcaVariances] = dimensionalityReductionPCA(concatenated_vectors, desiredVariance);

    subjectNames = {'fyc', 'hy', 'ljg', 'lqf', 'lsl', 'ml', 'nhz', 'rj', 'syj', 'wl', 'wq', 'wyc', 'xch', 'xxj', 'yjf', 'zc', 'zdx', 'zjg', 'zl', 'zyf'};
    encoded_labels = performLabelEncoding(subjectNames);

    % Perform PCA and return the results
    % [hogDescriptorPCA, hofDescriptorPCA, mbhxDescriptorPCA, mbhyDescriptorPCA, hmgDescriptorPCA] = performPCA();

    % Concatenate the PCAed Descriptors
    % [concatenatedDescriptors] = concatenateDescriptors(hogDescriptorPCA, hofDescriptorPCA, mbhxDescriptorPCA, mbhyDescriptorPCA, hmgDescriptorPCA);

    % disp(concatenatedDescriptors);

    %storeDescriptors(concatenatedDescriptors, videoPath);

end

function runFisherConcatPCA(videoPath, subjectName, sequenceName)
    % Load the video and get the read time
    [vid, videoReadTime] = loadVideo(videoPath);

    % Extract features
    [hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo] = extractFeatures(vid, videoReadTime);

    % Performing binning & normalization
    % [hogDescNorm, hofDescNorm, mbhxDescNorm, mbhyDescNorm, hmgDescNorm] = BinAndNormalize(hogDesc, hofDesc, MBHRowDesc, MBHColDesc, hmgDesc)
    
    % Set vlfeat path
    vlfeatPath = 'E:\bsef19m501\vlfeat-0.9.21-bin';

    subjectNames = {'fyc', 'hy', 'ljg', 'lqf', 'lsl', 'ml', 'nhz', 'rj', 'syj', 'wl', 'wq', 'wyc', 'xch', 'xxj', 'yjf', 'zc', 'zdx', 'zjg', 'zl', 'zyf'};

    % Perform label encoding
    encoded_labels = performLabelEncoding(subjectNames);

    % Find the encoded label for the given subject name
    encodedLabel = encoded_labels(strcmp(subjectNames, subjectName));

    fprintf('\nEncoded Label for Current Subject:\n');
    disp(encodedLabel);

    % Perform Fisher Vector Encoding
    [hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector] = fisherVectorEncoder(vlfeatPath, hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo);
    % [hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector] = fisherVectorEncoder(vlfeatPath, hogDescNorm, hogInfo, hofDescNorm, hofInfo, mbhxDescNorm, mbhyDescNorm, mbhInfo, hmgDescNorm, hmgInfo);

    % [hogFisherVector, hofFisherVector, mbhFisherVector, hmgFisherVector] = fisherVectorEncoder(vlfeatPath, hogDesc, hogInfo, hofDesc, hofInfo, MBHRowDesc, MBHColDesc, mbhInfo, hmgDesc, hmgInfo);


    % Concatenate after Fisher Vector Encoding
    concatenated_vectors = concatenateFisherVectors(hogFisherVector, hofFisherVector, mbhRowFisherVector, mbhColFisherVector, hmgFisherVector);

    % [normalized_vectors] = normalizeVectors(concatenated_vectors)
    
    % saveConcatWithLabels(normalized_vectors, encodedLabel, sequenceName);

    saveConcatWithLabels(concatenated_vectors, encodedLabel, sequenceName);

end

function runNewCode(videoPath,subjectName,sequenceIndex)

    [vid, videoReadTime] = loadVideo(videoPath);
    dense_points = extract_dense_points(video);
    tracked_points = track_points(video, dense_points);
    trajectories = compute_trajectories(tracked_points);
    normalized_trajectories = normalize_trajectories(trajectories);
    local_descriptors = compute_local_descriptors(video, normalized_trajectories);
    encoded_descriptors = encode_descriptors(local_descriptors);
    best_combination = evaluate_descriptor_combinations(local_descriptors);

end

function runCode()
    % Iterate over the subject folders
subjectNames = {'fyc', 'hy', 'ljg', 'lqf', 'lsl', 'ml', 'nhz', 'rj', 'syj', 'wl', 'wq', 'wyc', 'xch', 'xxj', 'yjf', 'zc', 'zdx', 'zjg', 'zl', 'zyf'};


% subjectNames = {'fyc', 'hy', 'ljg', 'lqf', 'lsl', 'ml', 'nhz', 'rj', 'syj', 'wl', 'wq', 'wyc', 'xch', 'xxj', 'yjf', 'zc', 'zdx', 'zjg'};

% subjectNames = {'fyc', 'hy', 'ljg', 'lqf'};

for subjectIndex = 1:numel(subjectNames)
    subjectName = subjectNames{subjectIndex};
    subjectFolder = fullfile(subjectName);
    fprintf('\nSubject Folder: %s\n', subjectFolder);
    
    % Iterate over the sequence folders for each subject
    sequenceNames = {'00_1', '00_2', '00_3', '00_4'};
    
    for sequenceIndex = 1:numel(sequenceNames)
        sequenceName = sequenceNames{sequenceIndex};
        sequenceFolder = fullfile(subjectFolder, sequenceName);
        fprintf('Sequence Folder: %s\n', sequenceFolder);
        
        % Construct the video filename
        videoFilename = [subjectName, sequenceName];
        videoPath = fullfile([videoFilename, '.avi']);
        fprintf('Video Path: %s\n', videoPath);
        
        % Process the video file as needed
        % disp(videoPath);

        % Run complete code
        % videoPath = [pwd '\v_HulaHoop_g11_c04.avi'];
        fprintf('Video Path: %s\n', videoPath);
        
        % runCompleteCode(videoPath);

        runFisherConcatPCA(videoPath,subjectName,sequenceIndex);

        % runNewCode(videoPath,subjectName,sequenceIndex);

        
    end
end

%videoPath = [pwd '\v_HulaHoop_g11_c04.avi'];
%runFisherConcatPCA(videoPath,subjectName,sequenceIndex);

end