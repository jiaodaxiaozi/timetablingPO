function [solval, objval, lambda] = bundlequadprog_disaggregate(mu, Phi, Active, g, u_curr, i_curr, Cap)
% Solves the bundle quadratic problem using the in-built QP Matlab solver

B = size(mu, 1);
T = size(mu, 2);
R = size(Phi, 2);


k = size(Active,1);
mu_k = mu(:,:,i_curr);

% Convert the problem to the standard form
% H
ij = (R+1:(B*T+R))'; ij = double(ij);
val = u_curr*ones(B*T,1);
H = sparse(ij,ij,val);

% f
c = zeros(B,T);
for b=1:B
   c(b,:) = Cap(b);
end
f = [ones(R,1); c(:)];

% A and b
A = zeros(k*R,R+B*T);
b = zeros(k*R,1);
for l_=1:k
    for r=1:R
        mu_l = mu(:,:,l_);
        if(Active(l_,r) == 1)
            % matrix A
            A((r-1)*k+l_,r) = -1;
            gt = g(:,:,r,l_);
            A((r-1)*k+l_,(R+1):end) = gt(:)';
            % rhs vector b
            b((r-1)*k+l_) = -Phi(l_,r)-gt(:)'*(mu_k(:)-mu_l(:));
        end
    end
end

% lb and ub (bounds)
lb = zeros(R+B*T,1);
lb(1:R,1) = -inf;
lb((R+1):end,1) = -mu_k(:);
ub = [];

% No equality constraints
Aeq = [];
beq = [];

% Solve the quadratic problem (Sol = [y|mu_new]')
options = optimoptions(@quadprog,'Algorithm','interior-point-convex', 'Display', 'off');
[xval, ~, ~, ~, lambda_struct] = quadprog(H,f,A,b,Aeq,beq,lb,ub,[],options);

% Get objective, mu and lambda
solval = reshape(xval((R+1):end),[B T])+mu_k; % new_mu = X + mu, prices (or multipliers)
objval = sum(xval(1:R))+c(:)'*solval(:); % objective value
lambda = reshape(lambda_struct.ineqlin, [k R]); % lagrangian multipliers