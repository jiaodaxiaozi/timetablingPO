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
%     % 4 academic tests - crossing requests
%      'test1_AC_4';'test1_AC_4_stop';...
%     'test1_AE_20';'test1_AE_20_stop';...   
%     % 4 academic tests - similar requests
%      'test_AC_4';'test_AC_4_stop';...
%      'test_AE_20';'test_AE_20_stop';...
%     % 4 test from malmbanan
%     'NK_AK_4';'NK_AK_4_stop';...
%     'NK_TNK_8';'NK_TNK_8_stop';...
% %    'NK_KMB_10_stop';'NK_KMB_10_stop';...
    };
% test cases
N = size(testnames, 1);
filename = cell(N, 1);
for i=1:N
    % OBS. specify the absolute path with "/"
    filename{i,1} = ...
    strcat('C:/Users/abde/Documents/GitHub/TimetablePO/code/Common/data/',...
              testnames{i},'.csv');
end


for nt =1:N
    %% init test case
    if DEBUG
        fprintf('***** Test BM_agg, case %d : %s ***** \n', nt, testnames{nt});
    end
    
    %% BM aggregate
    if DEBUG
        disp('> Reading Network Data ...');
    end
    [network, graphs, R, Cap, T, genPaths] = ...
        mexReadData(filename{nt,1});
    B = size(Cap, 1);
   
    
    % Bundle method without perturbations or restrictions
    if DEBUG
        disp('> Bundle Phase - Paths Generation ...');
    end
    [x_agg, mu_opt, Phi_agg, capCons_opt] = BM_aggregate(network, graphs, genPaths, Cap, B, T, R, P);

    % creating result folder
    if DEBUG
        disp('> Creating results folder ...');
    end
    mkdir(testnames{nt});
    
    % exporting the results
    if PLOT
        if DEBUG
            disp('> Plotting the generated paths ...');
        end
        % Generated paths
        [Timetables, Revenues, capCons] = mexPaths(genPaths, P);
        for r=1:R
            figure('Visible','off')
            DrawTimetable(Timetables(:,:,:,r));
            cd(testnames{nt});
            str = sprintf('genPaths_request_%d_agg', r);
            saveas(1,str, 'png');
            cd ..;
            close all;
        end
        
        % Optimal prices
        if DEBUG
            disp('> Plotting the optimal pricing ...');
        end
        figure('Visible','off')
        DrawPrices(mu_opt);
        cd(testnames{nt});
        saveas(1,'optimal_prices_agg', 'png');
        close all;
        cd ..;
        
        % Dual function & primal fractional solution
        if DEBUG
            disp('> Plotting the dual function ...');
        end
        figure('Visible','off')
        K = size(x_agg,3);
        F_agg = zeros(K,1);
        for it=1:K
            F_agg(it) = sum(sum(Revenues.*x_agg(:,:,it)));
        end
        plot(1:size(Phi_agg), Phi_agg,1:K, F_agg, 'LineWidth',2);
        ylabel('Value')
        xlabel('Iteration')
        legend('Dual', 'Primal')
        title('Dual vs Primal Objective')
        cd(testnames{nt});
        saveas(1,'dual_primal_agg', 'png')
        cd ..;
        close all;        
    end
  
    %% free memeory in c++
    mexFreeMem(network, graphs, genPaths);
    clear network graphs genPaths;
end