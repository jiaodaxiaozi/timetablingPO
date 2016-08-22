%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Main program: TTP using Lagrangian Relaxation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
global DEBUG
DEBUG = 1;
% maximal number of generated paths per request
global MAX_Pr
MAX_Pr = 10;

%%% Global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network

% Matlab data
global R
global T
global B
global capCons
global Rev
global mu



%%% Read the network data (OBS. specify the absolute path with "/")
if DEBUG
    disp('---> Reading Network Data ...');
end
%[ids, stations, requests, network, ordering, path_ids, P, R, T, B, Cap, Rev] = ...
 [network, graphs, R, B, T, Rev] = ...
    MexReadData('C:/Users/abde/Documents/GitHub/TimetablePO/data/academic/r2_t1_s7'); 
%[ids, requests, network, ordering, path_ids, P, R, T, B, Cap] = MexReadData('D:/Skola/Exjobb/TimetablePO/data');


% nr of fractional variables n (i.e. number of possible paths)
n = MAX_Pr*R;

% Generated paths saved as capacity consumption
capCons = zeros(B,T,n); 

% The lagrange multipliers
mu = zeros(B,T); %  initially random prices

%l and u are initially just zeros and ones which mean no variables are
%fixed yet
l = zeros(n,1);
u = ones(n,1);

return;

% Bundle method without perturbations or restrictions
if DEBUG
    disp('---> Bundle Phase - Paths Generation ...');
end
[x, ~] = RMLP([],l,u);



% get and draw the integer solution
% draw the timetable
DrawTimetable(capCons, x, stations);
% draw the prices
DrawPrices(mu, stations);



%Calculate revenues for all paths
V = GetObjValFromPath(capCons, Rev);

%checking if integer infeasibilities exist
inf = find(( x > eps) & (x < 1 - eps));
n_i = isempty(inf);

%loop until no integer infeasibilitys remain
if DEBUG
    disp('---> Rapid Branching Phase - Feasibility ...');
end
while n_i == true;
    if DEBUG
        disp('-- GeneratePotentialFixings ...');
    end
    [B_star,x_0] = GeneratePotentialFixings(l,u,V, P_min);
    if DEBUG
        disp('-- ApplyFixings ...');
    end
    [l,u,n_i] = ApplyFixings(B_star,l,u,x_0,V,capCons,mu,n);
end

% get and draw the integer solution
% draw the timetable
DrawTimetable(capCons, l, stations);
% draw the prices
DrawPrices(mu, stations);