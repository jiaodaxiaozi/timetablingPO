function [solval, objval, lambda] = bundlequadprog(mu_k, Psi, g, u_curr, Cap, k)
% Solves the bundle quadratic problem using the in-built QP Matlab solver

%% macro
global DISAGG

%% parameter
B = size(mu_k, 1);
T = size(mu_k, 2);
R = size(Psi, 2);

%% Problem Formulation: convert the problem to the standard form
% H
ij = (R+1:(B*T+R))';    
ij = double(ij);
val = u_curr*ones(B*T,1);
H = sparse(ij,ij,val);

% f
if(DISAGG)
    c = repmat(Cap,1,T);
    f = [ones(R,1); c(:)];
else
    f = [1; zeros(B*T,1)];
end

% A and b
A = zeros(k*R,R+B*T);
b = zeros(k*R,1);
for l_=1:k
    for r=1:R
        % matrix A
        A((r-1)*k+l_,r) = -1;
        if(DISAGG)
            gt = g(:,:,r,l_);
        else
            gt = g(:,:,l_);
        end
        A((r-1)*k+l_,(R+1):end) = gt(:)';
        % rhs vector b
        b((r-1)*k+l_) = -Psi(l_,r);
    end
end
% No equality constraints
Aeq = [];
beq = [];


%% bounds: lb and ub
lb = zeros(R+B*T,1);
lb(1:R,1) = -inf;
lb((R+1):end,1) = -mu_k(:);
ub = [];

%% Solve the quadratic problem (Sol = [y|mu_new]')
options = optimoptions(@quadprog,'Algorithm','interior-point-convex', 'Display', 'off');
[xval, ~, ~, ~, lambda_struct] = quadprog(H,f,A,b,Aeq,beq,lb,ub,[],options);

%% Get solution
solval = reshape(xval((R+1):end),[B T])+mu_k; % new_mu = X + mu, prices (or multipliers)
if(DISAGG)
    objval = sum(xval(1:R))+c(:)'*solval(:); % objective value
else
    objval = xval(1); % objective value
end
lambda = reshape(lambda_struct.ineqlin, [k R]); % lagrangian multipliers