function j_star = strongbranching(x_0,l,u,V,A,b,Aeq,beq)
int_tol = 10^-6; %Tolerance for intervals around 0 and 1
V_perturbated = V;
r = 5;%Maximum number of fractions examined
%Check index of fractionals that are between 0 and 1
index = find((x_0 >= int_tol) & (x_0 <= 1-int_tol) & (l ~= 1) & (u ~= 0));
%the size of the branching index vector is the minimum of r and the nr of
%fractions
nr_of_branches = min(r,length(index));
%so long as not all values in x_i is 0 or 1
if isempty(index) == 0;    
    %add all the fractional values to array for fractional
    %values
    fractionals = x_0(index);
end
%Array for objective values.
Obj = zeros(nr_of_branches,1);
%Array for possible best indexes to fix
best_index = zeros(nr_of_branches,1);
for t = 1:nr_of_branches;
    %temporary bound
    l_t_u = l;
    %find the index of the maximum fractional in fractionals and the maximum fraction.
    [~, max_fractional_index_in_fractionals] = max(fractionals);
    %set the maximum fraction in fractionals to zero to avoid finding it again
    fractionals(max_fractional_index_in_fractionals) = 0;
    %Remember this index
    best_index(t) = max_fractional_index_in_fractionals;
    %find max fractional index in x_best
    x_0_max_index = index(max_fractional_index_in_fractionals);
    %Change temporary lower bound for variable with maximum fraction.
    l_t_u(x_0_max_index) = 1;
    %solve RLMP
    [x_i] = RMLP_test(l_t_u,u,V_perturbated,A,b,Aeq,beq);
    %calculate objective value using current x_i and corresponding revenues
    obj_u = sum(x_i(:).*V(:));
    %add the objective value to the objective value vector
    Obj(t,1) = obj_u;
    
    
end
%find the maximal  objective value in Obj
[~, max_index] = max(Obj);
j_star = index(best_index(max_index));

end