function [ mu_new, lambda_new, stop, u_new] = bundle(mu, Phi, g, u, paths2fix, c)
%bundle Computes the new dual iterate using aggregate bundle quadratic method

% Global variables from the main program
global ids
global requests
global network
global ordering
global path_ids

% Get some useful data
B = size(mu,1);
T = size(mu,2);
R = size(Phi,1);
k = size(Phi,2);

% previous multiplier
persistent mu_old
if(k==2)
    mu_old = zeros(size(mu));
end

% active constraints and 
persistent Active
Active_new = ones(k-1,R);
if(k>2)
    Active_new(1:end-1,:) = Active;     
end
Active = Active_new;

% The reduced gradient Psi (used to avoid storing all mu_s)
persistent Psi
Psi_new = zeros(R,k-1);
if(k>2)
    Psi_new(:,1:end-1) = Psi;
    for r=1:R
        Psi_new(r,end) = Phi(r,end)+sum(dot(g(:,:,r,end),(mu-mu_old)));
    end
else
    for r=1:R
        Psi_new(r,end) = Phi(r,k-1)+sum(dot(g(:,:,r,k-1),(mu-mu_old)));
    end 
end
Psi = Psi_new;

% Parameters
m_L = 0.4; % in (0,0.5) for taking serious steps
u_min = 0.001; % minimal value for u

% Solve the quadratic problem
[mu_computed, objval, lambda_new] = bundlequadprog(mu, Psi, Active, g, u);

% get the achieved and the predicted descent
[Phi_achieved,~,~,~] = ...
    MexSeqSP(ids, requests, network, ordering, path_ids, reshape(mu_computed,[B T]), paths2fix, c);
Phi_predicted = (objval - 0.5*u*norm(mu_computed-reshape(mu,size(mu_computed)),2));
achieved = sum(Phi(:,k)) - sum(Phi_achieved);
predicted = sum(Phi(:,k)) - Phi_predicted;
% stopping condition
if predicted <= 0.001 && k>2
    stop = true;
    mu_new = mu;
    u_new = u;
    return;
else
    stop = false;
end

% Check if we should take a serious step
ratio = achieved/predicted;
if ratio >= m_L || k == 2% serious step
    % update the multipliers
    mu_new = reshape(mu_computed, [B,T]);
    mu_old = mu_new;
    % update the step size
    u_new = max([u_min u/10 2*u*(1-ratio)]);
else % null step
    % same multipliers and step size
    mu_new = mu; 
    u_new = min([10*u 2*u*(1-ratio)]);
end

% update the active set
for r=1:R
    for l=1:k-1
        if(lambda_new(l,r) ~= 0)
            Active(l,r) = 1;
        else
            Active(l,r) = 0;
        end
    end
end
