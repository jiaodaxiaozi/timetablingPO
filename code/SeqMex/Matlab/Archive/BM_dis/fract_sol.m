function [ x ] = fract_sol(lambda, Path)
%FRACT_SOL Constructs the fractional solution
%   Constructs the fractional solution from the lagrangian multipliers
global R
global P

% sizes
k_max = size(lambda,1);
% construct the solution
x = zeros(P,R); %% main binary variable of the IP problem
for r=1:R % train requests
    for p=1:P % paths
        for k=1:k_max
           if Path(r,k) == p
              x(p,r) = x(p,r) + lambda(k,1);
           end
        end
    end
end

end

