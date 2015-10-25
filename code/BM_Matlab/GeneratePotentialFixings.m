function B_star = GeneratePotentialFixings(l,u,V,A,b,Aeq,beq)
%test values


%initial values
epsilon = 0.2; delta = 0.3; %integrality tolerance: epsilon, constant used in potential function: delta,
alfa = 0.5; G = max(V(:)); % constant used to update costvector: alfa, bonus weight for spacer step: gamma, 
i=0; k=0; %Step counters, i is the number of iterations, k is the number of iterations without progress
k_s = 5; %Number of steps w/o progress before spacer step
k_max = 10; %maximum number of allowed iterations
n_i = true; %True if integer infeasibilities exist 
int_tol = 10^-6; %Tolerance for intervals around 0 and 1
B_star = []; %Vector of indexes of potential fixings
v_star = 0; %Potential function is set to zero initially
V_perturbed = V; %Initially the revenues of path are unperturbed
while k < k_max && n_i == true;
    %solve the Restricted Master LP for the current perbutated cost vector,
    %x_i is the fractional solutions.
    x_i = RMLP_test(l,u,V_perturbed,A,b,Aeq,beq);
    
    if i == 0;
        x_0 = x_i;
    end
    %calculate objective value using current x_i and corresponding revenues
    obj = sum(x_i(:).*V(:));
    
    %identify index for variables close to but not fixed to one.
    B_i = find(x_i > 1 - epsilon & l == 0);
    
    %calculate the potential function used to determine if we are making
    %progress or not.
    v_x_i = obj + delta*length(B_i);
    
    %check if all entries in x_i are zeroes or ones.
    index = find((x_i >= int_tol) & (x_i <= 1-int_tol));
    %If integer solution then potential fixes found
    if isempty(index) == 1;
        n_i = false;
        B_star = B_i;
    end
    
    %Spacer step is done if no progress for k_s steps
    if mod(k,k_s) == 0 && k > 0 && n_i == true;
        %The index of the largest fractional variable is added to the
        %potential fixings vector.
        
        %Check index of fractionals that are between 0 and 1 not already in
        %B_star or B_i
        fractional_index = setdiff(index, union(B_star,B_i));
        %so long as not all values in x_i is 0 or 1 or potential fixes
        if isempty(fractional_index) == 0; 
            %add all the fractional values to array for fractional values  
            fractionals = x_i(fractional_index);
            
            %find the index of the maximum fractional in fractionals.
            [~, max_fractional_index_in_fractionals] = max(fractionals);
                      
            %find the index of corresponding maximal fractional in x_i
            j_star = fractional_index(max_fractional_index_in_fractionals) ;
            %Give bonus weight G to perturbation value of x_i(j_star)
            V_perturbed(j_star) = V_perturbed(j_star) + G;
            %Add j_star to the list of potential fixings
            B_star = union(B_i,j_star);
        end
    else
        if v_x_i > v_star;
            %Update the vector for potential fixings, potential function
            %and since we made progress we reduce the number of steps w/o
            %progress.
            B_star = B_i; v_star = v_x_i; k = k - 1;
        end
        %the perturbation  made to all elements in income matrix
        V_perturbed = alfa*V_perturbed.*(x_i).^2 + V_perturbed;

    end     
    i = i + 1; k = k + 1;
end

%If B_star is empty then choose a potential variable to fix by
%strongbranching.
if isempty(B_star) == 1;
    j_star = strongbranching(x_0,l,u,V,A,b,Aeq,beq);
    B_star = j_star;
end
end