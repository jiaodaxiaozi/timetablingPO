function [capCons] = getCapCons(Occupation)

% global parameters
global R
global T
global B
global P

capCons = zeros(B, T, P, R);

for r=1:R
    for p=2:P
        for b=1:B
            dep = Occupation(b,1,p,r);
            arr = Occupation(b,2,p,r);
            if((dep == 0) && (arr == 0))
                continue;
            end
            dt = arr - dep+1;
            capCons(b,(dep+1):(arr+1),p,r) = ones(1,dt);
        end
    end 
end
end