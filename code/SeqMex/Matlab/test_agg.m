%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Disaggregate vs Aggregate BM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% Global constantes
% show or unshow the debugging mesxsages
global DEBUG
DEBUG = 1;

global PLOT
PLOT = 1;

%%% Test set
N_tests = 10;
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

%%% Read the network data (OBS. specify the absolute path with "/")
for nt =10:N_tests
    %% init test case
    if DEBUG
        fprintf('>>> Test case %d  \n', nt);
    end
    % creating result folder
    [~,name,~] = fileparts(filename{nt,1});
    mkdir(name);
    
    %% BM aggregate
    if DEBUG
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
    [x_agg, mu_opt, Phi_agg, capCons_opt] = BM_aggregate(network, graphs, genPaths, Cap, B, T, R, P);

    
    if PLOT
        % draw all the generated paths
        % get the generated paths
        [Timetables, Revenues, capCons] = mexPaths(genPaths, P);
        for r=1:R
            figure(1);
            DrawTimetable(Timetables(:,:,:,r));
            cd(name);
            str = sprintf('genPaths_request_%d_agg', r);
            saveas(1,str, 'png');
            cd ..;
        end
    end
    close all;

    
    
    % saving the plots the results
    % draw optimal prices
    figure(1);
    DrawPrices(mu_opt);
    cd(name);
    saveas(1,'optimal_prices_agg', 'png');
    close all;
    cd ..;
    
    %%% PHI & REVENUES PER ITERATION
    % generate fig - Dual
    figure(1);
    plot(1:size(Phi_agg), Phi_agg, 'LineWidth',2);
    ylabel('Value')
    xlabel('Iteration')
    title('Dual Objective')
    
    % save fig
    cd(name);
    saveas(1,'dual_agg', 'png')
    cd ..;
    
    %% free memeory in c++
    mexFreeMem(network, graphs, genPaths);
    clear network graphs genPaths;
    close all;
end