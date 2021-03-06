function [ x ] = fract_sol(lambda, Path, P)
%FRACT_SOL Constructs the fractional solution
%   Constructs the fractional solution from the lagrangian multipliers
R = size(Path,1);

global DISAGG

% sizes
k_max = size(lambda,1);
% construct the solution
x = zeros(P,R); %% main binary variable of the IP problem
for r=1:R % train requests
    if DISAGG
        rr = r;
    else
        rr = 1;
    end
    for p=1:P % paths
        for k=1:k_max
           if Path(r,k) == p
              x(p,r) = x(p,r) + lambda(k,rr);
           end
        end
    end
end

end



