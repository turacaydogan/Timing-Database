
%% REQUIRES TB_Code to be run first %%

clear all;close gcf
load ("TB_variables.mat")

recordFitMatrix = saveStructure.recordFitMatrix ;

outliers = [216, 552]; % According to WR and PSE values 
recordFitMatrix(outliers,:) = [];

PSE = recordFitMatrix(:,11); % Point of subjective equality
WR = recordFitMatrix(:,14); % Weber's ratio

taskDifficulty = recordFitMatrix(:,18);  % Task difficulty: min(probeList)/max(probeList)

arithmeticMean = recordFitMatrix(:,15);
geometricMean = recordFitMatrix(:,16);

PSE_normArithmetic = PSE./arithmeticMean; % Normalized to arithmetic mean
PSE_normGeometric = PSE./geometricMean; % Normalized to geometric mean

%% Plotting Task Difficulty vs. Wber's Ratio
figure('Name', "Task Difficulty vs. Weber's Ratio")

[f, goodness] = fit(taskDifficulty, WR, 'poly1');

scatter(taskDifficulty, WR, 'k', 'filled', 'markeredgealpha', .5, 'markerfacealpha', .5, 'SizeData', 20); % Plot training data

hold on
plot(f, 'k') % Plot fitted line.
title("Task Difficulty vs. Weber's Ratio")
xlabel("taskDifficulty")
ylabel("Weber's Ratio")
legend("off")

%% Plotting PSE Distributions
figure('Name', "Normalized Distributions")

subplot(2,1,1)
histogram(PSE_normArithmetic,100)
title("Arithmetic PSE dist")

subplot(2,1,2)
histogram(PSE_normGeometric,100)
title("Geometric PSE dist")
