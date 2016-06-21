function [phi_, g_] = compute_phi_g(mu)


%%% the dual aggregate objective value
phi_ = sum((mu(:)-2).*(mu(:)-2));
g_ = 2*(mu-2);
end