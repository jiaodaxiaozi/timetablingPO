function [solval, objval, lambda] = bundlequadprog_aggregate(mu, Psi, Active, g, u)
% Solves the bundle quadratic problem using the in-built QP Matlab solver

% Get some useful data
B = size(mu,1);
T = size(mu,2);

R = size(g,3);

k = size(Active,1);

% Convert the problem to the standard form
% H
ij = (R+1:B*T+R)'; v = u*ones(B*T,1);
H = sparse(ij,ij,v);

% f
f = [ones(R,1); zeros(B*T,1)]; 
sparse(f);

% A and b
A = zeros(R*k,R+B*T);
b = zeros(k*R,1);
for r=1:R
    % matrix A
    for l=1:k
        if(Active(l,r) == 1)
            A((r-1)*k+l,r) = -1;
            tempA = g(:,:,r,l);
            A((r-1)*k+l,(R+1):end) = tempA(:)';
        end
           % rhs vector b
        if(Active(l,r) == 1)
            b((r-1)*k+l) = -Psi(l,r);
        end 
    end
end

% lb and ub (bounds)
lb = zeros(R+B*T,1);
lb(1:R,1) = -inf; 
lb((R+1):end,1) = -mu(:);
ub = [];

% No equality constraints
Aeq = [];
beq = [];

% Solve the quadratic problem (Sol = [y|mu_new]')
options = optimoptions(@quadprog,'Algorithm','interior-point-convex', 'Display', 'off');
[xval, ~, ~, ~, lambda_struct] = quadprog(H,f,A,b,Aeq,beq,lb,ub,[],options);

% Get objective, mu and lambda
objval = xval(1); % objective value
solval = reshape(xval((R+1):end),[B T])+mu; % new_mu = X + mu, prices (or multipliers)
lambda = reshape(lambda_struct.ineqlin, [k R]); % lagrangian multipliers