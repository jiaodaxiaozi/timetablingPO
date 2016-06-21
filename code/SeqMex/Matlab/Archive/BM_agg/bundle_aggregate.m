function [mu_new, u_new, stop, SPs_id, i_new, Phi_new, g_new] = ...
    bundle_aggregate(k,paths2fix, c, mu, Phi, g, u_curr, i_curr, Restricted)   
%bundle Computes the new dual iterate using aggregate bundle quadratic method

% global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

global capCons

% Parameters
m_L = 0.1; % step quality parameter
u_min = 10^-10; % minimal value for the step size

persistent Active
if(k==1)
    Active = ones(k,1);
else
    tmp = ones(k,1);
    tmp(1:end-1, 1) = Active;
    Active = tmp;
end


% active constraints
[Phi_bar, Active] = predict_aggregate(k, mu(:,:,i_curr), Phi, g, mu, Active); 
    
% Solve the quadratic problem and get the predicted dual value
[y, Phi_predicted, ~] = bundlequadprog_aggregate(mu, Phi, Active, g, u_curr, i_curr);

if(~Restricted && abs(Phi_bar - Phi(i_curr)) > eps)
    fprintf('KO Phi_bar is diff than Phi!\n');
    Phi_bar - Phi(i_curr)
end
% get the achieved dual value
if(Restricted)
    [totalRev, cap_cons, SPs_id, Phi_SP] = ...
        SP_RMLP(capCons, y, paths2fix, c);        
else
[totalRev, cap_cons, SPs_id, Phi_SP] = ...
        mexSeqSP(network, graphs, genPaths, y);    
end
[Phi_new, g_new] = compute_phi_g(totalRev, cap_cons, y, Phi_SP);

%%% compute the predicte and achieved descents (descent = positive)
achieved = Phi_bar - Phi_new
predicted = Phi_bar - Phi_predicted

% stopping condition
if predicted < eps
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
    else
        i_new = i_curr;
        u_new = min([10*u_curr 2*u_curr*(1-(ratio))]); % new step parameter
    end
end
% Information about the new hyperplane
mu_new = y;
