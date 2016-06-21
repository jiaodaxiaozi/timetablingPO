function [phi_, g_, cst] = compute_phi_g_dis(totalRev, cap_cons, mu, Phi_SP, Cap)

B = size(mu,1);
R = size(totalRev, 1);

%%% the dual aggregate objective value
phi_tmp = totalRev;

%%% adding the constant (sum of total priced capacity)
for r=1:R
    phi_tmp(r) = phi_tmp(r) - sum(sum(double(cap_cons(:,:,r)).*mu));
end
phi_ = phi_tmp;

if(norm(Phi_SP - phi_tmp)>0.0001)
   fprintf('KO: Phi_SP and Phi_MB!!!!, %f \n',norm(Phi_SP - phi_tmp));
end

cst = 0.0;
for b=1:B
    cst =  cst + Cap(b)*sum(mu(b,:));
end

% subgrad
g_ = -cap_cons;

end