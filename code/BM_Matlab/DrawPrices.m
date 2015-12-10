function DrawPrices(mu, stations)
% DrawPrices  draw a density plot from the prices.
%   DrawTimetable(mu) draw a density plot from the prices given by the
%   multipliers mu
%   See also ...

% draw the graph
figure();
imagesc(mu(stations,:)); 
colorbar

% graph information
ylabel('Stations')
xlabel('Time')
title('Timetable')

end