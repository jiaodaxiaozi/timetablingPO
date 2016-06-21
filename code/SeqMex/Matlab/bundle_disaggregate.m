function [mu_new, u_new, stop, SPs_id, i_new, Phi_new, g_new, cst_new, capCons_opt] = ...
    bundle_disaggregate(k, paths2fix, c, mu, Phi, g, u_curr, i_curr, cst, Restricted, ...
    Cap, network, graphs, genPaths, capcons)
%bundle Computes the new dual iterate using aggregate bundle quadratic method

R = size(Phi,2);

% Parameters
m_L = 0.1; % step quality parameter
u_min = 10^-10; % minimal value for the step size

persistent Active
if(k==1)
    Active = ones(k,R);
else
    tmp = ones(k,R);
    %tmp(1:end-1, :) = Active;
    Active = tmp;
end


% active constraints
[Phi_bar, Active] = predict_disaggregate(k, mu(:,:,i_curr), Phi, g, mu, Active);
Active = ones(k+1,R);
% Solve the quadratic problem and get the predicted dual value
[y, Phi_predicted, ~] = bundlequadprog_disaggregate(mu, Phi, Active, g, u_curr, i_curr, Cap);

% get the achieved dual value
if(Restricted)
%     [totalRev, cap_cons, SPs_id, Phi_SP] = ...
%         SP_RMLP(capCons, y, paths2fix, c);
else
    [totalRev, cap_cons, SPs_id, Phi_SP] = ...
        mexSeqSP(network, graphs, genPaths, y);
end
[Phi_new, g_new, cst_new] = compute_phi_g_dis(totalRev, cap_cons, y, Phi_SP, Cap);
S_Phi_new = sum(Phi_new) + cst_new;

%%% compute the predicted and achieved descents (descent = positive)
S_Phi_curr =  sum(Phi_bar) + cst(i_curr);
if(norm(Phi_bar - Phi(i_curr, :)) > 10^-13)
    fprintf('KO!!! %f\n', norm(Phi_bar - Phi(i_curr, :)));
end
S_PHI = sum(Phi(i_curr, :)) + cst(i_curr);
achieved = S_PHI - S_Phi_new;
predicted = S_PHI - Phi_predicted;

% stopping condition
if predicted < 10^-13
    predicted
    stop = true;
    u_new = u_curr;
    i_new = i_curr;
    capCons_opt =  capcons;
else
    stop = false;
    % Check if we take a serious step or not
    ratio = achieved/predicted;
    if ratio >= m_L % serious step
        i_new = k+1;
        u_new = max([u_min u_curr/10 2*u_curr*(1-ratio)]); % new step parameter
        capCons_opt = cap_cons;
    else % null step
        i_new = i_curr;
        u_new = min([10*u_curr 2*u_curr*(1-(ratio))]); % new step parameter
        capCons_opt = cap_cons;
    end
end
% Information about the new hyperplane
mu_new = y;
