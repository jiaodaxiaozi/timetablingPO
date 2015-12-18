%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Main program: TTP using Lagrangian Relaxation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global variables
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
global stations
global capCons
global Rev
global mu

%%% Read the network data (OBS. specify the absolute path with "/")
[ids, stations, requests, network, ordering, path_ids, P, R, T, B, Cap, Rev] = ...
    MexReadData('C:/Users/abde/Documents/GitHub/TimetablePO/data/academic/r10_t2_s10'); 
%[ids, requests, network, ordering, path_ids, P, R, T, B, Cap] = MexReadData('D:/Skola/Exjobb/TimetablePO/data');

%nr of fractional variables n (i.e. number of possible paths)
P_min = min(P);
n = P_min*R;

% Generated paths saved as capacity consumption
capCons = zeros(B,T,n); 

% The lagrange multipliers
mu = zeros(B,T); %  initially random prices

%l and u are initially just zeros and ones which mean no variables are
%fixed yet
l = zeros(n,1);
u = ones(n,1);

% Bundle method without perturbations or restrictions
[x, ~] = RMLP([],l,u,P_min);

%TODO;
%Capacity consumptions of paths -ok-> capCons(b,t,n)
%MU multipliers from BundlePhase -ok-> mu
%Calculate revenues function --> Rev(r,4), col1=tmin,...col4=vmax
%Total number of requests R in strongbranching and applyfixings ---> R

%Calculate revenues for all paths
V = GetObjValFromPath(capCons, Rev);

%checking if integer infeasibilities exist
int_tol = 10^-6;
inf = find(( x > int_tol) & (x < 1 - int_tol));
n_i = isempty(inf);

%loop until no integer infeasibilitys remain
while n_i == true;
    [B_star,x_0] = GeneratePotentialFixings(l,u,V, P_min);
    [l,u,n_i] = ApplyFixings(B_star,l,u,x_0,V,capCons,mu,P_min);
end

%return integer vector x
% draw the timetable
%DrawTimetable(capCons, x, stations);
% draw the prices
%DrawPrices(mu, stations);

