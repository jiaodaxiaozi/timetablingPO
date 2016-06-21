%Restricted master LP; 
function [x] = RMLP(c, lb, ub)
%RMPL  Solve the relaxed problem with given fixings and perturbations 

% to show or unshow the debugging messages
global DEBUG
DEBUG = 0;
global PLOT

% C++ Pointers (insignificant here in Matlab)
% global genPaths

%%% global parameters
global B
global T
global R
global P
% global V

% 
% global Revenues
global mu
global Phi
global i
global K
global lambda
global SPs_id
global capCons
global mu_final

% setting parameters
k_max = 50; % maximum number of iterations
mu = zeros(B, T, k_max); % the multipliers (/prices/dual variable)
mu(:,:,1) = mu_final;
u = ones(k_max); % step control parameter

% initialization of variables
if DEBUG
    fprintf('Bundle: init ... \n');
end
k = 1; % first iteration
stop = false; % initially, no stop
SPs_id = zeros(R, k_max); % the identifiers of shortest path per iteration
g = zeros(B,T,k_max); % the subgradient per iteration
Phi = zeros(k_max, 1); % the dual objective value per iteration
i = ones(k_max,1); % the iteration number of the latest serious step

% get the paths to fix for each request (for RB)
paths2fix = GetFixingFromBounds(reshape(lb, [P R]),reshape(ub, [P R]));

% reshape the perturbation matrix
c = reshape(c, [P R]);

% initialization of the algorithm (generate the first approximation)
%%% Solve the shortes path (C++ function)
[totalRev, cap_cons, SPs_id(:,1), Phi_SP] = ...
    SP_RMLP(capCons, mu(:,:,1), paths2fix, c);
%%% compute the gradient
[Phi(1), g(:,:, 1)] = compute_phi_g(totalRev, cap_cons, mu(:,:,1), Phi_SP);

%%% Bundle phase
while ((~stop) && (k < k_max))
    
    % display iteration number
    if DEBUG
       fprintf('Bundle: iteration %d ... \n',k);
    end
    
    %%% Compute the new prices (Matlab function)
    [mu(:,:,k+1), u(k+1), stop, SPs_id(:,k+1), i(k+1), Phi(k+1), g(:,:, k+1)] = ...
    bundle_aggregate(k, paths2fix, c, mu, Phi, g, u(k), i(k), true);

    % next iteration
    k = k+1;
end


%%%%%%%%% Results display
% number of performed iterations
K = k-1;

% Constructs the fractional solution from lambda
i_curr = i(K);
[~, ~, lambda] = bundlequadprog_aggregate(mu, Phi, ones(K,1), g, u(i_curr), i_curr);
x = fract_sol(lambda(1:K,:), SPs_id(:,1:K));
x = x(:);
mu_final = mu(:,:,i_curr);

% display the final prices
if PLOT
    % draw optimal prices
    figure();
    DrawPrices(mu(:,:,i_curr));
    
    
    %%% PHI & REVENUES PER ITERATION
    figure();    
    plot(1:K, Phi(i(1:K),:), 'LineWidth',2);
    ylabel('Value')
    xlabel('Iteration')
    title('Dual Objective')
end

end

