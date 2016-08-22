function [phi_, g_, cst] = compute_phi_g(totalRev, cap_cons, mu, Phi_SP, Cap)

%% macros
global DEBUG
global DISAGG

%% Parameters
T = size(mu,2);
R = size(totalRev, 1);
cap_cons = double(cap_cons);

%% Phi: Dual objective
% initialize with revenues
phi_tmp = totalRev;

% subtract the capacity usage penalization
for r=1:R
    cc = cap_cons(:,:,r);
    phi_tmp(r) = phi_tmp(r) - cc(:)'*mu(:);
end

% check if the result is consistent with SP
if(DEBUG && sum(Phi_SP ~=phi_tmp))
    fprintf('SP is diff than MB, %f !!!!\n', Phi_SP - phi_tmp);
end

% constant term, i.e. C*mu
cc = repmat(Cap,1,T);
cst = cc(:)'*mu(:);

% add the constant term to dual objective (not for disaggregate)
phi_ = phi_tmp;


%% g: Subgradient
if(DISAGG) % disaggregate approach
    g_ = -cap_cons;
else % aggregate approach
    g_ = cc-sum(cap_cons,3);
end

end