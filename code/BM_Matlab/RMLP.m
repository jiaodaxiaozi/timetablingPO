%Restricted master LP; 
% RMLP(w,l,u) 
%   w   costvector variables that model variable fixings to 0 and 1, l and u
function [x, obj] = RMLP(c,lb,ub,p)

% global variables
global ids
global requests
global network
global ordering
global path_ids
global R
global T
global B
global P
global stations

%%% Initializing parameters
k_max = 10; % maximum number of iterations
k = 1; % current iteration number
stop = false;

%%% Parameters to store the iteration results
mu = zeros(B,T); %  initially random prices
Phi = zeros(R,k_max); % dual objective function
g = zeros(B,T,R,k_max); % sub-gradient of the dual obj function
lambda = zeros(k_max,R); % multiplier for the convex combinations of paths
Path = zeros(R,k_max); % store index of the path which was chosen for each request and at each Bundle iteration
u = ones(1,k_max); % coefficient in front of the quadratic term in Bundle method
capCons = zeros(B,T,R,k_max); % capacity consumption of the shortest path

%%% Bundle phase
while ((~stop) && (k <= k_max))
        
    %%% Solve the shortes path (C++ function)
   [Phi(:,k), g(:,:,:,k), Path(:,k), capCons(:,:,:,k)] = ...
        MexSeqSP(ids, requests, network, ordering, path_ids, mu);
%MexSeqSP(ids, requests, network, ordering, path_ids, mu, c, lb, ub, p);
    
    % draw the timetable with the computed optimal paths
    DrawTimetable(capCons(:,:,:,k), stations);
       
    %%% Compute the new prices (Matlab function)
    [mu, lambda(1:k,:), stop, u(k+1)] = ...
        bundle(mu, Phi(:,1:k), g(:,:,:,1:k), u(k));
    
    % draw the density plot from the multipliers
    DrawPrices(mu, stations);

    % next iteration if the step is serious
    k = k+1
    
end


% Constructs the fractional solution from lambda
x = fract_sol(lambda, Path, P);
x = x(:);
x = sparse(x);

% objective value
obj = 0; % !TODO!

end

