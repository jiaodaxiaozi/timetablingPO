function [ f , g] = oracle(x)
%ORACLE An oracle function that is used to test the bundle phase

%% exponential (x_opt = 0)
% f = exp(x);
% g = exp(x);


%% polynomial (x_opt = 1)
f = sum((x(:)-20).*(x(:)-20));
g = 2*(x(:)-20);
g = reshape(g, size(x));

%% piece-wise function (x_opt = 2)
% if(x<2)
%     f = (x-2)^2+1;
%     g = 2*(x-2);
% else
%     f = (x-2)^3+1;
%     g = 3*(x-2)^2;   
% end

end

