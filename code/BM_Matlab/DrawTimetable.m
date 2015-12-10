function DrawTimetable(OccMat, stations)
% DrawTimetable  draw a timetable as a the block-time diagram.
%   DrawTimetable(OccMat) draws timetable from occupation matrix OccMat for all requests.
%   See also ...

% gets the sizes (T: times, R: requests, S: stations)
T = size(OccMat,2);
R = size(OccMat,3);
S = size(stations,1);
figure();
% draw a timetable for each request
for r=1:R
    Position = zeros(1,T);
    for b=1:S
        % get the stations occupation
        t = find(OccMat(stations(b),:,r));
        if(t)
            Position(1,t) = stations(b);
        end
    end
    [~,t,b] = find(Position);
    % draw the timetable
    plot(t, b, 'LineWidth',2);
    hold on;
end

% graph information
ylabel('Stations')
xlabel('Time')
title('Timetable')

end
