%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Disaggregate vs Aggregate BM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging messages
global DEBUG
DEBUG = 1;

global PLOT
PLOT = 1;

% test cases
N_tests = 12;
filename = cell(N_tests, 1);
filename{1,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_4_stop.csv';
filename{2,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AE_20_stop.csv';
filename{3,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_AK_4_stop.csv';
filename{4,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_TNK_8_stop.csv';
filename{5,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_10_stop.csv';
filename{6,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AC_4.csv';
filename{7,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/test_AE_20.csv';
filename{8,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_AK_4.csv';
filename{9,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_TNK_8.csv';
filename{10,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_10.csv';
filename{11,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_26.csv';
filename{12,1} = 'C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/NK_KMB_26_stop.csv';


%%% Read the network data (OBS. specify the absolute path with "/")
for nt =10:N_tests
    
    if DEBUG
        fprintf('>>> Test case %d  \n', nt);
    end
    
    %% creating result folder
    [~,name,~] = fileparts(filename{nt,1});
    mkdir(name);
    
    %% Aggregate
    if DEBUG
        disp('--->>>> AGGREGATE ...');        
        disp('---> Reading Network Data ...');
    end
    [network, graphs, R, Cap, T, genPaths] = ...
        mexReadData(filename{nt,1});
    B = size(Cap, 1);
    
    % maximal number of generated paths per request
    P = 50;
    
    % Bundle method without perturbations or restrictions
    if DEBUG
        disp('---> Bundle Phase - Paths Generation ...');
    end
    [x_agg, mu_opt, Phi_agg, ~] = ...
       BM_aggregate(network, graphs, genPaths, double(Cap), B, T, R, P);
    
    %% saving the plots the results from the aggregate
    % draw optimal prices
    figure(1);
    DrawPrices(mu_opt);
    cd(name);
    saveas(1,'optimal_prices_agg', 'png');
    close all;
    cd ..;
    
    %% free memory
    mexFreeMem(network, graphs, genPaths);
    clear network graphs genPaths;
        
    %% the disaggregate
    if DEBUG
        disp('--->>>> DISAGGREGATE ...');        
        disp('---> Reading Network Data ...');
    end
    [network, graphs, R, Cap, T, genPaths] = ...
        mexReadData(filename{nt,1});
    B = size(Cap, 1);
    
    % maximal number of generated paths per request
    P = 50;
    
   
    % Bundle method without perturbations or restrictions
    if DEBUG
        disp('---> Bundle Phase - Paths Generation ...');
    end
   [x_dis, mu_opt, Phi_dis, ~] = ...
       BM_disaggregate(network, graphs, genPaths, Cap, B, T, R, P);
    
    %% saving the plots the results    
    % draw optimal prices
    figure(1);
    DrawPrices(mu_opt);
    cd(name);
    saveas(1,'optimal_prices_dis', 'png');
    close all;
    cd ..;
    
    %% free memeory in c++
    mexFreeMem(network, graphs, genPaths);
    clear network graphs genPaths;
    
    
    %% Save the comparison results
    figure(1);
    plot(1:size(Phi_agg), Phi_agg, 1:size(Phi_dis), Phi_dis, 'LineWidth',2);
    ylabel('Value')
    xlabel('Iteration')
    legend('aggregate', 'disaggregate')
    title('Aggregate vs disaggregate dual objective')
    cd(name);
    saveas(1,'comp_dis_agg', 'png');
    close all;
    cd ..;
end