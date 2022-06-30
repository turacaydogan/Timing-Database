clear all
close gcf

% Process necessary files
myFolder = sprintf("%s\\PI_datasets", pwd);
filePath = fullfile(myFolder, '**/*.csv');
csvFiles = dir(filePath);

subjList = []; % Variables list of each subject: target duration, peak, spread for each subject

for datasetIndex = 1:length(csvFiles) % Go through all csv files

    clearvars -except myFolder filePath csvFiles datasetIndex saveStructure subjList
    baseFileName = csvFiles(datasetIndex).name;
    fullFileName = fullfile(csvFiles(datasetIndex).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', fullFileName);
    dataTable = readtable(fullFileName);
    
    % Use only last 10 sessions of data corresponding to steady-state
    sessionColumn = table2array(dataTable(:,3)); % Session information
    
    sessionList = unique(sessionColumn,'sorted'); % Unique session numbers are sorted
    
    if length(sessionList) > 10 % Last 10 sessions of data is extracted
        steadyStateSessions = sessionList(end-9:end);
        dataTable = dataTable(ismember(sessionColumn, steadyStateSessions), :);
    end

    
    subjColumn = table2array(dataTable(:, 2)); % Subject id
    targetDurColumn = table2array(dataTable(:, 9)); % Target Duration 
    trialColumn = table2array(dataTable(:, 5)); % Trial number
    
    % Form the matrix of raw data containing required columns 
    matrix = [subjColumn, targetDurColumn, trialColumn, table2array(dataTable(:, 3))];

    targetDuration = unique(targetDurColumn, 'sorted')';
    targetDuration = targetDuration(~isnan(targetDuration));

    % Response times are semicolon separated strings 
    % Turn them into cells of numericals
    cellONsettime = regexp(string(table2array(dataTable(:, 10))), ";", "split");
    
    % Merge different lengths of cells into arrays, NaNs at the ends
    onsetTime=padcat(cellONsettime{:});

    % Some datasets cause problems while converting into numericals
    if isstring(onsetTime)==1
        onsetTime = str2double(onsetTime);
    end

    for dur = 1:length(targetDuration)
        subjCount = 0;
        onsetMax = targetDuration(dur)*3; % Maximum response time is set to 3 times of the target duration 
        if targetDuration(dur)<9
            onsetMax = targetDuration(dur)*5; % Maximum response time is set to 5 times of the target duration (shorter than 9 seconds)
        end

        % Count novel subjects; occasionaly irregular subject indices may be present
        for subj = 1:max(subjColumn)
            if ismember(subj, subjColumn)==1
                subjCount = subjCount + 1;
            else
                continue
            end
            durSubjOnset = onsetTime(subjColumn==subj & targetDurColumn==targetDuration(dur),:); % Extract response times regarding the subjects
            durSubjOnset(durSubjOnset<=0 | durSubjOnset>onsetMax) = NaN; 
            indOnset{subjCount, dur} = durSubjOnset; % Group response times by subjects and target durations
        end

        trialIndex = trialColumn(targetDurColumn==targetDuration(dur)); % Extract trial information regarding the target duration

        durTrialOnset = onsetTime(targetDurColumn==targetDuration(dur), :); % Extract response times information relating the target duration
        durTrialOnset(durTrialOnset<=0 | durTrialOnset>onsetMax) = NaN; 
        
        % Single-trial Start-Stop Calculation
        singleTrialStartStopMat = []; % Matrix to be filled with Start and Stop values of each trial
        
        for trial = 1:size(trialIndex, 1)

            [trialBinCount, ~, ~] = histcounts(durTrialOnset(trial, :), 0:onsetMax); % Response times are binned into 1-s bins
            
            if nnz(trialBinCount)<=4 % If there are less than 4 non zero element, the start-stop calculation does not work properly

                singleTrialStartStopMat=[singleTrialStartStopMat; NaN(1, 4)];

                continue

            end

            [trialStartStop] = getStartStop(trialBinCount); % getStartStop is an external function that calculates Start, Stop, Peak, and Spread values of a given array

            singleTrialStartStopMat = [singleTrialStartStopMat; trialStartStop]; % Single-trial start-stop outputs are collected in an array

        end

        % Subject Start-Stop Calculation
        subjectStartStopMat = []; % Matrix to be filled with Start and Stop values of each subject
        subjectBinCounts = []; % Bin counts of the response times of each subject

        for subj = 1:subjCount
            subjmat = vertcat(indOnset{subj, dur}); % Response times of each subject and target duration are concatenated
            subjmat(subjmat<=0 | subjmat>onsetMax) = NaN;

            if isempty(subjmat)==1
                continue
            end
            [subjBinCount, ~, ~] = histcounts(subjmat, 0:onsetMax); % Response times regarding each subject are binned into 1 second bins
            
            if nnz(subjBinCount)<=4 % If there are less than 4 non zero element, the start-stop calculation does not work properly

                subjectStartStopMat = [subjectStartStopMat; NaN(1, 4)]; 

                continue
            end

            subjectBinCounts = [subjectBinCounts; subjBinCount]; % Subject bin counts are collected in an array

            smoothNum = 19/30*targetDuration(dur); % Smoothing factor is calculated depending on target duration (19 for 30 s target duration)

            if targetDuration(dur)<9 % Target durations < 9 s are smoothened by a factor equivalent to the target duration
                smoothNum = targetDuration(dur);
            end
            
            smoothSubj = smooth(subjBinCount, smoothNum); % Response time bins of subjects are smoothened

            [subjStart] = getStartStop(smoothSubj); % getStartStop is an external function that calculates Start, Stop, Peak, and Spread values of a given array

            subjectStartStopMat = [subjectStartStopMat; subjStart]; % Start-Stop outputs of each subject are collected in an array

            spread = subjStart(2) - subjStart(1); % Spread value is calculated
            [~, peak] = max(smoothSubj); % Peak of the response curve is calculated

            subjList = [subjList; targetDuration(dur), peak, spread]; % Turned into a list for convenience

        end
        
        datasetBinCount = mean(subjectBinCounts, 1, "omitnan")'; % Dataset Response Curves for each target duration
        datasetStartStopMean = round(mean(subjectStartStopMat, 1, "omitnan")); % Averaging start and stop values to have a dataset start - stop value
        datasetBinCount = datasetBinCount(1:datasetStartStopMean(2)); % Cut probability density function at the stop value
        datasetPDF = datasetBinCount./sum(datasetBinCount); % Compute Probability Density Function
        datasetPDF(datasetPDF(:)==0) = NaN; % Omit zero values
        datasetCDF = cumsum(datasetPDF, 'omitnan'); % Create Cumulative Density Function

        % Save variables in a structure (for each target duration)
        saveStructure.datasetCDF(datasetIndex).datasetCDF(dur).data = datasetCDF;
        saveStructure.subjectBinCounts(datasetIndex).subjectBinCounts(dur).data = subjectBinCounts;
        saveStructure.subjectStartStopMat(datasetIndex).subjectStartStopMat(dur).data = subjectStartStopMat;
        saveStructure.datasetPDF(datasetIndex).datasetPDF(dur).data = datasetPDF;

    end

    % Save global variables in a structure 
    saveStructure.targetDuration{datasetIndex} = targetDuration;
    saveStructure.indOnset{datasetIndex} = indOnset;
    saveStructure.matrix{datasetIndex} = matrix;
    saveStructure.onsettime{datasetIndex} = onsetTime;
    saveStructure.subjList = subjList;

end

save('PI_Variables.mat', 'saveStructure') 