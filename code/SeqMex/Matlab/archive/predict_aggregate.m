function [Phi_predicted, Active_new] = predict_aggregate(k, y, Phi, g, mu, Active)

% compute the predicted phi
v = -inf(k,1);
for l_=1:k
    if(Active(l_) == 1)
        cc = g(:,:,l_);
        mu_l = mu(:,:,l_);
        v(l_) = Phi(l_)+ cc(:)'*(y(:)-mu_l(:));
    end
end
Phi_predicted = max(v);

% set the active hyperplanes
Active_new = zeros(k,1);
Active_new(abs(v-Phi_predicted)<eps) = 1;
end