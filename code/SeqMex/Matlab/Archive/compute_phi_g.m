function [phi_, g_] = compute_phi_g(dualObj, cap_cons, mu, aggregate)

global B_g
global R_g
global T_g
global Cap


%%% compute the objective value
cst = 0;
for b=1:B_g
    cst = cst + sum(double(Cap(b))*mu(b,:));
end
if(aggregate)
    rg = 1;
else
    rg = R_g;
end
phi_ = zeros(rg,1);
g_ = zeros(B_g,T_g,rg);
if(~aggregate) %% disaggregate
    % obj
   for r=1:R_g    
       phi_(r) = dualObj(r);
   end 
   % subgradient
   g_ = -cap_cons;
else %% aggregate 
   % obj
   phi_(rg) = sum(dualObj)+ cst; 
   % subgrad
   for b=1:B_g
        g_(b,:,rg) = double(Cap(b));
        for r=1:R_g
            g_(b,:,rg)= g_(b,:,rg)-double(cap_cons(b,:,r));
        end
    end   
end

end