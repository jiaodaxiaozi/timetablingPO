%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Bundle Method
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
global DEBUG
DEBUG = 1;

% maximal number of generated paths per request
global P_g
P_g = 20;

%%% Global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths

% global data
global Cap % the capacity of each block
global R_g % the number of train requests
global T_g % time slots
global B_g % number of blocks

global Phi_g
global SPs_id
global i

global K


%%% Read the network data (OBS. specify the absolute path with "/")
if DEBUG
    disp('---> Reading Network Data ...');
end
[network, graphs, R_g, Cap, T_g, genPaths] = mexReadData('C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test.csv');
B_g = size(Cap, 1); 

% The total number of generated path (for all requests)
n = P_g*R_g;

% variables for fixing paths (initially, no fixings)
l = zeros(n,1); u = ones(n,1);

% Bundle method without perturbations or restrictions
if DEBUG
    disp('---> Bundle Phase - Paths Generation ...');
end
x = RMLP(zeros(R_g, P_g),l,u);

% get the generated paths
[Timetables, Revenues, capCons] = mexPaths(genPaths);

%%% PHI & REVENUES PER ITERATION
figure();
sum_rev = zeros(1,K);
for k=1:K
    for r=1:R_g
        sum_rev(k) = sum_rev(k) + Revenues(SPs_id(r,k),r);         
    end
end

plot(1:K, sum(Phi_g(i(1:K),:),2), 'LineWidth',2);
ylabel('value')
xlabel('iteration')
title('Dual objective value - Phi')

%%% different paths per request
for r=1:R_g
   DrawTimetable(Timetables(:,:,:,r)) 
end