%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Phi Convexity 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
global DEBUG
DEBUG = 1;

global PLOT
PLOT = 1;

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

%%% Test set
N_tests = 8;
filename = cell(N_tests, 1);
filename{1,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_2.csv';
filename{2,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_4.csv';
filename{3,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AE_20.csv';
filename{4,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_RGN_4.csv';
filename{5,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_AK_8.csv';
filename{6,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/KMB_AK_8.csv';
filename{7,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/malmbanan_4.csv';
filename{8,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/malmbanan_26.csv';



for t=1:N_tests-4
    
    %%% Read the network data (OBS. specify the absolute path with "/")
    if DEBUG
        disp('---> Reading Network Data ...');
    end
    [network, graphs, R, Cap, T, genPaths] = ...
        mexReadData(filename{t,1});
    B = size(Cap, 1);
    
    % maximal number of generated paths per request
    P = 100;
    n = P*R;
    
    % mu_0
    mu_0 = zeros(B,T);
    [totalRev0, cap_cons0, SPs_id_0, Phi_SP0] = ...
        mexSeqSP(network, graphs, genPaths, mu_0);
    % compute the objective value
    [Phi_0, g_0] = compute_phi_g(totalRev0, cap_cons0, mu_0, Phi_SP0);
    
    % Testing the convexity
    max_tests = 20;
    epsilon = 0.0000000001;
    for i=0:max_tests
        fprintf('---> Convexity Test %d\n', i);
        % generate a random point
        mu = 10*rand(B,T);
        % call SP
        [totalRev, cap_cons, SPs_id, Phi_SP] = ...
            mexSeqSP(network, graphs, genPaths, mu);
        % compute the objective value
        [Phi, g] = compute_phi_g(totalRev, cap_cons, mu, Phi_SP);
        % compute the approximation at mu_0
        Phi_app = Phi_0+g_0(:)'*(mu(:)-mu_0(:));
        % test if the result is convex
        if(Phi_app - Phi > epsilon)
            Phi_app - Phi
            fprintf('KOOOO!\n');
        else
            fprintf('OK :)\n');
        end
        % save mu as the next mu_0
        mu_0 = mu;
        Phi_0 = Phi;
        g_0 = g;
        SPs_id_0 = SPs_id;
        totalRev0 = totalRev;
        cap_cons0 = cap_cons;
        Phi_SP0 = Phi_SP;
    end
    
end

