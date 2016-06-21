function [mu_new, u_new, stop, SPs_id, i_new, Phi_new, g_new, cst_new] = ...
    bundle_disaggregate(k, paths2fix, c, mu, Phi, g, u_curr, i_curr, cst, Restricted)
%bundle Computes the new dual iterate using aggregate bundle quadratic method

global R

% global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

% Parameters
m_L = 0.25; % step quality parameter
u_min = 0.1; % minimal value for the step size
epsilon = 10^-6;

persistent Active
if(k==1)
    Active = ones(k,R);
else
    tmp = ones(k,R);
    tmp(1:end-1, :) = Active;
    Active = tmp;
end


% active constraints
[Phi_bar, Active] = predict_disaggregate(k, mu(:,:,i_curr), Phi, g, mu, Active);

% Solve the quadratic problem and get the predicted dual value
[y, Phi_predicted, ~] = bundlequadprog_disaggregate(mu, Phi, Active, g, u_curr, i_curr);

% get the achieved dual value
if(Restricted)
    [totalRev, cap_cons, SPs_id, Phi_SP] = ...
        SP_RMLP(capCons, y, paths2fix, c);
else
    [totalRev, cap_cons, SPs_id, Phi_SP] = ...
        mexSeqSP(network, graphs, genPaths, y);
end
[Phi_new, g_new, cst_new] = compute_phi_g_dis(totalRev, cap_cons, y, Phi_SP);
S_Phi_new = sum(Phi_new) + cst_new;

%%% compute the predicte and achieved descents (descent = positive)
S_Phi_curr =  sum(Phi_bar) + cst(i_curr);
if(norm(Phi_bar - Phi(i_curr, :)) > epsilon)
    fprintf('KO!!!\n');
    norm(Phi_bar - Phi(i_curr, :))
end
achieved = S_Phi_curr - S_Phi_new;
predicted = S_Phi_curr - Phi_predicted;

% stopping condition
if predicted < -eps
    stop = true;
    u_new = u_curr;
    i_new = i_curr;
else
    stop = false;
    % Check if we take a serious step or not
    ratio = achieved/predicted;
    if ratio >= m_L % serious step
        i_new = k+1;
        u_new = max([u_min u_curr/10 2*u_curr*(1-ratio)]); % new step parameter
    else % null step
        i_new = i_curr;
        u_new = min([10*u_curr 2*u_curr*(1-(ratio))]); % new step parameter
    end
end
% Information about the new hyperplane
mu_new = y;
