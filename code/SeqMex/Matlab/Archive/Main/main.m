%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Main program: TTP using Lagrangian Relaxation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
global DEBUG 
DEBUG = 1;
global PLOT
PLOT = 0;

% maximal number of generated paths per request
global P
P = 20;

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
global Revenues
global capCons
global V

global mu_final

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
x = BM();

% random generation of paths
for i=1:30
    [~,~,~,~] = ...
        mexSeqSP(network, graphs, genPaths, mu_final+mu_final.*(2*rand(B,T)-0.5));
end


% get the generated paths
[Timetables, Revenues, capCons] = mexPaths(genPaths, P);

V = Revenues;

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
    [B_star,x_0] = GeneratePotentialFixings(l,u);
    
    if DEBUG
        disp('-- ApplyFixings ...');
    end
    [l,u,n_i] = ApplyFixings(B_star,l,u,x_0,mu_final,n);
end

% get the final results
% timetable
[rev, timetable] = getOptimal(l,Timetables);
figure();
DrawTimetable(timetable);
% capcons
l = reshape(l, [P R]);
sumCapCons = zeros(B,T);
for r=1:R
    id = find(l(:,r)==1);
    sumCapCons = sumCapCons + double(capCons(:,:,id,r));    
end
figure();
DrawPrices(sumCapCons);
% prices
figure();
DrawPrices(mu_final);