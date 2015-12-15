%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Main program: TTP using Lagrangian Relaxation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global param
global ids
global requests
global network
global ordering
global path_ids
global R
global T
global B
global P
global stations

%%% Read the network data (OBS. specify the absolute path with "/")
[ids, stations, requests, network, ordering, path_ids, P, R, T, B, Cap, Rev] = ...
    MexReadData('C:/Users/abde/Documents/GitHub/TimetablePO/data/academic/r10_t2_s10'); 
%[ids, requests, network, ordering, path_ids, P, R, T, B, Cap] = MexReadData('D:/Skola/Exjobb/TimetablePO/data');

%nr of fractional variables n (i.e. number of possible paths)
n = sum(P(:));

%l and u are initially just zeros and ones which mean no variables are
%fixed yet
l = zeros(n,1);
u = ones(n,1);

% Bundle method without restrictions
[x, ~] = RMLP([],l,u,[]);

return;
%TODO;
%Capacity consumptions of paths
%MU multipliers from BundlePhase
%Calculate revenues function
%Total number of requests R in strongbranching and applyfixings

%Calculate revenues for all paths
V = Rev;

%checking if integer infeasibilities exist
int_tol = 10^-6;
n_i = false;

for s = x;
    if (s >= int_tol) && (s <= 1 - int_tol);
        n_i = true;
        break
    end
end


%loop until no integer infeasibilitys remain
while n_i == true;
    [B_star,x_0] = GeneratePotentialFixings(l,u,V);
    [l,u,n_i] = ApplyFixings(B_star,l,u,x_0,V,Capacity_Consumptions_Of_Paths,Last_MU_Multipliers_BundlePhase_For_BlockTimes);
end


%return integer vector x (or the elements in l-vector that is one).
