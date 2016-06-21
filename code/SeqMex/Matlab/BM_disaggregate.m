%Restricted master LP; 
function [x, mu_opt, Phi_it, capCons_opt] = ...
    BM_disaggregate(network,graphs,genPaths, Cap, B, T, R, P)
%RMPL  Solve the relaxed problem with given fixings and perturbations 

global DEBUG
global DEBUG_L1

Cap = double(Cap);

% setting parameters
k_max = 200; % maximum number of iterations
mu = zeros(B, T, k_max); % the multipliers (/prices/dual variable)
u = ones(k_max); % step control parameter

% initialization of variables
if DEBUG
    fprintf('BM_dis: init ... \n');
end
k = 1; % first iteration
stop = false; % initially, no stop
SPs_id = zeros(R, k_max); % the identifiers of shortest path per iteration
g = zeros(B,T,R, k_max); % the subgradient per iteration
Phi = zeros(k_max, R); % the dual objective value per iteration
cst = zeros(k_max,1);
i = ones(k_max,1); % the iteration number of the latest serious step

% initialization of the algorithm (generate the first approximation)
%%% Solve the shortes path (C++ function)
[totalRev, cap_cons, SPs_id(:,1), Phi_SP] = ...
    mexSeqSP(network, graphs, genPaths, mu(:,:,1));
%%% compute the gradient
[Phi(1, :), g(:,:,:, 1), cst(1,1)] = ...
    compute_phi_g_dis(totalRev, cap_cons, mu(:,:,1), Phi_SP, Cap);

%%% Bundle phase
while ((~stop) && (k < k_max))
    
    % display iteration number
    if DEBUG_L1
       fprintf('BM_dis: iteration %d ... \n',k);
    end
    
    %%% Compute the new prices (Matlab function)
    [mu(:,:,k+1), u(k+1), stop, SPs_id(:,k+1), i(k+1), Phi(k+1,:), g(:,:,:,k+1), cst(k+1), capCons_opt] = ...
    bundle_disaggregate(k, zeros(R,1), zeros(P,R), mu, Phi, g, u(k,1), i(k,1), cst, false, ...
    Cap, network, graphs, genPaths, cap_cons);
    
    % next iteration
    k = k+1;
end


%%%%%%%%% Results display
% number of performed iterations
K = k-1;


%% Results display
% Constructs the fractional solution from lambda
i_opt = i(K);
mu_opt = mu(:,:,i_opt);
[~, ~, lambda] = bundlequadprog_disaggregate(mu, Phi, ones(K,R), g, u(i_opt), i_opt, Cap);
x = fract_sol(lambda(1:K,:), SPs_id(:,1:K), P);
x = x(:);

Phi_it = sum(Phi(i(1:K),:),2)+cst(i(1:K));
if DEBUG
    if(k < k_max)
        fprintf('BM_dis: optimal solution found after %d iterations!\n', k);
    else
        fprintf('BM_dis: solution found but not optimal!\n');        
    end
end
end

