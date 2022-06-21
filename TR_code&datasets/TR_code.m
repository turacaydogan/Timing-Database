clear all;clear all;close all;clc;
close gcf

% Process necessary files
myFolder = sprintf("%s\\TR_datasets",pwd);
filePath = fullfile(myFolder, '**/*.csv');
csvFiles = dir(filePath);

% Empty arrays to be filled between datasets
reprDatasetMatrix = []; CVDatasetMatrix = []; fullDurMat = []; 

for datasetIndex = 1:length(csvFiles) % Go through all csv files

    clearvars -except myFolder filePath csvFiles CVCell normCell durCell matrixCell datasetIndex reprDatasetMatrix CVDatasetMatrix 
    baseFileName = csvFiles(datasetIndex).name;
    fullFileName = fullfile(csvFiles(datasetIndex).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', fullFileName);
    dataTable = readtable(fullFileName);

    % Form the matrix containing required columns for analysis
    matrix = [table2array(dataTable(:, 2:5)), table2array(dataTable(:, 9:10))];

    targetDuration = unique(matrix(:, 5), 'sorted')'; % Create a list of target durations

    subjColumn = matrix(:, 1); % Subject information
    targetDurColumn = matrix(:, 5); % Target duration information
    reproducedDurColumn = matrix(:, 6); % Reproduced duration information

    subjCount = 0;

    for subj = 1:max(subjColumn)

        % Count novel subjects; occasionaly irregular subject indices may be present
        if ismember(subj, subjColumn)==1
            subjCount = subjCount + 1;
        else
            continue
        end

        for dur = 1:length(targetDuration)

            % Create normalized reproduced duration and CV matrices for each subject and duration set 
            % Reproductions below 33% and above 300% of target durations are marked as outliers

            repDur(subjCount, dur) = mean(matrix(find(subjColumn==subj ...
                & targetDurColumn==targetDuration(dur) ...
                & reproducedDurColumn < targetDuration(dur)*3 ...
                & reproducedDurColumn>targetDuration(dur)*.33), 6), 'omitnan')/targetDuration(dur);
            
            CV(subjCount, dur) = std(matrix(find(subjColumn==subj ...
                & targetDurColumn==targetDuration(dur) ...
                & reproducedDurColumn < targetDuration(dur)*3 ...
                & reproducedDurColumn>targetDuration(dur)*.33), 6), 'omitnan')/(repDur(subjCount,dur)*targetDuration(dur));
            
            subjDur(subjCount, dur) = targetDuration(dur);

        end
    end

    colorJet = parula(1000); % Color palette array
 
    % Take mean of Normalized reproductions and CVs of all subjects 
    meanReproduction = nanmean(repDur);
    meanCV = nanmean(CV);
    
    % Collect means of normalized reproduced duration  of each dataset into one matrix for visualization
    reprDatasetMatrix = [reprDatasetMatrix, meanReproduction]; 
    
    % Collect means of CV of each dataset into one matrix for visualization
    CVDatasetMatrix = [CVDatasetMatrix, meanCV]; 
   
    fullDurMat = [fullDurMat, targetDuration];
    
    % Merge into one matrix for brevity
    meanMatrixSorted = sortrows([fullDurMat; reprDatasetMatrix; CVDatasetMatrix]');

    % Saving variables
    normCell{datasetIndex} = repDur;
    CVCell{datasetIndex} = CV;
    durCell{datasetIndex} = subjDur;
    matrixCell{datasetIndex} = matrix;

end

save('TR_Variables.mat', 'meanMatrixSorted', 'normCell', 'CVCell', 'durCell', 'matrixCell')
