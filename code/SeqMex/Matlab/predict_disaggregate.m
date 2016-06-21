function [Phi_predicted, Active_new] = predict_disaggregate(k, y, Phi, g, mu, Active)

R = size(Phi, 2);

% compute the predicted phi
v = -inf(k,R);
for l_=1:k
    mu_l = mu(:,:,l_);
    for r=1:R
        if(Active(l_,r)==1)
            cc = g(:,:,r,l_);        
            v(l_,r) = Phi(l_,r)+ cc(:)'*(y(:)-mu_l(:));
        end
    end
end
[Phi_predicted] = max(v, [], 1);

% find the current active constraints
Active_new = zeros(k,R);
for r=1:R
    m = Phi_predicted(r);
    Active_new(abs(m-v(:,r))<eps,r) = 1;
end
end