


function y = waldpdf(X,b,c)

y = ( (c./(2*pi*(X.^3))).^(1/2) ) .* ( exp((-c.*(X-b).^2)./(2*b^2.*X)) );

end % func