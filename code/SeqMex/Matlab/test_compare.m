%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Disaggregate vs Aggregate BM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% global macros
% showing debugging messages (different levels)
global DEBUG
DEBUG = 1;
global DEBUG_L1
DEBUG_L1 = 1;
global DEBUG_L2
DEBUG_L2 = 1;
% maximal number of generated paths per request
P = 50;

%% creating the test database
testnames = {...
    % 4 academic tests - crossing requests
     'test1_AC_4';'test1_AC_4_stop';...
    'test1_AE_20';'test1_AE_20_stop';...
    % 4 academic tests - similar requests
    'test_AC_4';'test_AC_4_stop';...
        'test_AE_20';'test_AE_20_stop';...
    % 4 test from malmbanan
        'NK_AK_4';'NK_AK_4_stop';...
        'NK_TNK_8';'NK_TNK_8_stop';...
    %    'NK_KMB_10_stop';'NK_KMB_10_stop';...
    };
% test cases
N = size(testnames, 1);
filename = cell(N, 1);
for i=1:N
    filename{i,1} = ...
        strcat('C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/',...
        testnames{i},'.csv');
end

%%% Read the network data (OBS. specify the absolute path with "/")
for nt =1:N
    
    if DEBUG
        fprintf('>>> Test case %d  \n', nt);
    end
    
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
    
    
    % creating result folder
    if DEBUG
        disp('> Creating results folder ...');
    end
    mkdir(testnames{nt});
    
    %% saving the plots the results from the aggregate
    % draw optimal prices
            figure('Visible','off')
    DrawPrices(mu_opt);
    cd(testnames{nt});
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
    figure('Visible','off')
    DrawPrices(mu_opt);
    cd(testnames{nt});
    saveas(1,'optimal_prices_dis', 'png');
    close all;
    cd ..;
    
    %% Save the comparison results
    figure('Visible','off')
    plot(1:size(Phi_agg), Phi_agg, 1:size(Phi_dis), Phi_dis, 'LineWidth',2);
    ylabel('Value')
    xlabel('Iteration')
    legend('aggregate', 'disaggregate')
    title('Aggregate vs disaggregate dual objective')
    cd(testnames{nt});
    saveas(1,'comp_dis_agg', 'png');
    close all;
    cd ..;
    
    %% free memeory in c++
    mexFreeMem(network, graphs, genPaths);
    clear network graphs genPaths;
end