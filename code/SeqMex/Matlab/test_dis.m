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
% plotting figures
global PLOT
PLOT = 1;
% maximal number of generated paths per request
P = 50;

%% creating the test database
testnames = {...
   'S1';...
    % 4 academic tests - crossing requests
 %     'test1_AC_4';'test1_AC_4_stop';...
  %   'test1_AE_20';'test1_AE_20_stop';...
%     % 4 academic tests - similar requests
%      'test_AC_4';'test_AC_4_stop';...
%      'test_AE_20';'test_AE_20_stop';...
%     % 4 test from malmbanan
%     'NK_AK_4';'NK_AK_4_stop';...
%     'NK_TNK_8';'NK_TNK_8_stop';...
 %   'NK_KMB_10_stop';'NK_KMB_10_stop';...
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
    %% init test case
    if DEBUG
        fprintf('***** Test BM_dis, case %d : %s ***** \n', nt, testnames{nt});
    end
  
    %% read the test data
    if DEBUG
        disp('> Reading Network Data ...');
    end
    [network, graphs, R, Cap, T, genPaths] = ...
        mexReadData(filename{nt,1});
    B = size(Cap, 1);
    
    
    %% BM aggregate
    % Bundle method without perturbations or restrictions
    if DEBUG
        disp('> Bundle Phase - Paths Generation ...');
    end
    [x_dis, mu_opt, Phi_dis, capCons_opt] = ...
        BM_disaggregate(network, graphs, genPaths, Cap, B, T, R, P);
    
    % creating result folder
    if DEBUG
        disp('> Creating results folder ...');
    end
    mkdir(testnames{nt});
    
    if PLOT
        % Generated paths
        [Timetables, Revenues, capCons] = mexPaths(genPaths, P);
        for r=1:R
            figure('Visible','off')
            DrawTimetable(Timetables(:,:,:,r));
            cd(testnames{nt});
            str = sprintf('genPaths_request_%d_dis', r);
            saveas(1,str, 'png');
            cd ..;
            close all;
        end
        
        % optimal prices
        figure('Visible','off')
        DrawPrices(mu_opt);
        cd(testnames{nt});
        saveas(1,'optimal_prices_dis', 'png');
        close all;
        cd ..;
        
        %%% dual and primal objective
        figure('Visible','off')
        K = size(x_dis,3);
        F_dis = zeros(K,1);
        for it=1:K
            F_dis(it) = sum(sum(Revenues.*x_dis(:,:,it)));
        end
        plot(1:size(Phi_dis), Phi_dis, 1:K, F_dis, 'LineWidth',2);
        ylabel('Value')
        xlabel('Iteration')
        legend('Dual', 'Primal')
        title('Dual vs Primal Objective')
        cd(testnames{nt});
        saveas(1,'dual_primal_dis', 'png')
        cd ..;
        close all;
    end  
    
    %% free memeory in c++
    mexFreeMem(network, graphs, genPaths);
    clear network graph genPaths;
end