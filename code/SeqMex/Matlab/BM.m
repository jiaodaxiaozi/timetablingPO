%Restricted master LP;
function [x, mu, Phi_it, SPs_id, exec_time] = ...
    BM(Cap, B, T, R, P)
%RMPL  Solve the relaxed problem with given fixings and perturbations

%% macro
global DEBUG
global DISAGG

%% parameters
k_max = 200; % maximum number of iterations
mu = zeros(B, T); % the multipliers (/prices/dual variable)
u = ones(k_max); % step control parameter
stop = false; % initially, no stop
SPs_id = zeros(R, k_max); % the identifiers of shortest path per iteration
cst = zeros(k_max,1);
i = ones(k_max,1); % the iteration number of the latest serious step
Cap = double(Cap); % convert to double
x = zeros(P,R,k_max);
if(DISAGG)
    g = zeros(B,T,R, k_max); % the subgradient per iteration
    Phi = zeros(k_max, R); % the dual objective value per iteration
    Psi = zeros(k_max, R);
else
    g = zeros(B,T,k_max); % the subgradient per iteration
    Psi = zeros(k_max,1);
end


%% initialization of variables
fprintf('BM: init ... \n');
tic % start timing
% Solve the shortes path (C++ function)
[totalRev, cap_cons, SPs_id(:,1), Phi_SP] = ...
    mexSP('compute', mu);
if(DISAGG)
    [Phi(1, :), g(:,:,:,1), cst(1,1)] = ...
        compute_phi_g(totalRev, cap_cons, mu, Phi_SP, Cap);
    Psi(1,:) = Phi(1, :);
else
    [Phi(1, :), g(:,:,1), cst(1,1)] = ...
        compute_phi_g(totalRev, cap_cons, mu, Phi_SP, Cap);
    Psi(1,:) = sum(Phi(1))+cst(1);
end



%% Bundle iteration
k = 0; % init iteration
while ((~stop) && (k+1 < k_max))
    
    % next iteration
    k = k+1;
    
    % display iteration number
    fprintf('BM: iteration %d ... \n',k);
    
    %%% Compute the new prices (Matlab function)
    if(DISAGG)
        [mu, lambda, Psi, u(k+1), stop, SPs_id(:,k+1), i(k+1), Phi(k+1,:), g(:,:,:,k+1), cst(k+1)] = ...
            bundle(k, zeros(R,1), zeros(P,R), mu, Psi(1:k,:), Phi(1:k,:), g(:,:,:,1:k), u(k,1), i(k,1), cst(1:k), false, ...
            Cap);
    else
        [mu, lambda, Psi, u(k+1), stop, SPs_id(:,k+1), i(k+1), Phi(k+1,:), g(:,:,k+1), cst(k+1)] = ...
            bundle(k, zeros(R,1), zeros(P,R), mu, Psi(1:k), Phi(1:k,:), g(:,:,1:k), u(k,1), i(k,1), cst(1:k), false, ...
            Cap);
    end
    
    %%% fractional solution at current iteration
    x(:,:,k) = fract_sol(lambda, SPs_id(:,1:k), P);
end

%% Results
% execution time
exec_time = toc;

% end bundle phase
if DEBUG
    if(k+1 ~= k_max)
        fprintf('BM: optimal solution found after %d iterations!\n', k);
    else
        fprintf('BM: solution found but not optimal!\n');
    end
end

% dual objective
Phi_it = zeros(k+1,1);
for it=1:k+1
    Phi_it(it) = sum(Phi(it,:)) + cst(it);
end
Phi_it = Phi_it(i(2:k+1)); % consider only the best so far

end

