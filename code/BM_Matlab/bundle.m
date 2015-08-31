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
k = size(mu,3);
R = size(Phi,1);
mu_current = mu(:,:,end);

% Define the quadratic problem
ij = (2:B*T+1)'; v = u*ones(B*T,1);
H = sparse(ij,ij,v);
f = [1; -u*mu_current(:)]; sparse(f);
A = [-ones(k*R,1), zeros(k*R,B*T)]; %% add mu >= 0 ?
b = zeros(k*R,1);
for r=1:R
    for j=1:k
        % matrix A
        tempA = g(:,:,r,j);
        A((r-1)*k+j,2:end) = tempA(:)';
        % rhs vector b
        tempb = sum(sum(g(:,:,r,j).*mu(:,:,j)));
        b(j) = tempb - Phi(r,j) - 0.5*u*norm(mu_current,2);
    end
end

% make sparse
sparse(A);
sparse(b);

% Solve the quadratic problem (Sol = [y|mu_new]')
[xval, fval, ~, ~, lambda_struct] = quadprog(H,f,A,b);

% Get the mu and the multipliers
mu_computed = xval(2:end);
lambda_new = lambda_struct.ineqlin;

% get the achieved and the predicted descent
[Phi_achieved, ~,~] = ...
    MexSeqSP(ids, requests, network, ordering, path_ids, reshape(mu_computed,[B T]));
Phi_predicted = (fval - 0.5*u*norm(mu_computed-reshape(mu_current,size(mu_computed)),2));
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

