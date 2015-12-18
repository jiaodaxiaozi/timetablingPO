%Restricted master LP; 
% RMLP(c,l,u,P) 
function [x, obj] = RMLP(c,lb,ub,P_max)

% global variables
% C++ Pointers (insignificant here in Matlab)
global ids
global requests
global network
global ordering
global path_ids
% Matlab data
global R
global T
global B
global capCons
global Rev
global mu

%%% Initializing parameters
k_max = 7; % maximum number of iterations
k = 1; % firsr iteration
stop = false; % variable to stop the algorithm

%%% Parameters to store the iteration results
Phi = zeros(R,k_max); % dual objective function
g = zeros(B,T,R,k_max); % sub-gradient of the dual obj function
lambda = zeros(k_max,R); % multiplier for the convex combinations of paths
SPs_id = zeros(R,k_max); % store index of the path which was chosen for each request and at each Bundle iteration
u = ones(1,k_max); % coefficient in front of the quadratic term in Bundle method

%%% Compute the paths to fix to one for each request
lb = reshape(lb, [P_max R]);
ub = reshape(ub, [P_max R]);
paths2fix = GetFixingFromBounds(lb,ub);

%%% Bundle phase
while ((~stop) && (k <= k_max))
        
    %%% Solve the shortes path (C++ function)
   [Phi(:,k), g(:,:,:,k), SPs_id(:,k), Path] = ...
        MexSeqSP(ids, requests, network, ordering, path_ids, mu, paths2fix, c);
    
    %%% Save the generated path
    for r=1:R
        capCons(:,:,SPs_id(r,k)) = Path(:,:,r);
    end
    
    %%% Compute the new prices (Matlab function)
    [mu, lambda(1:k,:), stop, u(k+1)] = ...
        bundle(mu, Phi(:,1:k), g(:,:,:,1:k), u(k), paths2fix, c);
    
    % next iteration if the step is serious
    k = k+1;
end


% Constructs the fractional solution from lambda
x = fract_sol(lambda(1:(k-1),:), SPs_id(:,1:(k-1)), P_max);
x = x(:);

% Get the objective value of 
ObjVal = GetObjValFromPath(capCons, Rev);

% objective value
obj = sum(ObjVal(:).*x);

end

