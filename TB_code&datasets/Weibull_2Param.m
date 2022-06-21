function [fitresult, gof] = CFToolboxFit_2Param(durationList, individualData)
%  close gcf
%CREATEFIT1(DURATIONLIST,INDIVIDUALDATA)
%  Create a fit.
%
%  Data for 'untitled fit 1' fit:
%      X Input : durationList
%      Y Output: individualData
%  Output:
%      fitresult : a fit object representing the fit.
%      gof : structure with goodness-of fit info.
%
%  See also FIT, CFIT, SFIT.



%% Fit: 'untitled fit 1'.
[xData, yData] = prepareCurveData( durationList, individualData );

% Set up fittype and options.
% ft = fittype( '1-exp(-1*((x/l)^s))', 'independent', 'x', 'dependent', 'y' );
% opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
% opts.Display = 'Off';
% opts.MaxIter = 20000;
% % l s
% opts.Lower = [1	0];
% opts.Upper = [4.5	7.1];

%% With Hedge Factors

ft = fittype( '(1-exp(1)^-((x/l)^s))', 'independent', 'x', 'dependent', 'y' );
opts = fitoptions( 'Method', 'NonlinearLeastSquares' );
opts.Display = 'Off';

% gamma l lambda s
% opts.Lower = [-Inf 0 -Inf 0];
% opts.Upper = [Inf 4.5 Inf 7.1];

opts.Lower = [0 0];
opts.Upper = [30 300];
% opts.MaxIter = 500000;
opts.StartPoint = [mean(durationList), rand];

% Fit model to data.
[fitresult, gof] = fit( xData, yData, ft, opts );

% Plot fit with data.

% figure( 'Name', 'weibull Fit' );
% h = plot( fitresult, xData, yData );
% legend( h, 'Proportion of Long Responses vs. Tested Durations', 'Weibull Fit', 'Location', 'SouthEast' );
% % Label axes
% xlabel( 'Tested Durations' );
% ylabel( 'Proportion of Long (L) Responses' );
% xlim([min(durationList)-0.2 max(durationList)+0.2]);
% ylim([0 1]);
% grid on


