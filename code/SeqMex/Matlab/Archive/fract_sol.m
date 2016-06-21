function [ x ] = fract_sol(lambda, Path)
%FRACT_SOL Constructs the fractional solution
%   Constructs the fractional solution from the lagrangian multipliers
global R_g
global P_g

% sizes
k_max = size(lambda,1);
rl = size(lambda,2);
% construct the solution
x = zeros(P_g,R_g); %% main binary variable of the IP problem
for r=1:R_g % train requests
    if(rl ~= 1)
       rl = r; 
    end
    for p=1:P_g % paths
        x(p,r) = 0; % approximation of x(p_r)
        for k=1:k_max
           if Path(r,k) == p
              x(p,r) = x(p,r) + lambda(k,rl);
           end
        end
    end
end

end

