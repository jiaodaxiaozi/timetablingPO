%indata is B_star, the set of potential fixes and l,u which are the lower
%and upper bounds for all variables. Basically this part tries to apply all
%fixes but if the target value is not reached then we only try to apply
%half of the fixes. This is repeated until either the target value is
%reached or only one potential fix remain. We are trying to minimize an
%upper bound so we want to be below our target value.
%NOTE1: below or above target value
%NOTE2: Need to know number of trains to know how to calculate target value
%NOTE3: Order variables by increasing or decreasing reduced cost
%NOTE4: Calculate v_p, mu and d_p
%NOTE5: Add objective value for RMLP in the current subtree as input
%NOTE6: Change objective values to bounds instead
%NOTE7: Total perturbation dimensionality, how to calculate
%NOTE8: Might not need u if we manipulate constraints in bundle method

function [l,u] = ApplyFixings(B_star,l,u) % !ABDOU! use l_in and l_out instead of l!
kappa = 0.05; %target value factor
nr_of_trains = 500; %total number of trains, how to calculate?
indicator = 0; %our indicator that we should apply the current set of variables in B_star
% total_perturbation = zeros(length(l),1); %we never perturb the costvector here.
%step one: sort the set B_star by reduced cost.


%Random values to test code
%B_star = randperm(25,9)';
n = size(B_star,1);
%obj_subtree_RMLP = randperm(100,1);
total_perturbation = zeros(n,1);
l = zeros(max(B_star)+1,1);
%Sort B_star by increasing index
B_star = sort(B_star);

%calculate lagrangian revenue for all variables in B_star

%vector for lagrangian revenu
lag_rev = ones(n,1);

%Lagrangian revenue is calculated for all variables in B_star
%V is vector with all profits for paths in B_star
%d_p is a vector (d^p_bt) for recource consumption of p on blocktimes bt
%mu is the lagrange multipliers to the corresponding blocktimes
%Lagrangian revenue for a path p is the sum of the income v_p and the
%scalar product of mu_p and d_p
%OBS: B_star and lag_rev should have the same index ordering
%random value to test code
lag_rev = randperm(100,n)'.*lag_rev;

%Find indexes for sorting lag_rev in descending order
[dec_val,dec_ind] = sort(lag_rev,'descend');

%We use indexes found to sort B_star
B_star_sorted = B_star(dec_ind);
B_star = B_star_sorted;

%step two: loop until either target value is reached or only one possible
%fix remains
%constant to test code 
b = 1;

while indicator == 0 && b < 25;
    %temporary l vector to see if applying fixes is good or bad
    if indicator == 0;
        %Set lower bound for all variables currently in B_star to one
        l_temp(B_star,:) = 1;  %!ABDOU! l_temp should be preallocated somewhere before!

        %calculate target value by using obj value for current subtree
        %Random value to test code obj_subtree_RMLP        
        target_value = RMLP(v,l,u,p) - kappa*length(B_star)/nr_of_trains;
        
        %calculate objective value using the fixes made in this iteration.
        [x,obj_l_temp] = RMLP(total_perturbation,l_temp,u,[]); %!ABDOU! x is not used or?
        %random value to test code
        obj_l_temp = 1.5*randperm(100,1);
        %if we are below the target value, we want to minimize an upper bound, the fixes are fine
        %and we apply them and uppdate our indicator of this.
        if obj_l_temp < target_value && length(B_star) ~= 1;
            indicator = 1;
        %If the target value was reached or exceeded we halve the number of indexes
        %in B_star, need to remember if odd or even, pay attention to when
        %there is only one element in B_star.
        elseif obj_l_temp >=target_value && length(B_star) ~= 1;
            %if odd number of variables remove "worst" half of them
            if mod(length(B_star),2) == 1;
                B_star = B_star(1:length(B_star)-1,1);
            end
            %Now it is even nr of variables so remove the worst half
            B_star =  B_star(1:length(B_star)/2,1);
        elseif length(B_star) == 1;
            %if only one element remain in B_star then we apply it and
            %uppdate our indicator of doing so
            indicator = 1;
        end
    elseif indicator == 1;
        %if our indicator is 1 here we should update l using l_temp
        l = l_temp;
        %We may want to change u here aswell or l can be used to force
        %variables to zero in the bundle code. If we update u then we
        %should set u = 0 for all indexes that belong to the same train
        %as we just set the l = l_temp.
    end
%test variable update
b = b + 1;   
end
if indicator == 1;
    %if our indicator is 1 here we should update l using l_temp
    l = l_temp;
    %We may want to change u here aswell or l can be used to force
    %variables to zero in the bundle code. If we update u then we
    %should set u = 0 for all indexes that belong to the same train
    %as we just set the l = l_temp.
end
end