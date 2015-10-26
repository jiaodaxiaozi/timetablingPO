function [x_0,l,u,n_i] = ApplyFixings(l,u,x_0,V,A,b,Aeq,beq,B_star,MU,R)
V_perturbated = V;
kappa = 0.3; %target value factor
nr_of_trains = R; 
int_tol = 10^-6; %Tolerance for intervals around 0 and 1
indicator = 0; %our indicator that we should apply the current set of variables in B_star

%calculate lagrangian revenue for all variables in B_star
Lagrangian_revenue = zeros(length(B_star),1);%vector for lagrangian revenue
A_star=A(:,B_star); V_star = V(B_star);
for i = 1:length(B_star);
    temp = (D_star(i)).*MU;
    Lagrangian_revenue(i) = V_star(i) + sum(temp(:));
end

%Find indexes for sorting lag_rev in descending order
[~,dec_ind] = sort(Lagrangian_revenue,'descend');

%We use indexes found to sort B_star
B_star = B_star(dec_ind);
%The potential fixes of B_star that are rejected are fixed to zero
B_star_complement = [];

%step two: loop until either target value is reached or only one possible
%fix remains
while indicator == 0;
    if indicator == 0;
        %temporary vectors to see if applying fixes is good or bad
        l_temp = l; u_temp = u;
        %Set lower bound for all variables currently in B_star to one
        l_temp(B_star,:) = 1;
        %Set upper bound for all variables currently in B_star_complement
        %to zero
        u_temp(B_star_complement,:) = 0;

        %calculate target value by using obj value for current subtree node
        obj_subtree_RMLP = sum(x_0(:).*V(:));       
        target_value = obj_subtree_RMLP - kappa*length(B_star)/nr_of_trains;
        
        %Calculate temporary solution
        [x_i] = RMLP(l_temp,u_temp,V_perturbated,A,b,Aeq,beq);
        %calculate objective value using current x_i and corresponding revenues
        obj_l_temp = sum(x_i(:).*V(:));
        %if we are above or equal to the target value, the fixes are fine
        %and we apply them and uppdate our indicator of this.
        if obj_l_temp >= target_value && length(B_star) ~= 1;
            indicator = 1;
        %If the target value was not reached we move halve the number of indexes
        %in B_star to B_star_complement
        elseif obj_l_temp < target_value && length(B_star) ~= 1;
            %if odd number of variables remove "worst" half of them
            if mod(length(B_star),2) == 1;
                B_star_complement = [B_star_complement; B_star(end)];
                B_star = B_star(1:length(B_star)-1,1);
            end
            %move the worst half to complement
            B_star_complement = [B_star_complement; B_star(length(B_star)/2+1:end,1)];
            B_star =  B_star(1:length(B_star)/2,1);
        elseif length(B_star) == 1;
            %if only one element remain in B_star then we apply it and
            %uppdate our indicator accordingly
            indicator = 1;
        end
    elseif indicator == 1;
        %if our indicator is 1 here we should update l and u using
        %temporary l_temp and u_temp
        l = l_temp; u = u_temp;
        %remember current solution as our current root solution
        x_0 = x_i;
    end 
end
%check if integer solution found
n_i = false;
for s = x_0;
    for t = s';
        if (t >= int_tol) && (t <= 1 - int_tol);
            n_i = true;
            break
        end
    end
    if n_i == true;
        break
    end
end
end