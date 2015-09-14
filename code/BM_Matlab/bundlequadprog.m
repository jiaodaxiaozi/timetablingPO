function [ solval, objval, lambda] = bundlequadprog(mu, Phi, g, u)
% Solves the bundle quadratic problem using the in-built QP Matlab solver

% Get some useful data
R = size(Phi,1);
B = size(mu,1);
T = size(mu,2);
k = size(mu,3);
mu_current = mu(:,:,end);

% Convert the problem to the standard form
% H
ij = (R+1:B*T+R)'; v = u*ones(B*T,1);
H = sparse(ij,ij,v);
% f
f = [ones(R,1); -u*mu_current(:)]; 
sparse(f);
% A and b
A = sparse(R*k+1,R+B*T);
A(end,R+1:end) = -ones(1,B*T);
b = sparse(k*R+1,1);
for r=1:R
    for j=1:k
        % matrix A
        A((r-1)*k+j,r) = -1;
        tempA = g(:,:,r,j);
        A((r-1)*k+j,R+1:end) = tempA(:)';
        % rhs vector b
        tempb = sum(sum(g(:,:,r,j).*mu(:,:,j)));
        b((r-1)*k+j) = tempb - Phi(r,j) + 0.5*u*norm(mu_current,2);
    end
end

% Solve the quadratic problem (Sol = [y|mu_new]')
[xval, fval, ~, ~, lambda_struct] = quadprog(H,f,A,b);

% Get objective, mu and lambda
objval = fval;
solval = xval(R+1:end);
lambda = reshape(lambda_struct.ineqlin(1:end-1),[k R]);