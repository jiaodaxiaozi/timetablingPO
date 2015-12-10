function [ x ] = fract_sol( lambda, Path, P )
%FRACT_SOL Constructs the fractional solution
%   Constructs the fractional solution from the lagrangian multipliers

% sizes
k_max = size(lambda,1);
R = size(lambda,2);

% construct the solution
x = zeros(max(P),R); %% main binary variable of the IP problem
for r=1:R % train requests
    for p=1:P(r) % paths
        x(p,r) = 0; % approximation of x(p_r)
        for k=1:k_max
           if Path(r,k) == p
              x(p,r) = x(p,r) + lambda(k,r);
           end
        end
    end
end
end

