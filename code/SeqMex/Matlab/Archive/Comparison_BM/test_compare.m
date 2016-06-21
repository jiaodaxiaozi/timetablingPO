%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Disaggregate vs Aggregate BM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
global DEBUG
DEBUG = 1;

global PLOT
PLOT = 0;

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
global mu
global Phi
global i
global K
global cst
global lambda
global SPs_id

%%% Test set
N_tests = 14;
filename = cell(N_tests, 1);
filename{1,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_2.csv';
filename{2,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_2_stop.csv';
filename{3,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_4.csv';
filename{4,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_4_stop.csv';
filename{5,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AE_20.csv';
filename{6,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AE_20_stop.csv';
filename{7,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_AK_4.csv';
filename{8,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_AK_4_stop.csv';
filename{9,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_TNK_8.csv';
filename{10,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_TNK_8_stop.csv';
filename{11,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_10.csv';
filename{12,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_10_stop.csv';
filename{13,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_26.csv';
filename{14,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_26_stop.csv';

%%% Read the network data (OBS. specify the absolute path with "/")
for nt =1:N_tests-4
    if DEBUG
        fprintf('>>> Test case %d  \n', nt);
    end
    % creating result folder
    [~,name,~] = fileparts(filename{nt,1});
    mkdir(name);
    if DEBUG
        disp('--->>>> AGGREGATE ...');        
        disp('---> Reading Network Data ...');
    end
    [network, graphs, R, Cap, T, genPaths] = ...
        mexReadData(filename{nt,1});
    B = size(Cap, 1);
    
    % maximal number of generated paths per request
    P = 50;
    
    % maximal number of generated paths (for all requests)
    n = P*R;
    
    % variables for fixing paths (in BM, no fixings)
    l = zeros(n,1); u = ones(n,1);
    
    % Bundle method without perturbations or restrictions
    if DEBUG
        disp('---> Bundle Phase - Paths Generation ...');
    end
    x_agg = BM_aggregate();
    
    % saving the plots the results    
    % draw optimal prices
    figure(1);
    DrawPrices(mu(:,:,i(K)));
    cd(name);
    saveas(1,'optimal_prices_agg', 'png');
    close all;
    cd ..;
    
    rev = zeros(K,1);
    for k=1:K
        x_k = fract_sol(lambda(1:k,:), SPs_id(:,1:k));
        rev(k) = x_k(:)'*Revenues(:);
    end
    
    if DEBUG
        fprintf('average number of generated paths: %f\n', sum(max(SPs_id(:,1:K), [], 2))/double(R));
    end
    
    %%% PHI & REVENUES PER ITERATION
    % generate fig - Dual
    Phi_agg = sum(Phi(i(1:K),:),2);
    
    % gen fig - Primal relaxed
    Rev_agg = rev(i(1:K),:);
    
    if DEBUG
        disp('--->>>> DISAGGREGATE ...');        
        disp('---> Reading Network Data ...');
    end
    
    % Bundle method without perturbations or restrictions
    if DEBUG
        disp('---> Bundle Phase - Paths Generation ...');
    end
    x_dis = BM_disaggregate();
    
    % saving the plots the results    
    % draw optimal prices
    figure(1);
    DrawPrices(mu(:,:,i(K)));
    cd(name);
    saveas(1,'optimal_prices_disagg', 'png');
    close all;
    cd ..;
    
    rev = zeros(K,1);
    for k=1:K
        x_k = fract_sol(lambda(1:k,:), SPs_id(:,1:k));
        rev(k) = x_k(:)'*Revenues(:);
    end
    
    %%% PHI & REVENUES PER ITERATION
    % generate fig - Dual
    Phi_disagg = sum(Phi(i(1:K),:),2)+cst(i(1:K));
    
    % gen fig - Primal relaxed
    Rev_disagg = rev(i(1:K),:);
    
    if DEBUG
        fprintf('average number of generated paths: %f\n', sum(max(SPs_id(:,1:K), [], 2))/double(R));
    end    
    %%% Both duals (agg vs disagg)
    figure(1);
    cd(name);
    plot(1:size(Phi_agg,1),Phi_agg,'--bo',1:size(Phi_disagg,1),Phi_disagg,':r*',  'LineWidth',2)
    ylabel('Value')
    xlabel('Iteration')
    legend('aggregate','disaggregate')
    title('Dual Objectives: Aggregate vs Disaggregate')
    %save fig
    saveas(1,'dual_agg_disagg', 'png')
    %%% Both primals (agg vs disagg)    
    figure(1);
    plot(1:size(Rev_agg,1),Rev_agg,'--bo',1:size(Rev_disagg,1),Rev_disagg,':r*',  'LineWidth',2)
    ylabel('Value')
    xlabel('Iteration')
    legend('aggregate','disaggregate')
    title('Primal Objectives: Aggregate vs Disaggregate')
    %save fig
    saveas(1,'primal_agg_disagg', 'png')
    
    cd ..;    
    
    Phi_agg(end)-Phi_disagg(end)
    close all;
end