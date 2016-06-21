function [phi_, g_] = compute_phi_g(totalRev, capCons, mu_, Phi_SP, Cap)

B = size(mu_,1);
T = size(mu_,2);
R = size(totalRev, 1);

%% dual obj
phi_tmp = zeros(R,1);
for r=1:R
    cc = double(capCons(:,:,r));
    phi_tmp(r) = totalRev(r) - cc(:)'*mu_(:);
end
cst = 0.0;
for b=1:B
    cst =  cst + Cap(b)*sum(mu_(b,:));
end
if(norm(Phi_SP - phi_tmp)> 0.001)
    fprintf('SP is diff than MB, %f !!!!\n', norm(Phi_SP - phi_tmp));
end

phi_ = sum(phi_tmp) + cst;


%% subgrad
g_ = zeros(B,T);
for b=1:B
    g_(b,:) = Cap(b);
    for t=1:T
        g_(b,t)= g_(b,t)-sum(capCons(b,t,:));
    end
end

end