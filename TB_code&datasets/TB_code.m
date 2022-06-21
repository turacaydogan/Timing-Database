clear all;clear all;close all;clc;
close gcf

% Process necessary files
myFolder = sprintf("%s\\TB_datasets", string(pwd));
filePath = fullfile(myFolder, '**/*.csv');
csvFiles = dir(filePath);

recordFitMatrix = []; % Will be filled with individual data
recordMeanFitMat = []; % Will be filled with average data

for datasetIndex = 1:length(csvFiles) % Go through all csv files

    clearvars -except myFolder filePath csvFiles datasetIndex recordFitMatrix finalDurList recordMeanFitMat saveStructure
    baseFileName = csvFiles(datasetIndex).name;
    fullFileName = fullfile(csvFiles(datasetIndex).folder, baseFileName);
    fprintf(1, 'Now reading %s\n', fullFileName);
    dataTable = readtable(fullFileName);

    % Form the matrix containing required columns for analysis
    matrix = [table2array(dataTable(:,2)), table2array(dataTable(:,9)), string(table2array(dataTable(:,10))), table2array(dataTable(:,11))];

    % Change categorical values into numeric
    for i = 1:length(matrix)
        if contains(matrix(i, 3), 'L')==1
            matrix(i, 3) = 1;  %LONG
        elseif contains(matrix(i, 3), 'S')==1
            matrix(i, 3) = 0;  %SHORT
        end
    end

    matrix = str2double(matrix(:, 1:3));

    probeDurationList = unique(matrix(:,2),'sorted')'; % Create a list of probe durations
    finalDurationList{datasetIndex} = probeDurationList; % For the final list

    % Calculating means of probe durations
    arithmeticMean = mean([max(probeDurationList), min(probeDurationList)]);
    geometricMean = geomean([max(probeDurationList), min(probeDurationList)]);
    harmonicMean = harmmean([max(probeDurationList), min(probeDurationList)]);

    subjCount = 0;
    % Counting novel subjects; occasionaly irregular subject indices may be present
    for subj = 1:max(matrix(:,1))
        if ismember(subj, matrix(:,1))==1
            subjCount = subjCount+1;
        else
            continue
        end

        for dur = 1:length(probeDurationList)

            % Calculate short & long percentages
            percentLongResponses =  length(find(matrix(:, 3)==1 & matrix(:, 1)==subj & matrix(:, 2)==probeDurationList(dur)));
            percentShortResponses = length(find(matrix(:, 3)==0 & matrix(:, 1)==subj & matrix(:, 2)==probeDurationList(dur)));

            % Calculate long response possibilities at each probe duration
            bisectionData(subjCount, dur) = (percentLongResponses/(percentLongResponses+percentShortResponses));

        end
    end

    % Calculate Parameters for Each Subject

    for subj = 1:subjCount

        [fitresult, gof] = Weibull_2Param(probeDurationList, bisectionData(subj,:));  % Calculate curve fitting parameters

        recordFit(subj,:) = [fitresult.l, fitresult.s, cell2mat(struct2cell(gof))']; % SSE RSQ DFE ADJRSQ RMSE
        clear fitresult gof

        % Obtain Weibul parameters
        L = recordFit(subj, 1); % Scale
        S = recordFit(subj, 2); % Shape

        percentiles = [];
        for perc=1:3 % Calculate 25 50 75 percentiles
            percentiles=[percentiles L*((-log(1-perc*25/100))^(1/S))];
        end

        percentiles = [percentiles, (percentiles(3)-percentiles(1))/2, ((percentiles(3)-percentiles(1))/2)/percentiles(2) ]; % [25, PSE, 75, DL, WR]

        taskDifficulty = min(probeDurationList)/max(probeDurationList);

        recordFitMatrix = [recordFitMatrix; datasetIndex, subj, recordFit(subj, :), percentiles, arithmeticMean, geometricMean, harmonicMean, taskDifficulty];

    end


    % Calculate Weibull Fits for each dataset

    recordMeanFit = [];

    meanBisection = mean(bisectionData, 'omitnan'); % Average probabilities over each probe duration

    [fitresult, gof] = Weibull_2Param(probeDurationList, meanBisection); % Calculate parameters for averaged data

    recordMeanFit = [fitresult.l, fitresult.s, cell2mat(struct2cell(gof))']; % [SSE, RSQ, DFE, ADJRSQ, RMSE]
    clear fitresult gof

    L = recordMeanFit(1); % Scale
    S = recordMeanFit(2); % Shape

    parametersMean = [];

    for perc = 1:3
        parametersMean=[parametersMean L*((-log(1-perc*25/100))^(1/S))];
    end

    parametersMean = [parametersMean, (parametersMean(3)-parametersMean(1))/2, ((parametersMean(3)-parametersMean(1))/2)/parametersMean(2)]; % [25, PSE, 75, DL, WR]

    recordMeanFitMat = [recordMeanFitMat; datasetIndex, subj, recordMeanFit, percentiles, arithmeticMean, geometricMean, harmonicMean, taskDifficulty];

    % PLOTTING Weibull Fits for each Dataset

    errorSize = nanstd(bisectionData)/sqrt(length(bisectionData));

    annotationText = sprintf('%s %s %d \nreference interval: %s \nPSE: %s \nL:%s \nDL: %s \nWR: %s \nRSQ: %s', string(dataTable{1,1}), string(dataTable{1,6}), subjCount, string(dataTable{1,11}), percentiles(2), string(L),  percentiles(4), percentiles(5), string(recordMeanFit(6)) );
    clear f plotfit

    f = fittype('(1-exp(1)^-((x/l)^s))', 'independent', 'x', 'dependent', 'y'); % Fitting into cumulative 2 parameter weibull

    plotfit = cfit(f, L, S);

    figure('Name', 'Weibull Fit'); % Plotting the weibull fit
    weibullHandle = plot(plotfit, probeDurationList, meanBisection);
    hold on
    errorbar(probeDurationList, meanBisection, errorSize, 'LineStyle', 'none'); % Adding errorbars for each probe duration tested
    legend(weibullHandle, 'Long Prob', 'Weibull Fit', 'Location', 'SouthEast');
    titleText = strrep(string(baseFileName(12:end-4)),'_',' '); title(titleText);
    xlabel('Durations');
    ylabel('Long Response Prob');
    xlim([min(probeDurationList)-0.2 max(probeDurationList)+0.2]);
    ylim([0 1]);
    grid on
    set(gca, 'XTickLabel', string(probeDurationList), 'XTick', probeDurationList);
    set(gcf, 'units', 'normalized', 'outerposition', [0 0 1 1])
    set(gcf, 'Color', 'w');
    annotation('textbox', [0.2 0.8 0.1 0.1], 'String', annotationText, 'FitBoxToText', 'on');
    W_saveas = sprintf("W_Fit%s.jpg", baseFileName(8:end-4)); saveas(figure(1), W_saveas);
    close gcf

    recordFitTable = array2table(recordFitMatrix, 'VariableNames', {'datasetnum', 'subj', 'L', 'S', 'SSE', 'RSQ', 'DFE', 'ADRSQ', ...
        'RMSE', '25', 'PSE', '75', 'DL', 'WR', 'aritMean', 'geoMean', 'harmMean', 'taskDifficulty'});

    recordMeanFitTable = array2table(recordMeanFitMat, 'VariableNames', {'datasetnum', 'subj', 'L', 'S', 'SSE', 'RSQ', 'DFE', 'ADRSQ', ...
        'RMSE', '25', 'PSE', '75', 'DL', 'WR', 'aritMean', 'geoMean', 'harmMean', 'taskDifficulty'});

    clear f plotfit
    
    % Create a save structure
    saveStructure.plotfit{datasetIndex} = plotfit;
    saveStructure.tarDur{datasetIndex} = probeDurationList;
    saveStructure.meanBisection{datasetIndex} = meanBisection;
    saveStructure.bisectionData{datasetIndex} = bisectionData;
    saveStructure.matrix{datasetIndex} = matrix;
    saveStructure.L{datasetIndex} = L;
    saveStructure.S{datasetIndex} = S;
    saveStructure.recordFitTable = recordFitTable;
    saveStructure.recordMeanFitTable = recordMeanFitTable;
    saveStructure.recordFitMatrix = recordFitMatrix;
    saveStructure.recordMeanFitMat = recordMeanFitMat;
    saveStructure.finalDurationList = finalDurationList;

end
save("TB_Variables.mat", "saveStructure")