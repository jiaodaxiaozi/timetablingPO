%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Main program: TTP using Lagrangian Relaxation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   Obs. Before running this code, please make sure
%%%   that the mex-files were generated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%% Global param
global ids
global requests
global network
global ordering
global path_ids

%%% Read the network data (OBS. specify the absolute path with "/")
[ids, requests, network, ordering, path_ids, P, R, T, B] = MexReadData('C:/Users/abde/Documents/GitHub/TimetablePO/data');
%[ids, requests, network, ordering, path_ids, P, R, T, B] = MexReadData('D:/Skola/Exjobb/TimetablePO/data');

%%% Initializing parameters
k_max = 5; % maximum number of iterations
k = 1; % current iteration number
%B = 12; % number of spatial blocks
%T = 24*60*2; % number of time step 
%R = 5; % number of requests

%%% Parameters to store the iteration results
mu = zeros(B,T,k_max+1);% mu(:,:,1) = rand(B,T);% prices initially random
Phi = zeros(R,k_max); % dual objective function
g = zeros(B,T,R,k_max); % sub-gradient of the dual obj function
lambda = zeros(k_max,R); % multiplier for the convex combinations of paths
Path = zeros(R,k_max); % store index of the path which was chosen for a request at certain iteration
u = ones(1,k_max); % coefficient in front of the quadratic term in Bundle method


%%% Dual iteration
while (k <= k_max)
    
    %%% Solve the shortes path (C++)
    [Phi(:,k), g(:,:,:,k), Path(:,k)] = ...
        MexSeqSP(ids, requests, network, ordering, path_ids, mu(:,:,k));
    
    %%% Compute the new prices (Matlab)
    [mu(:,:,k+1), lambda(1:k,:), stop, serious, u(k+1)] = ...
        bundle(mu(:,:,1:k), Phi(:,1:k), g(:,:,:,1:k), u(k));
    
    % stop or next iteration if the step is serious
    if serious
        k = k+1;
    elseif stop
        break;    
    end
end

x = zeros(max(P),R); %% main binary variable of the IP problem
for r=1:R % train requests
    for p=1:P(r) % paths
        sum = 0; % approximation of x(p_r)
        for k=1:k_max
           if Path(r,k) == p
              sum = sum + lambda(k,r);
           end
        end
        x(p,r) = sum;
    end
end
sparse(x);
% data needed
% D is a cell where element d_r,p is capacity consumption

x;
break;

%%% Rapid Branching

%checking number of integer infeasibilities
n_i = 0;
for s = x'
    s = cell2mat(s); %% !!!! s is reused
    for t = s';
        if t ~= 0 && t ~= 1;
            n_i = n_i + 1;
        end
    end
end

%Loop until integer solution is found
l = sparse(zeros(size(x))); u = ones(size(x));%initially no variables are fixed
MU = mu(:,:,end); %last multipliers from intitial bundle phase
x_root = x; %the best solution from the bundle phase
while n_i >= 1
    
    [x_best,B_star] = GeneratePotentialFixings(l,u,x,D,V);
    [x,x_root,l,u,n_i] = ApplyFixings(l,u,x_best,x_root,D,V,B_star,MU,R);
end

%%% Results
