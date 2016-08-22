%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Disaggregate vs Aggregate BM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% global macros
% showing debugging messages (different levels)
global DEBUG
DEBUG = 1;

% chossing aggregate or disaggregate approach
global DISAGG
DISAGG = 0;

% maximal number of generated paths per request
P = 500;

%% creating the test database
testnames = {...
%   'S1';...
    % 4 academic tests - crossing requests
      'test1_AC_4';...
      %'test1_AC_4_stop';...
%    'test1_AE_20';'test1_AE_20_stop';...
% %     % 4 academic tests - similar requests
%      'test_AC_4'; 'test_AC_4_stop';...
%      'test_AE_20';'test_AE_20_stop';...
% %     % 4 test from malmbanan
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
        fprintf('***** Test BM, case %d : %s ***** \n', nt, testnames{nt});
    end
    
    %% read the test data
    if DEBUG
        disp('> Reading Network Data ...');
    end
    [R, Cap, T] = ...
        mexSP('read', filename{nt,1});
    B = size(Cap, 1);
    
    % Bundle method without perturbations or restrictions
    if DEBUG
        disp('> BM Iteration ...');
    end
    [x, mu_opt, Phi, SPs_id, i, exec_time] = ...
        BM(Cap, B, T, R, P);
    
    % creating result folder
    if DEBUG
        disp('> Creating results folder ...');
    end
    mkdir(testnames{nt});
    
    % agg or dis index
    if(DISAGG)
       ind = 'dis'; 
    else
       ind = 'agg';
    end
    
    % Generated paths
    [Timetables, Revenues, capCons] = mexSP('retrieve', P);
     K = size(x,3);
    % per iteration
    for k=1:K
        figure('Visible','off')
        for r=1:R
            hold on;
            p = SPs_id(r,k);
            DrawTimetable(Timetables(:,:,p,r));
        end
        cd(testnames{nt});
        str = sprintf('genPaths_%s_iter_%d', ind, k);
        saveas(1,str, 'png');
        cd ..;
        close all;
    end   
    % per request
    for r=1:R
        figure('Visible','off')
        DrawTimetable(Timetables(:,:,:,r));
        cd(testnames{nt});
        str = sprintf('genPaths_%s_request_%d', ind, r);
        saveas(1,str, 'png');
        cd ..;
        close all;
    end
    % all at once
    figure('Visible','off')
    for r=1:R
        hold on;
        DrawTimetable(Timetables(:,:,:,r));
    end
    cd(testnames{nt});
    str = sprintf('genPaths_allrequest_%s', ind);
    saveas(1,str, 'png');
    cd ..;
    close all;
    
    % optimal prices
    figure('Visible','off')
    DrawPrices(mu_opt);
    cd(testnames{nt});
    str = sprintf('optimal_prices_%s', ind);
    saveas(1, str, 'png');
    close all;
    cd ..;
    
    %%% dual and primal objective
    figure('Visible','off')
    F = zeros(K-1,1);
    for it=1:K-1
        F(it) = sum(sum(Revenues.*x(:,:,it)));
    end
    plot(1:size(Phi), Phi, 1:K-1, F, 'LineWidth',2);
    ylabel('Value')
    xlabel('Iteration')
    legend('Dual', 'Primal')
    lh=findall(gcf,'tag','legend');
    set(lh,'location','northeastoutside');
    str = sprintf('Test case %s - Dual vs Primal Objective (%s)', testnames{nt}, ind);
    title(str)
    cd(testnames{nt});
    str = sprintf('dual_primal_%s', ind);
    saveas(1, str, 'png');
    cd ..;
    close all;
    
    %%% dual objective only
    figure('Visible','off')
    plot(1:size(Phi), Phi, 'LineWidth',2);
    ylabel('Value')
    xlabel('Iteration')
    title('Dual Objective')
    cd(testnames{nt});
    str = sprintf('dual_%s', ind);
    saveas(1, str, 'png');
    cd ..;
    close all;
    
    %% free memory in c++
    if DEBUG
        disp('> Freeing C++ memory ...');
    end
    mexSP('clean');
    clear mexSP;
end