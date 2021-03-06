function DrawPrices(mu)
% DrawPrices  draw a density plot from the prices.
%   DrawTimetable(mu) draw a density plot from the prices given by the
%   multipliers mu
%   See also ...

% draw the graph
imagesc(flipud(mu)); 
colormap(flipud(gray(256)));
colorbar;

% graph information
ylabel('Blocks')
xlabel('Timestep')

end