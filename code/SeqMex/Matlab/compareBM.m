%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test Program : Disaggregate vs Aggregate BM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% global macros
% showing debugging messages (different levels)
global DEBUG
DEBUG = 0;
% chossing aggregate or disaggregate approach
global DISAGG

%% parameters
% maximal number of generated paths per request
P = 200;
% creating the test database
testnames = {...
    % large instances
    'S1';...
%     'S2';...
%     'S3';...
%     'S4';...
    %     %     % 4 academic tests - crossing requests
    %     'test1_AC_4';...
    %      'test1_AC_4_stop';...
    %      'test1_AE_20';'test1_AE_20_stop';...
    %             % 4 academic tests - similar requests
    %      'test_AC_4';...
    %      'test_AC_4_stop';...
    %      'test_AE_20';'test_AE_20_stop';...
    %         % 4 test from malmbanan
    %                'NK_AK_4';'NK_AK_4_stop';...
    %                'NK_TNK_8';'NK_TNK_8_stop';...
    %               'NK_KMB_10_stop';'NK_KMB_10_stop';...
    };
% test cases
N = size(testnames, 1);
filename = cell(N, 1);
timing = zeros(N,3);
for i=1:N
    filename{i,1} = ...
        strcat('C:/Users/abde/Documents/GitHub/TimetablePO/code/SeqMex/Matlab/',...
        testnames{i},'.csv');
end

%%% Read the network data (OBS. specify the absolute path with "/")
for nt =1:N
    
    fprintf('>>> Test case %s \n', testnames{nt});
    
    %% Aggregate
    DISAGG = 0;
    disp('--->>>> AGGREGATE ...');
    disp('---> Reading Network Data ...');
    
    tic
    [R, Cap, T] = ...
        mexSP('read', filename{nt,1});
    timing(nt,3) = toc; % timing graph construction
    B = size(Cap, 1);
    
    % Bundle method without perturbations or restrictions
    disp('---> Bundle Phase - Paths Generation ...');
    [x_agg, mu_agg, Phi_agg, SPs_id_agg, timing(nt,1)] = ...
        BM(Cap, B, T, R, P);
    
    %% getting the generated paths
    [Timetables_agg, ~, ~] = mexSP('retrieve', P);
    
    %% free memory
    disp('---> Cleaning memory ...');
    mexSP('clean');
    clear mexSP;
    
    %% the disaggregate
    DISAGG = 1;
    disp('--->>>> DISAGGREGATE ...');
    disp('---> Reading Network Data ...');
    
    [R, Cap, T] = ...
        mexSP('read', filename{nt,1});
    B = size(Cap, 1);
    
    % Bundle method without perturbations or restrictions
    
    disp('---> Bundle Phase - Paths Generation ...');
    
    [x_dis, mu_dis, Phi_dis, SPs_id_dis, timing(nt,2)] = ...
        BM(Cap, B, T, R, P);
    
    %% getting the generated paths
    [Timetables_dis, ~, ~] = mexSP('retrieve', P);
    
    %% Save variables to files
    save(strcat(testnames{nt},'.mat'));
    
    %% free memeory in c++
    disp('---> Cleaning memory ...');
    mexSP('clean');
    clear mexSP;
end