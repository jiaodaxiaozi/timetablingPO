%GetObjValFromPath Compute the revenues from the paths
%   Constructs the fractional solution from the lagrangian multipliers
function ObjVal = GetObjValFromPath(CapCons, Rev)
% get the sizes
R = size(Rev, 1);
n = size(CapCons, 3);
P_max = floor(n/R);

% create the obj val marix
ObjVal = zeros(P_max,R);

% Compute the obj val
for r=1:R
    for p=2:P_max % skip, null path p=1
        % get the starting time
        i = P_max*(r-1)+p;
        [~, t] = find(sparse(CapCons(:,:,i)));
        if(t)
            t = t(1);
        else
            ObjVal(p,r) = 0;
            continue;
        end
        % get the revenue
        rev = 0;
        tmin = Rev(r,1);
        tmax = Rev(r,2);
        tidl = Rev(r,3);
        vmax = Rev(r,4);
        if(t > tmin && t < tidl)
            rev = vmax/(tidl-tmin)*(t-tmin);
        elseif (t < tmax && t > tidl)
            rev = -vmax/(tmax-tidl)*(t-tmax);
        end
        % affect the revenue
        ObjVal(p,r) = rev;
    end
end
end
