%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Bundle Method (BM)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
global DEBUG
DEBUG = 1;

%%% Global variables
% C++ Pointers (insignificant here in Matlab)
global graphs
global network
global genPaths


%%% global parameters
global B
global T
global R
global P
global Cap
global Revenues

%%% Read the network data (OBS. specify the absolute path with "/")
if DEBUG
    disp('---> Reading Network Data ...');
end
T = 2; 
B = 4; 

% maximal number of generated paths per request
P = 20;

% maximal number of generated paths (for all requests)
n = P*R;

% variables for fixing paths (in BM, no fixings)
l = zeros(n,1); u = ones(n,1);

% Bundle method without perturbations or restrictions
if DEBUG
    disp('---> Bundle Phase - Paths Generation ...');
end
x = RMLP(zeros(R, P),l,u);
