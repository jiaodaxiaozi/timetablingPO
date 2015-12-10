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

%checking number of integer infeasibilities
n_ii = 0;
for x_i = x';
    if x_i ~= 0 && x_i ~= 1;
        n_ii = n_ii + 1;
    end
end


%Variable to check things work k
k = 0;
%loop until no integer infeasibilitys remain
while n_ii >= 1 && k ~= 50;
    B_star = GeneratePotentialFixings(l,u,x);
    [l,u] = ApplyFixings(B_star,l,u);
    k = k + 1;
end


%return integer vector x
