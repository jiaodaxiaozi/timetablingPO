function [phi_, g_] = compute_phi_g(totalRev, cap_cons, mu_, Phi_SP)

global B
global T
global R
global Cap


%%% the dual aggregate objective value
% phi_tmp = zeros(size(totalRev));
% 
% %%% adding the constant (sum of total priced capacity)
% for r=1:R
%     cc = double(cap_cons(:,:,r));
%     phi_tmp(r) = phi_tmp(r) - cc(:)'*mu_(:);
% end

%phi_tmp = zeros(size(totalRev));
phi_tmp = totalRev;
for r=1:R
    for b=1:B
        for t=1:T
            cc = double(cap_cons(b,t,r));
            phi_tmp(r) = phi_tmp(r) + (-cc)*mu_(b,t);
        end
    end
end
cst = 0;
for b=1:B
    cst =  cst + double(Cap(b))*sum(mu_(b,:));
end
if(norm(Phi_SP - phi_tmp)>10^-10)
    fprintf('KO!!!!\n');
end

phi_ = sum(phi_tmp) + cst;


% subgrad
g_ = zeros(B,T);
for b=1:B
    g_(b,:) = double(Cap(b));
    for t=1:T
        g_(b,t)= g_(b,t)-sum(double(cap_cons(b,t,:)));
    end
end

end