function DrawTimetable(OccMat, sol, stations)
% DrawTimetable  draw a timetable as a the block-time diagram.
%   DrawTimetable(OccMat) draws timetable from occupation matrix OccMat for all requests.
%   See also ...

% gets the sizes (T: times, R: requests, S: stations)
global R
T = size(OccMat,2);
n = size(OccMat,3);
S = size(stations,1);
P_max = ceil(n/R);
figure();

sol = reshape(sol, [P_max R]);
% draw a timetable for each request
for r=1:R
    % get the idex of the path for request r
    [id_p,~] = find(sol(:,r));
    % get the timetable
    Position = zeros(1,T);
    for b=1:S
        % get the stations occupation
        id = (r-1)*P_max+id_p;
        t = find(OccMat(stations(b),:,id));
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
