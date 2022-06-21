clear all
close gcf
load('TR_Variables.mat')
colormap parula
col = [167, 226, 55]/255;

% Empty arrays to be filled
normIndMat = []; indDurMat = []; CVIndMat = [];

for datasetNum = 1:length(durCell)
    for dur = 1:size(durCell{datasetNum}, 2)

        % Merge cell into a matrix
        normIndMat = [normIndMat; normCell{datasetNum}(:, dur)]; % Normalized reproductions of each dataset and target duration
        CVIndMat = [CVIndMat; CVCell{datasetNum}(:, dur)]; % CV of each dataset and target duration
        indDurMat = [indDurMat; durCell{datasetNum}(:, dur)]; % Corresponding target duration

    end
end

uniqueTarDur = unique(meanMatrixSorted(:, 1));

% Average variables for each unique target duration
meanList = [];
for tarDur = 1:length(uniqueTarDur)
    meanList=[meanList; nanmean(meanMatrixSorted(uniqueTarDur(tarDur)==meanMatrixSorted(:, 1), :), 1)];
end

uniqueTarDur = meanList(:, 1);
normMean = meanList(:, 2);
CVMean = meanList(:, 3);

% Plot reproductions
subplot(2, 1, 1)
[f, rsqN] = fit(uniqueTarDur, normMean, 'b*x^m');
plot(f, 'k')
hold on
scatter(indDurMat, normIndMat, 'k', 'filled', 'markeredgealpha', .2, 'markerfacealpha', .2, 'SizeData', 10) %individual data behind
scatter(uniqueTarDur, normMean, [], col, "filled"); plot(f, 'k'); %mean data in front

yline(1, 'k--')

ylabel('Normalized Reproductions')
title('Temporal Accuracy Power Fit')
leg2 = sprintf("RSQ: %s", num2str(rsqN.adjrsquare));
legend(leg2)

xlim([0 max(uniqueTarDur) + .5])
sgtitle("Temporal Reproduction")

% Plot Coef of Variations

subplot(2, 1, 2)
[f,rsqCV] = fit(uniqueTarDur, CVMean, 'b*x^m'); 
plot(f, 'k');

hold on

scatter(indDurMat, CVIndMat, 'k', 'filled', 'markeredgealpha', .2, 'markerfacealpha', .2, 'SizeData', 10) %individual data behind
scatter(uniqueTarDur, CVMean, [], col, "filled"); plot(f, 'k'); %mean data at top

xlabel('Target Duration')
ylabel('CV')
title('Scalar Property Power Fit')
xlim([0 max(uniqueTarDur) + .5])
leg1 = sprintf("RSQ: %s", num2str(rsqCV.adjrsquare));
legend(leg1)
