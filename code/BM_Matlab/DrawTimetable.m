function DrawTimetable(OccMat)
% DrawTimetable  draw a timetable as a the block-time diagram.
%   DrawTimetable(OccMat) draws timetable from occupation matrix OccMat for all requests.
%   See also ...

% gets the sizes (B: blocks, T: times, R: request)
%B = size(OccMat,1);
T = size(OccMat,2);
R = size(OccMat,3);
figure();
% defines the plot
for r=1:R
    % get the occupation
    [b,t] = find(OccMat(:,:,r));

    % draw the timetable
    plot(t, b, 'LineWidth',2);
    hold on;
end

% graph information
ylabel('Stations')
xlabel('Time')
title('Timetable')

end
