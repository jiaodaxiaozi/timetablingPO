function [l_out,u_out,n_i] = ApplyFixings(B_star,l_in,u_in,x_0,V,Capacity_Consumptions_Of_Paths,Last_MU_Multipliers_BundlePhase_For_BlockTimes,n)

global R %number of requests

kappa = 0.2; %target value factor
indexes_nullpaths = 1:n;
indicator = 0; %our indicator that we should apply the current set of variables in B_star

%calculate lagrangian revenue for all variables in B_star
Lagrangian_revenue = zeros(length(B_star),1);%vector for lagrangian revenue
V_star = V(B_star);
for i = 1:length(B_star);
    temp = Capacity_Consumptions_Of_Paths(:,:,B_star(i)).*Last_MU_Multipliers_BundlePhase_For_BlockTimes;
    Lagrangian_revenue(i) = V_star(i) - sum(temp(:));
end

%Find indexes for sorting lag_rev in descending order
[~,dec_ind] = sort(Lagrangian_revenue,'descend');

%We use indexes found to sort B_star
B_star = B_star(dec_ind);

%The potential fixes of B_star that are rejected are fixed to zero
B_star_complement = [];

while indicator == 0;
    if indicator == 0;
        %temporary vectors to see if applying fixes is good or bad
        l_temp = l_in; u_temp = u_in;
        %Set lower bound for all variables currently in B_star to one
        l_temp(B_star,:) = 1;
        %Set upper bound for all variables currently in B_star_complement
        %to zero, unless they are nullpaths
        zero_fixed_variables = setdiff(B_star_complement,indexes_nullpaths);
        u_temp(zero_fixed_variables,:) = 0;
        %calculate target value by using obj value for current subtree node
        obj_subtree_RMLP = sum(x_0(:).*V(:));       
        target_value = obj_subtree_RMLP*(1 - kappa*length(B_star)/R);
        %Calculate temporary solution if fixing does not make x_i integer
        integer_variables = size(find(l_temp == 1));
        if integer_variables < R;
            x_i = RMLP(V,l_temp,u_temp);
        else
            x_i = l_temp;
        end
        %calculate objective value using current x_i and corresponding revenues
        obj_l_temp = x_i'*V(:);
        %If we are above or equal to the target value, the fixes are fine
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
    end    
    if indicator == 1;
        %if our indicator is 1 here we should update l and u using
        %temporary l_temp and u_temp
        l_out = l_temp; u_out = u_temp;
    end  
end
%check if integer solution found i.e all requests have one fixed variable
nr_of_fixes = length(find(l_out == 1));
if nr_of_fixes ~= R;
    n_i = true;
else
    n_i = false;
end
end