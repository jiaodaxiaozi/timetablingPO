function [solval, objval, lambda] = bundlequadprog_aggregate(mu, Phi, Active, g, u_curr, i_curr)
% Solves the bundle quadratic problem using the in-built QP Matlab solver

global B
global T

k = size(Active,1);

% Convert the problem to the standard form
% H
ij = (2:(B*T+1))'; ij = double(ij);
val = u_curr*ones(B*T,1);
H = sparse(ij,ij,val);

% f
f = [1; zeros(B*T,1)];

% the current mu
mu_k = mu(:,:,i_curr);

% A and b
A = zeros(k,1+B*T);
b = zeros(k,1);
for l_=1:k
    mu_l = mu(:,:,l_);
    if(Active(l_,1) == 1)
        % matrix A
        A(l_,1) = -1;
        gt = g(:,:,l_);
        A(l_,2:end) = gt(:)';
        % rhs vector b
        b(l_) = -Phi(l_)-gt(:)'*(mu_k(:)-mu_l(:));
    end
end

% lb and ub (bounds)
lb = zeros(1+B*T,1);
lb(1,1) = -inf; 
lb(2:end,1) = -mu_k(:);
ub = +inf(1+B*T,1);

% No equality constraints
Aeq = [];
beq = [];

% Solve the quadratic problem (Sol = [y|mu_new]')
options = optimoptions(@quadprog,'Algorithm','interior-point-convex', 'Display', 'off');
[xval, ~, ~, ~, lambda_struct] = quadprog(H,f,A,b,Aeq,beq,lb,ub,[],options);

% Get objective, mu and lambda
objval = xval(1); % objective value
solval = reshape(xval(2:end),[B T])+mu_k; % new_mu = X + mu, prices (or multipliers)
lambda = reshape(lambda_struct.ineqlin, [k 1]); % lagrangian multipliers