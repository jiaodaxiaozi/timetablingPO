function [ mu_new, lambda_new, stop, serious, u_new] = bundle(mu, Phi, g, u)
%bundle Computes the new dual iterate using aggregate bundle quadratic method

% Global variables from the main program
global ids
global requests
global network
global ordering
global path_ids

% Parameters
m_L = 0.3; % in (0,0.5) for taking serious steps
u_min = 0.1; % minimal value for u

% Get some useful data
B = size(mu,1);
T = size(mu,2);
mu_current = mu(:,:,end);

% Solve the quadratic problem
[ mu_computed, objval, lambda_new] = bundlequadprog(mu, Phi, g, u);

% get the achieved and the predicted descent
[Phi_achieved,~,~,~] = ...
    MexSeqSP(ids, requests, network, ordering, path_ids, reshape(mu_computed,[B T]));
Phi_predicted = (objval - 0.5*u*norm(mu_computed-reshape(mu_current,size(mu_computed)),2));
achieved = sum(Phi_achieved) - sum(Phi);
predicted = Phi_predicted  - sum(Phi);
% check the stopping condition
if predicted >= -eps
    stop = true;
    return;
else
    stop = false;
end
% Check if we take a serious step
ratio = achieved/predicted;
if ratio <= m_L
    serious = true;
    mu_new = reshape(mu_computed,[B,T]);
    u_new = max([u_min u/10 2*u*(1-ratio)]);
else
    serious = false;
    mu_new = mu_current;
    u_new = u;    
end