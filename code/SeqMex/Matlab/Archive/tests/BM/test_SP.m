%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Main program: TTP using Lagrangian Relaxation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
DEBUG = 1;

% maximal number of generated paths per request
global P
P = 8;

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


mu = rand(B,T);
mu(2,11:15) = 0;
paths2fix = GetFixingFromBounds(l,u);
[dualObj, cap_cons, SPs_id(:,1)] = ...
        mexSeqSP(network, graphs, mu, paths2fix, zeros(R, P), genPaths);
    
mu(2,11:15) = 10000;    
[dualObj1, cap_cons1, SPs_id(:,2)] = ...
        mexSeqSP(network, graphs, mu, paths2fix, zeros(R, P), genPaths);


mu(8,11:15) = 100000;    
[dualObj3, cap_cons3, SPs_id(:,3)] = ...
        mexSeqSP(network, graphs, mu, paths2fix, zeros(R, P), genPaths);    
    
% get the generated paths
[Timetables, Revenues, capCons] = mexPaths(genPaths);

% the revenues of the generated paths
V = Revenues(:);

%%% different paths per request
for r=1:R
   DrawTimetable(Timetables(:,:,:,r)) 
end

%%% the prices
DrawPrices(mu);


