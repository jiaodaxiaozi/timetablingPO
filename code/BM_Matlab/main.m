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
[ids, requests, network, ordering, path_ids, P, R, T, B, Cap] = MexReadData('C:/Users/abde/Documents/GitHub/TimetablePO/data');
%[ids, requests, network, ordering, path_ids, P, R, T, B, Cap] = MexReadData('D:/Skola/Exjobb/TimetablePO/data');

%%% Initializing parameters
k_max = 5; % maximum number of iterations
k = 1; % current iteration number

%%% Parameters to store the iteration results
mu = zeros(B,T,k_max+1);% mu(:,:,1) = rand(B,T);% prices initially random
Phi = zeros(R,k_max); % dual objective function
g = zeros(B,T,R,k_max); % sub-gradient of the dual obj function
lambda = zeros(k_max,R); % multiplier for the convex combinations of paths
Path = zeros(R,k_max); % store index of the path which was chosen for each request and at each Bundle iteration
u = ones(1,k_max); % coefficient in front of the quadratic term in Bundle method
capCons = zeros(B,T,R); % capacity consumption of the shortest path


%%% Bundle phase

while (k <= k_max)
    
    %%% Solve the shortes path (C++ function)
   [Phi(:,k), g(:,:,:,k), Path(:,k), capCons] = ...
        MexSeqSP(ids, requests, network, ordering, path_ids, mu(:,:,k));
    
    %%% Compute the new prices (Matlab function)
    [mu(:,:,k+1), lambda(1:k,:), stop, serious, u(k+1)] = ...
        bundle(mu(:,:,1:k), Phi(:,1:k), g(:,:,:,1:k), u(k));
    
    % stop or next iteration if the step is serious
    if serious
        k = k+1;
    elseif stop
        break;    
    end
    
    % draw the timetable
    DrawTimetable(capCons);
end

% Constructs the fractional solution
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

return;


%%%%%%%% Data needed
%
% - (done) capCons(b,t,r)       is a multidimensional matrix with capacity consumption
% for each request
% - (done) Cap(b)               is the capacity of each space block



%%% Branch & Bound phase

%checking if integer infeasibilities exist
int_tol = 10^-6;
n_i = false;

for s = x;
    for t = s';
        if (t >= int_tol) && (t <= 1 - int_tol);
            n_i = true;
            break
        end
    end
    if n_i == true;
        break
    end
end

%Inequality constraints A*x = b, capacity constraints
A = zeros(T*B,numel(x));
for i = 1:numel(x);
    A(:,i) = D{i};
end

b = ones(T*B,1) %Add capacities that are larger then one

%Equality constraints Aeq*x = beq, one path per train constraints
Aeq = zeros(R,numel(x));
counter = 0;
for i = 1:R;
    Aeq(i,1 + counter:P(i) + counter) = 1;
    counter = counter + P(i);
end

beq = ones(R,1);


%Loop until integer solution is found
l = sparse(zeros(size(x))); u = ones(size(x));%initially no variables are fixed
MU = mu(:,:,end); %last multipliers from intitial bundle phase
x_0 = x; %the best solution from the bundle phase
while n_i == true;    
    B_star = GeneratePotentialFixings(l,u,V,A,b,Aeq,beq);
    [x_0,l,u,n_i] = ApplyFixings(l,u,x_0,V,A,b,Aeq,beq,B_star,MU,R);
end

%%% Results
