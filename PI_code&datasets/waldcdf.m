function y = waldcdf(x,mu,lambda)

% y=normcdf( sqrt(lambda./q) .* ((q./mu) - 1) ) + ...
%     exp((2.*lambda)./mu).*normcdf( - sqrt(lambda./q) .* ((q./mu) + 1) );

mu(mu <= 0) = NaN;
lambda(lambda <= 0) = NaN;

nonpos = (x <= 0);
x(nonpos)= realmin;
z1 = (x./mu - 1).*sqrt(lambda./x);
z2 = -(x./mu + 1).*sqrt(lambda./x);
y = 0.5.*erfc(-z1./sqrt(2)) + exp(2.*lambda./mu) .* 0.5.*erfc(-z2./sqrt(2));
% this would happen automatically for x==0, but generates DivideByZero warnings
y(nonpos) = 0;

% here's a hack: When lambda/mu > ~1000 or so, the expression is not robust
% because exp( 2lambda/mu) evaluates (wrongly) to inf. A hack is to devide
% lambda/mu by some factor that will keep it in a suitable range. The major
% issue that prevents us from doing the hack the entire time is that the
% hack works on only one part of the expression. So in the region in which
% the original expression (above) works, hacking it like this creates
% some discrepency issues problems. This only works in the region of
% lambda/mu > ~ 1000 because at that level, it approximates the true
% function to a reasonable enough degree to use. Caveat emptor.

%Of course, this  range depends on how big lambda/mu is. Assuming this script is used for
% the optimal DRL experiment of (Freestone, Balci, Simen) or similar, the
% critical variable is small you want the cv to get. the factor of 1e4
% below works well for w ~ 0.001.

%     nans = isnan( y );
%     y(nans) = 0.5.*erfc(-z1(nans)./sqrt(2)) + exp(2.*lambda(nans)./mu(nans)/1e4) .* 0.5.*erfc(-z2(nans)./sqrt(2));

end
