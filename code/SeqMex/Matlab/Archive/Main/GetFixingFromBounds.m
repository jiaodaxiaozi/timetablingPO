% GetFixingFromBounds(lb,ub,NbRequests) 
function fixings = GetFixingFromBounds(lb, ub)

% get the sizes
r_max = size(ub,2);

%%% initialize the vector of fixings
fixings = zeros(r_max,1);

%%% get the path index to fix to 1
for r=1:r_max
    index = find(lb(:,r)  == ub(:,r) & lb(:,r) == 1);
    if(index)
        fixings(r,1) = index;
    end
    % if no index is found, there is no fixing
end
end