function [Phi_predicted] = predict_aggregate(y, Psi, Active, g, mu)

R = size(g,3);

k = size(Active,1);

% v_r
v = zeros(R,k);

for r=1:R
   for l=1:k
      if(Active(l,r) == 1)
          cc = g(:,:,r,l);
          v(r,l) = Psi(l,r)+ cc(:)'*(y(:)-mu(:));
      end
   end
end

Phi_predicted = sum(max(v, [], 2));
end