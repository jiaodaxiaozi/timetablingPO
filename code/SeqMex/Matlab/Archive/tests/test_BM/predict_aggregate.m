function [Phi_predicted] = predict_aggregate(y, Phi, Active, g, mu)

k = size(Active,1);
v = zeros(k,1);
phi_ = zeros(k,1);
for l_=1:k
    if(Active(l_,1) == 1)
        cc = g(:,:,l_);
        mu_l = mu(:,:,l_);
        v(l_) = cc(:)'*(y(:)-mu_l(:));
        phi_(l_) = Phi(l_);
    end
end

Phi_predicted = max(v+phi_);
end