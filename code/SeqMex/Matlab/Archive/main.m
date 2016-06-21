%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Main program: TTP using Lagrangian Relaxation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
DEBUG = 1;

% maximal number of generated paths per request
global P
P = 10;

%%% Global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

% Matlab data
global R
global T
global B
global Cap
global mu
global Revenues


%%% Read the network data (OBS. specify the absolute path with "/")
if DEBUG
    disp('---> Reading Network Data ...');
end
%[ids, stations, requests, network, ordering, path_ids, P, R, T, B, Cap, Rev] = ...
 [network, graphs, R, Cap, T, genPaths] = mexReadData('C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test.csv'); 
B = size(Cap, 1);

% nr of fractional variables n (i.e. number of possible paths)
n = P*R;

% l and u are initially just zeros and ones which mean no variables are fixed yet
l = zeros(n,1);
u = ones(n,1);

% Bundle method without perturbations or restrictions
if DEBUG
    disp('---> Bundle Phase - Paths Generation ...');
end
x = RMLP(zeros(R, P),l,u);

% get the generated paths
[Timetables, Revenues, capCons] = mexPaths(genPaths);

% the revenues of the generated paths
V = Revenues(:);

%checking if integer infeasibilities exist
inf = find((x > eps) & (x < 1 - eps));
n_i = 1-isempty(inf);

%loop until no integer infeasibilitys remain
if DEBUG
    disp('---> Rapid Branching Phase - Feasibility ...');
end
while n_i == true;
    if DEBUG
        disp('-- GeneratePotentialFixings ...');
    end
    [B_star,x_0] = GeneratePotentialFixings(l,u,V);
    if DEBUG
        disp('-- ApplyFixings ...');
    end
    [l,u,n_i] = ApplyFixings(B_star,l,u,x_0,V,double(capCons),mu,n);
end

% if bundle phase found a
if(inf)
   feasible = find((x > 1-eps));
   l(feasible) = 1;
else
   l = x;
end

% get the final results
[rev, timetable] = getOptimal(l,Timetables);
DrawTimetable(timetable);