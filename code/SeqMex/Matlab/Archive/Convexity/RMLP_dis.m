%Restricted master LP; 
function [x] = RMLP_dis(c,lb,ub)
%RMPL  Solve the relaxed problem with given fixings and perturbations 

% to show or unshow the debugging messages
global DEBUG
global PLOT


% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

%%% global parameters
global B
global T
global R
global P
global V


global Revenues
global Phi
global i
global K
global cst
global lambda
global SPs_id
global mu


% setting parameters
k_max = 100; % maximum number of iterations
mu = zeros(B, T, k_max); % the multipliers (/prices/dual variable)
u = ones(k_max, 1); % step control parameter

% initialization of variables
if DEBUG
    fprintf('Bundle: init ... \n');
end
k = 1; % first iteration
stop = false; % initially, no stop
SPs_id = zeros(R, k_max); % the identifiers of shortest path per iteration
g = zeros(B,T,R,k_max); % the subgradient per iteration
Phi = zeros(k_max, R); % the dual objective value per iteration
cst = zeros(k_max,1);
i = ones(k_max,1); % the iteration number of the latest serious step

% get the paths to fix for each request (for RB)
paths2fix = GetFixingFromBounds(reshape(lb, [P R]),reshape(ub, [P R]));

% reshape the perturbation matrix
c = reshape(c, [P R]);

% initialization of the algorithm (generate the first approximation)
%%% Solve the shortes path (C++ function)
[totalRev, cap_cons, SPs_id(:,1), Phi_SP] = ...
    mexSeqSP(network, graphs, mu(:,:,1), paths2fix, c, genPaths);
%%% compute the gradient
[Phi(1,:), g(:,:,:,1), cst(1,1)] = compute_phi_g_dis(totalRev, cap_cons, mu(:,:,1), Phi_SP);
%%% Bundle phase
while ((~stop) && (k < k_max))
    
    % display iteration number
    if DEBUG
       fprintf('Bundle: iteration %d ... \n',k);
    end
    
    %%% Compute the new prices (Matlab function)
    [mu(:,:,k+1), u(k+1,1), stop, SPs_id(:,k+1), i(k+1,1), Phi(k+1,:), g(:,:,:,k+1), cst(k+1)] = ...
    bundle_disaggregate(k, paths2fix, c, mu, Phi, g, u(k,1), i(k,1), cst);
    

    % next iteration
    k = k+1;
end


%%%%%%%%% Results display
% number of performed iterations
K = k-1;

% Constructs the fractional solution from lambda
i_curr = i(K);
[~, ~, lambda] = bundlequadprog_disaggregate(mu, Phi, ones(K,R), g, u(i_curr), i_curr);
x = fract_sol(lambda(1:K,:), SPs_id(:,1:K));
x = x(:);
% get the generated paths
[~, Revenues, ~] = mexPaths(genPaths);
% the revenues of the generated paths
V = zeros(P,R);
V(1:size(Revenues,1),1:R) = Revenues;

% display the final prices
if PLOT
    % draw optimal prices
    DrawPrices(mu(:,:,i_curr));
    
    %%% PHI & REVENUES PER ITERATION
    figure();    
    plot(1:K, sum(Phi(i(1:K),:),2)+cst(i(1:K)), 'LineWidth',2);
    ylabel('Value')
    xlabel('Iteration')
    title('Dual Objective')
end

end

