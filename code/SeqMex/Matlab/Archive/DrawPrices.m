function DrawPrices(mu)
% DrawPrices  draw a density plot from the prices.
%   DrawTimetable(mu) draw a density plot from the prices given by the
%   multipliers mu
%   See also ...

% draw the graph
figure();
imagesc(flipud(mu)); 
colorbar

% graph information
ylabel('Blocks')
xlabel('Time')
title('Price Levels')

end