clear all
close gcf
load("PI_Variables.mat");

col = [167, 226, 55]/255;

% Set semantic variables for data regarding each subject
tarDur = subjList(:, 1); % Target Durations
peak = subjList(:, 2)./tarDur; % Normalize peak value by target duration
spread = subjList(:, 3)./tarDur; % Normalize spread value by target duration
cv = spread./peak; % Coefficient of variation

excludedSubj = subjList((cv>5) | (peak>2.5), :); % Excluded subjects list 
subjList((cv>5) | (peak>2.5), :) = []; % Exclude outliers 

% Reset variables after outlier exclusion
tarDur = subjList(:, 1);
peak = subjList(:, 2)./tarDur;
spread = subjList(:, 3)./tarDur;
cv = spread./peak;

% Average variables for each unique target duration
uniqueTarDur = unique(tarDur, "sorted"); % Unique target durations
meanList = [];
for i = 1:length(uniqueTarDur)
    meanList = [meanList; nanmean(subjList(uniqueTarDur(i)==subjList(:, 1), :))];
end

% Set variables for each unique target duration
peakMean = meanList(:, 2)./uniqueTarDur; % Normalized average peak value for each uniqueTarDur
spreadMean = meanList(:, 3)./uniqueTarDur; % Normalized average spread value for each uniqueTarDur
cvMean = spreadMean./peakMean; % Coefficient of variation for each uniqueTarDur


% Plot peak values
subplot(2, 1, 1)
[f, rsqPeak] = fit(uniqueTarDur, peakMean, 'b*x^m');
plot(f, 'k')
hold on
scatter(tarDur, peak, 'k', 'filled', 'markeredgealpha', .2, 'markerfacealpha', .2, 'SizeData', 15) % Subject data behind
scatter(uniqueTarDur, peakMean, [], col, "filled"); plot(f, 'k'); % Mean data in front

yline(1, 'k--')

ylabel('Normalized Peak Times')
title('Temporal Accuracy Power Fit')
legend("off")
xlim([0 max(tarDur)+3])

% Plot Coefficient of Variations
subplot(2, 1, 2)

[f1, rsqCV] = fit(uniqueTarDur, cvMean, 'b*x^m');
plot(f1, 'k')
hold on
scatter(tarDur, cv, 'k', 'filled', 'markeredgealpha', .2, 'markerfacealpha', .2, 'SizeData', 15) % Subject data behind
scatter(uniqueTarDur, cvMean, [], col, "filled"); plot(f1,'k'); % Mean data in front

xlabel('Target Duration')
ylabel('CV')
title('Scalar Property Power Fit')
legend("off")

xlim([0 max(tarDur)+3])
sgtitle("Peak Interval Procedure")

%% Plot Peak Procedure Superposition 
coljet = parula(length(uniqueTarDur)*110); % Color Palette
increment = 0.025;
tarDurList = padcat(saveStructure.targetDuration{:}); % Merges each target duration list for each dataset into an array with NaN at the end

for uniqueDur = 1:length(uniqueTarDur)
    
    [durations, datasets] = find(tarDurList==uniqueTarDur(uniqueDur)); % Locate datasets and target durations containing that specific unique target duration
    
    for datasetIndex = 1:length(datasets) % Run for each dataset that is located for the unique target duration
        
        rawCdf = saveStructure.datasetCDF(durations(datasetIndex)).datasetCDF(datasets(datasetIndex)).data; % Extract related Cumulative Density Function 

        rawCdf = [rawCdf, (1:length(rawCdf))']; % Insert response time information (1s bins makes it possible)
        
        for bins = 1:40
            finalCdf(bins, :) = rawCdf(max(find(( rawCdf(:, 1)<= bins*increment))), :); % Bin each CDF onto 40 steps from 0-1
        end

        binnedCDF(uniqueDur).binnedCDF{datasetIndex} = finalCdf(:, 1); % CDF information
        timeStruct(uniqueDur).timeStruct{datasetIndex} = finalCdf(:, 2); % Time in trial information

    end

    % Time and CDF data are averaged across each target duration 
    meanCDF = nanmean(horzcat(binnedCDF(uniqueDur).binnedCDF{:}), 2);
    timeInTrial = nanmean(horzcat(timeStruct(uniqueDur).timeStruct{:}), 2); 

    % Normal Time-Scale
    figure(2)
    subplot(1, 2, 1)
    stairs(timeInTrial, meanCDF, 'color', coljet(uniqueDur*100, :));
    hold on

    % Curve Fitting 
    [xData, yData] = prepareCurveData(timeInTrial, meanCDF);

    ft = fittype(' 0.5.*erfc(-(x./mu - 1).*sqrt(lambda./x)./sqrt(2)) + exp(2.*lambda./mu) .* 0.5.*erfc((x./mu + 1).*sqrt(lambda./x)./sqrt(2));', 'independent', 'x', 'dependent', 'y');
    opts = fitoptions('Method', 'NonlinearLeastSquares');
    opts.Display = 'Off';
    opts.Lower = [0 0];
    opts.StartPoint = [0 120];

    [fitResult, ~] = fit(xData, yData, ft, opts);
    
    fitSpace = .1:.1:300;
    fitVal=coeffvalues(fitResult);
    p1 = plot(fitSpace, waldcdf(fitSpace, fitVal(2), fitVal(1)), "Color", coljet(uniqueDur*100,:), "LineWidth", 1);

    legend("off")
    sgtitle("Mean CDF Per Target Duration")
    xlabel("Time in Trial")
    ylabel("CDF")

    % Superposed Time-Scale
    superSpace = .1:.1:4;
    subplot(1, 2, 2)
    superpose = timeInTrial./median(timeInTrial);
    stairs(superpose, meanCDF, 'Color', coljet(uniqueDur*100,:));
    
    hold on

    % Curve fitting
    [fitResult, ~] = fit(superpose,meanCDF, ft, opts);
    fitVal=coeffvalues(fitResult);
    plot( superSpace, waldcdf(superSpace,fitVal(2),fitVal(1)), "Color", coljet(uniqueDur*100,:), "LineWidth", 1);
    
    legend("off")
    xlabel("Normalized Time in Trial")

    cb = colorbar;
    cb.Ticks=linspace(0,1,length(uniqueTarDur));
    cb.TickLabels=string(uniqueTarDur);
    cb.Limits=[0 1];
    xlim([0 4])
end





