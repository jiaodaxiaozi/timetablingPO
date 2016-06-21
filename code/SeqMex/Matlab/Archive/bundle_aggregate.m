function [mu_new, u_new, stop] = bundle_aggregate(k, paths2fix, c, epsilon, mu, u)
%bundle Computes the new dual iterate using aggregate bundle quadratic method

% global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

% Matlab fixed parameters (data sizes)
global T_g
global B_g

% Matlab global variables
global Phi_g % objective value
global g_g % subgradien
global lambda % lag. multipliers in the quadratic prob
global SPs_id % ids of the generated paths
global i % indices of the serious steps

% Parameters
m_L = 0.002; % step quality parameter
u_min = 0.005; % minimal value for the step size


if(k==1)
    % initializations
    k_max = size(SPs_id,2);
    Phi_g = zeros(k_max,1); % the dual objective
    g_g = zeros(B_g,T_g,1,k_max); % the subgradient
    i = ones(1,k_max);
    %%% Solve the shortes path (C++ function)
    [dualObj, cap_cons, SPs_id(:,k)] = ...
        mexSeqSP(network, graphs, mu, paths2fix, c, genPaths);
    %%% compute the gradient
    [Phi_g(k), g_g(:,:,1,k)] = compute_phi_g(dualObj, cap_cons, mu, true);
end

% previous multiplier
persistent mu_prev
if(k==1)
    mu_prev = mu;
end

% active constraints
persistent Active
Active_new = ones(k,1);
if(k>1)
    Active_new(1:end-1,1) = Active;
end
Active = Active_new;

% The reduced gradient Psi (used to avoid storing all the prices)
persistent Psi
Psi_new = zeros(1,k);
if(k>1)
    Psi_new(1,1:end-1) = Psi;
end
g_ = g_g(:,:,1,k);
Psi_new(1,k) = Phi_g(k)+g_(:)'*(mu(:)-mu_prev(:));
Psi = Psi_new;

% Solve the quadratic problem and get the predicted dual value
[y, Phi_predicted, lambda] = bundlequadprog_aggregate(mu, Phi_g, Active, g_g, u);
[Phi_k] = predict_aggregate(mu, Psi, Active, g_g, mu);

% get the achieved dual value
[dualObj, cap_cons, SPs_id(:,k+1)] = ...
        mexSeqSP(network, graphs, y, paths2fix, c, genPaths);
[Phi_g(k+1), g_g(:,:,1,k+1)] = compute_phi_g(dualObj, cap_cons, y, true);


%%% compute the predicte and achieved descents (descent = positive)
achieved = Phi_g(i(k)) - Phi_g(k+1);
predicted = Phi_k - Phi_predicted;

% stopping condition
if predicted < epsilon
    stop = true;
    mu_new = mu; % optimal prices
    u_new = u;
    return;
else
    stop = false;
    % Check if we take a serious step or not
    ratio = achieved/predicted;
    if ratio >= m_L % serious step
        mu_new = y; % new prices
        i(k+1) = k+1;
        u_new = max([u_min u/10 2*u*(1-abs(ratio))]); % new step parameter
    else% null step
        mu_new = mu; % same prices
        i(k+1) = i(k);
        u_new = min([10*u 2*u*(1-abs(ratio))]); % new step parameter                        
    end
    % update the active constraints
    Active = ones(k,1);
    for r=1:1
        for l=1:k
            if(lambda(l,r) > epsilon)
                Active(l,r) = 1;
            end
        end
    end
    mu_prev = y; % prices to use in the newly generated hyperplane 
end
