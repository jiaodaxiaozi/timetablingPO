%Restricted master LP; 
function [x] = RMLP(c,lb,ub)
%RMPL  Solve the relaxed problem with given fixings and perturbations 

% to show or unshow the debugging messages
global DEBUG

% global data
global R_g % the number of train requests
global T_g % time slots
global B_g % number of blocks

global lambda % lag. multipliers in the quadratic prob
global SPs_id % identifiers of the generated paths for each iteration

global K

% Matlab fixed parameter
P = size(c, 2); % maximal number of generated paths per request

% Parameters
k_max = 50; % maximum number of iterations
epsilon = 10^-3; % accuracy tolerance
mu = zeros(B_g, T_g);
u = 1;
% initializations
if DEBUG
    fprintf('Bundle: init ... \n');
end
k = 1; % first iteration
stop = false; % initially, no stop
SPs_id = zeros(R_g, k_max);

% get the paths to fix for each request
paths2fix = GetFixingFromBounds(reshape(lb, [P R_g]),reshape(ub, [P R_g]));

%%% Bundle phase
while ((~stop) && (k < k_max))
    
    % display iteration number
    if DEBUG
       fprintf('Bundle: iteration %d ... \n',k);
    end
    
    %%% Compute the new prices (Matlab function)
    [mu, u, stop] = bundle_aggregate(k, paths2fix, c, epsilon, mu, u);
%    [mu, u, stop] = bundle(k, paths2fix, c, epsilon, mu, u);
    
    % next iteration
    k = k+1;
end

% number of performed iterations
K = k-1;

% Constructs the fractional solution from lambda
x = fract_sol(lambda(1:(k-1),:), SPs_id(:,2:k));
x = x(:);

% display the final prices
if DEBUG
    DrawPrices(mu(:,:,K));
end
end

