function [stop, serious] = BM(k, k_max, epsilon, mu_init, u_init)
%bundle Computes the new dual iterate using aggregate bundle quadratic method

% Matlab fixed parameters (data sizes)
global T
T = size(mu_init, 2);
global B
B = size(mu_init, 1);

% Matlab global variables
global mu % prices
global u % step size
global Phi % objective value
global g % subgradien

serious = 0;

% Iteration parameters
m_L = 0.3; % in (0,0.5) for taking serious steps
u_min = 0.05; % minimal value for u

if(k==1)
    Phi = zeros(k_max,1);
    g = zeros(B,T,1,k_max);
    %%% initialize the prices and the step parameter
    u = u_init;
    mu = mu_init;
    %%% Solve the shortes path (C++ function)
    [Phi(k), g(:,:,1,k)] = oracle(mu);
end


global i
if(k==1)
    i = ones(k_max,1);
end


% previous multiplier
persistent mu_prev
if(k==1)
    mu_prev = mu;
end

% active constraints
persistent Active
Active_new = ones(k,1);
if(k>1)
    Active_new(1:end-1,1) = Active;
end
Active = Active_new;

% The reduced gradient Psi (used to avoid storing all mu_s)
persistent Psi
Psi_new = zeros(1,k);
if(k>1)
    Psi_new(1,1:end-1) = Psi;
end
Psi_new(1,k) = Phi(k)+sum(dot(g(:,:,1,k),(mu-mu_prev)));
Psi = Psi_new;


% Solve the quadratic problem
[y, Phi_predicted, lambda] = bundlequadprog_aggregate(mu, Psi, Active, g, u(k));

% get the achieved and the predicted descent
[Phi(k+1), g(:,:,:,k+1)] = oracle(y);

%%% compute the descents (positive -> descent)
achieved = Phi(i(k)) - Phi(k+1);
predicted = Phi(i(k)) - Phi_predicted;

% stopping condition
if predicted < -epsilon
    stop = true;
    return;
else
    stop = false;
end

% Check if we take a serious step
ratio = achieved/predicted;
if ratio >= m_L % serious step
    % update the multipliers
    mu = y;
    % update the iterate
    mu_prev = y;
    i(k+1) = k+1;
    serious = 1;
    % update the step size parameter
    u(k+1) = max([u_min u(k)/10 2*u(k)*(1-ratio)]);
else % null step
    % update the iterate
    mu_prev = y;
    i(k+1) = i(k);
    % update the step size parameter
    u(k+1) = min([10*u(k) 2*u(k)*(1-ratio)]);
end

% update the set of active constraints for the next call
for r=1:1
    for l=1:k
        if(lambda(l,r) > epsilon)
            Active(l,r) = 1;
        else
            Active(l,r) = 0;
        end
    end
end
