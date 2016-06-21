function [mu_new, u_new, stop] = bundle(k, paths2fix, c, epsilon, mu, u)
%bundle Computes the new dual iterate using aggregate bundle quadratic method

% global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

% Matlab fixed parameters (data sizes)
global R_g
global T_g
global B_g

% Matlab global variables
global Phi_g % objective value
global g_g % subgradien
global lambda % lag. multipliers in the quadratic prob
global SPs_id % ids of the generated paths
global i % save the index of the last serious step

% Iteration parameters
m_L = 0.2; % in (0,0.5) for taking serious steps
u_min = 0.5; % minimal value for u

if(k==1)
    k_max = size(SPs_id,2);
    Phi_g = zeros(k_max,R_g);
    g_g = zeros(B_g,T_g,R_g,k_max);
    i = ones(1,k_max);
    %%% Solve the shortes path (C++ function)
    [dualObj, cap_cons, SPs_id(:,k)] = ...
        mexSeqSP(network, graphs, mu, paths2fix, c, genPaths);
    %%% compute the gradient
    [Phi_g(k,:), g_g(:,:,:,k)] = compute_phi_g(dualObj, cap_cons, mu, false);
end

% previous multiplier
persistent mu_prev
if(k==1)
    mu_prev = mu;
end

% The reduced gradient Psi (used to avoid storing all mu_s)
persistent Psi
Psi_new = zeros(R_g,k);
if(k>1)
    Psi_new(:,1:end-1) = Psi;
end
for r=1:R_g
    g_ = g_g(:,:,r,k);
    Psi_new(r,k) = Phi_g(k,r)+g_(:)'*(mu(:)-mu_prev(:));
end
Psi = Psi_new;


% active constraints
persistent Active
Active_new = ones(k,R_g);
if(k>1)
    Active_new(1:end-1,:) = Active;
end
Active = Active_new;

% Solve the quadratic problem
[y, Phi_predicted, lambda] = bundlequadprog(mu, Psi, Active, g_g, u);

% get the achieved and the predicted descent
[dualObj, cap_cons, SPs_id(:,k+1)] = ...
        mexSeqSP(network, graphs, y, paths2fix, c, genPaths);
%%% compute the gradient
[Phi_g(k+1,:), g_g(:,:,:,k+1)] = compute_phi_g(dualObj, cap_cons, y, false);
    
%%% compute the descents (positive -> descent)
achieved = sum(Phi_g(i(k),:)) - sum(Phi_g(k+1,:));
predicted = sum(Phi_g(i(k),:)) - Phi_predicted;
% stopping condition
sc = predicted/sum(Phi_g(i(k),:));
if sc < -epsilon
    stop = true;
    u_new = u;
    mu_new = mu;
    return;
else
    stop = false;
    % Check if we take a serious step or not
    ratio = achieved/predicted;
    if ratio >= m_L % serious step
        mu_new = y; % new prices
        i(k+1) = k+1;
        u_new = max([u_min u/10 2*u*(1-ratio)]); % new step parameter
    elseif(ratio>0) % null step
        mu_new = mu; % same prices
        i(k+1) = i(k);
        u_new = min([10*u 2*u*(1-ratio)]); % new step parameter
    else
        mu_new = mu; % same prices
        i(k+1) = i(k);
        u_new = u/10; % new step parameter        
    end
    mu_prev = y; % prices to use in the newly generated hyperplane
end

% update the set of active constraints for the next call
Active = zeros(k,R_g);
for r=1:R_g
    for l=1:k
        if(lambda(l,r) > epsilon)
            Active(l,r) = 1;
        end
    end
end