function DrawRes(filename)

%% load the results file
load(filename, 'R', 'mu_agg', 'mu_dis', 'SPs_id_agg', 'SPs_id_dis', ...
        'Timetables_agg', 'Timetables_dis', 'Phi_agg', 'Phi_dis', 'timing');

%% creating result folder
disp('> Creating results folder ...');
[~,foldername,~] = fileparts(filename);
mkdir(foldername);

%% draw optimal prices (agg & dis)
figure('Visible','off')
DrawPrices(mu_agg, 'Optimal multipliers - Aggregate Approach');
cd(foldername);
saveas(1,'optimal_prices_agg', 'png');
close all;
cd ..;

figure('Visible','off')
DrawPrices(mu_dis, 'Disaggregate Approach');
cd(foldername);
saveas(1,'optimal_prices_dis', 'png');
close all;
cd ..;


%% Saving the optimal timetable
for r=1:R
    figure('Visible','off');
    for p=2:max(SPs_id_agg(r,:))
        hold on;
        DrawTimetable(Timetables_agg(:,:,p,r));
    end
    cd(foldername);
    str_name = sprintf('genPaths_agg_r%d',r);
    saveas(1, str_name, 'png');
    close all;
    cd ..;
    
    figure('Visible','off');
    for p=2:max(SPs_id_dis(r,:))
        hold on;
        DrawTimetable(Timetables_dis(:,:,p,r));
    end
    cd(foldername);
    str_name = sprintf('genPaths_dis_r%d',r);
    saveas(1, str_name, 'png');
    close all;
    cd ..;
end

%% Save the dual objectives (agg vs dis)
figure('Visible','off')
plot(1:size(Phi_agg), Phi_agg, 'r', 1:size(Phi_dis), Phi_dis, 'b', 'LineWidth', 2);
ylabel('Dual objective value')
xlabel('Iteration number')
legend('Aggregate', 'Disaggregate')
lh=findall(gcf,'tag','legend');
set(lh,'location','northeast');
str = sprintf('Test case %s - aggregate vs disaggregate dual objective', foldername);
title(str)
cd(foldername);
saveas(1,'comp_dual_value', 'png');
close all;
cd ..;

%% improvements (agg vs dis)
time_startup = timing(1,3);
t_agg = timing(1,1); t_dis = timing(1,2);
time_improv = (t_agg-t_dis)/t_dis;
v_dis = Phi_dis(end,1); v_agg = Phi_agg(size(Phi_dis,1),1);
v_improv = (v_agg-v_dis)/v_dis;
fprintf('startup time  %d\n', time_startup);
fprintf('time improvement  %d\n', time_improv*100);
fprintf('value improvement  %d\n', v_improv*100);