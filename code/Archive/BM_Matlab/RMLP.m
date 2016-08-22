%Restricted master LP; 
% RMLP(c,l,u,P) 
function [x, obj] = RMLP(c,lb,ub)

%%% Global constantes
% show or unshow the debugging messages
global DEBUG
DEBUG = 1;

% maximal number of generated paths per request
global MAX_Pr
MAX_Pr = 10;

% global variables
% C++ Pointers (insignificant here in Matlab)
global graphs

% Matlab data
global R
global T
global B
global Rev
global mu

%%% Initializing parameters
k_max = 10; % maximum number of iterations
k = 1; % firsr iteration
stop = false; % variable to stop the algorithm

%%% Parameters to store the iteration results
Phi = zeros(R,k_max); % dual objective function
g = zeros(B,T,R,k_max); % sub-gradient of the dual obj function
lambda = zeros(k_max,R); % multiplier for the convex combinations of paths
SPs_id = zeros(R,k_max); % store index of the path which was chosen for each request and at each Bundle iteration
u = 0.01*ones(1,k_max); % coefficient in front of the quadratic term in Bundle method

%%% Compute the paths to fix to one for each request
lb = reshape(lb, [MAX_Pr R]);
ub = reshape(ub, [MAX_Pr R]);
paths2fix = GetFixingFromBounds(lb,ub);

%%% get some initial approximation
% display iteration number
if DEBUG
    fprintf('Bundle: init ... \n');
end
[Phi(:,k), g(:,:,:,k), SPs_id(:,k)] = ...
        MexSeqSP(graphs, mu, paths2fix, c);

%%% Bundle phase
while ((~stop) && (k <= k_max))
    
    % display iteration number
    if DEBUG
       fprintf('Bundle: iteration %d ... \n',k);
    end
    
    % next iteration if the step is serious
    k = k+1;
    
    %%% Solve the shortes path (C++ function)
   [Phi(:,k), g(:,:,:,k), SPs_id(:,k)] = ...
        MexSeqSP(graphs, mu, paths2fix, c);
    
    %%% Save the generated path
%     for r=1:R
%         capCons(:,:,SPs_id(r,k)) = Path(:,:,r);
%     end
    
    %%% Compute the new prices (Matlab function)
    [mu, lambda(1:k-1,:), stop, u(k+1)] = ...
        bundle(mu, Phi(:,1:k), g(:,:,:,1:k), u(k), paths2fix, c);
    
end

% Constructs the fractional solution from lambda
x = fract_sol(lambda(1:(k-1),:), SPs_id(:,1:(k-1)), MAX_Pr);
x = x(:);

% Get the objective value of 
ObjVal = GetObjValFromPath(capCons, Rev);

% objective value
obj = sum(ObjVal(:).*x);

end

