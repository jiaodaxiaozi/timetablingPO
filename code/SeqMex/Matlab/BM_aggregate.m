%Restricted master LP; 
function [x, mu_opt, Phi_it, capCons_opt] = BM_aggregate(network,graphs,genPaths, Cap, B, T, R, P)
%RMPL  Solve the relaxed problem with given fixings and perturbations 

Cap = double(Cap);

% to show or unshow the debugging messages
global DEBUG

% setting parameters
k_max = 200; % maximum number of iterations
mu = zeros(B, T, k_max); % the multipliers (/prices/dual variable)
u = ones(k_max,1); % step control parameter

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

% initialization of the algorithm (generate the first approximation)
%%% Solve the shortes path (C++ function)
[totalRev, capCons, SPs_id(:,1), Phi_SP] = ...
    mexSeqSP(network, graphs, genPaths, mu(:,:,1));
capCons_opt = capCons;
%%% compute the gradient
[Phi(1), g(:,:, 1)] = compute_phi_g(totalRev, capCons, mu(:,:,1), Phi_SP, Cap);

%%% Bundle phase
while ((~stop) && (k < k_max))
    
    % display iteration number
    if DEBUG
       fprintf('Bundle: iteration %d ... \n',k);
    end
    
    %%% Compute the new prices (Matlab function)
    [mu(:,:,k+1), u(k+1), stop, SPs_id(:,k+1), i(k+1), Phi(k+1), g(:,:, k+1), capCons_opt] = ...
    bundle_aggregate(k, zeros(R,1), zeros(P,R), mu, Phi, g, u(k), i(k), false, ...
    Cap, network, graphs, genPaths, capCons_opt);
    
    % next iteration
    k = k+1;
end

K = k-1;

%% Results display
% Constructs the fractional solution from lambda
i_opt = i(K);
mu_opt = mu(:,:,i_opt);
[~, ~, lambda] = bundlequadprog_aggregate(mu, Phi, ones(K,1), g, u(i_opt), i_opt);
x = fract_sol(lambda(1:K,:), SPs_id(:,1:K), P);
x = x(:);

Phi_it = sum(Phi(i(1:K),:),2);
end