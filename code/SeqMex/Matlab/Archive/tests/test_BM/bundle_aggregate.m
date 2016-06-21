function [mu_new, u_new, stop, SPs_id, i_new, Phi_new, g_new] = ...
    bundle_aggregate(k, paths2fix, c, mu, Phi, g, u_curr, i_curr)   
%bundle Computes the new dual iterate using aggregate bundle quadratic method
global R

% global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

% Parameters
m_L = 0.3; % step quality parameter
u_min = 0.005; % minimal value for the step size
epsilon = 10^-4; % for test of positivity


% active constraints
persistent Active
if(k==1)
    Active = ones(k,1);
end

% Solve the quadratic problem and get the predicted dual value
[y, Phi_predicted, lambda] = bundlequadprog_aggregate(mu, Phi, Active, g, u_curr, i_curr);
[Phi_bar_mu_k] = predict_aggregate(mu(:,:,i_curr), Phi, Active, g, mu);


% get the achieved dual value
[Phi_new, g_new] = compute_phi_g(y);
Phi_new = double(Phi_new); % converting to double

%%% compute the predicte and achieved descents (descent = positive)
achieved = Phi(i_curr) - Phi_new;
predicted = Phi(i_curr) - Phi_predicted;

% stopping condition
if predicted < epsilon
    stop = true;
    mu_new = mu(:,:,i_curr);
    u_new = u_curr;
    i_new = i_curr;
else
    stop = false;
    % update the active constraints
    Active = ones(k+1,1);
     for l_=1:k
         if(lambda(l_,1) < epsilon)
             Active(l_,1) = 0;
         end 
     end
    % Check if we take a serious step or not
    ratio = achieved/predicted;
    if ratio >= m_L % serious step
        i_new = k+1;
        u_new = max([u_min u_curr/10 2*u_curr*(1-ratio)]); % new step parameter
        mu_new = y;
    else % null step
        i_new = i_curr;
        u_new = min([10*u_curr 2*u_curr*(1-(ratio))]); % new step parameter
%        u_new = u_curr;
        mu_new = y; % prices to use in the newly generated hyperplanes 
    end 
end
SPs_id = zeros(R,1);
