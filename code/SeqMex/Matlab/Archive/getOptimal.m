function [rev, timetable] = getOptimal(l,Timetables)

% global parameters
global R
global P
global Revenues

S = size(Timetables, 1);
lb = reshape(l, [P, R]);
opts = zeros(R,1);
%%% get the path index to fix to 1
for r=1:R
    index = find(lb(:,r) == 1);
    if(index)
        opts(r) = index;
    else
        opts(r) = 1;
    end
    % if no index is found, there is no fixing
end

timetable = zeros(S, 2, R);
for r=1:R
    timetable(:,:,r) = Timetables(:,:,opts(r),r);
end
rev = sum(Revenues(opts));
end