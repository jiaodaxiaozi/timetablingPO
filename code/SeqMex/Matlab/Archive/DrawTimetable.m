function DrawTimetable(timetable)
% DrawTimetable  draw a timetable as a the block-time diagram.
%   DrawTimetable(OccMat) draws timetable from occupation matrix OccMat for all requests.
%   See also ...

% gets the sizes (T: times, R: requests, S: stations)
S = size(timetable,1);
NbPaths = size(timetable,3);

% draw a timetable for each request
for r=1:NbPaths
    graph = zeros(2*S, 2);
    graph(1:S, 1) = 1:S; graph(S+1:2*S, 1) = 1:S;
    graph(1:S, 2) = timetable(:,1,r); graph(S+1:2*S, 2) = timetable(:,2,r);
    [~,I] = sort(graph(:,2));
    graph = graph(I,:);
    n = size(find(graph == -1))+1;
    plot(graph(n:end,2), graph(n:end,1), 'LineWidth',2);
   hold on;
end

% graph information
ylabel('Stations')
xlabel('Time')
title('Timetable')

end
