%If x_i_k = a for some element of x_i then strong branching introduces the
%constraint x_i_k < a. this prouduces a new subproblem that is solved. Then
%the same is done but with the constrain x_i_k > a. This is repeated for
%all fractionals or a subset of the fractionals in x_i. The constraint that
%gives the best bound is then chosen. The way to choose subset to test may vary.
%Here I choose the r largest fractions. Might only want to find a
%variable to set to 1. In that case then we only look at the optimal
%objective value for x_i_k > a.


function j_star = strongbranching(x_best,l,u,D,V)
V_perturbated = V;
r = 10;%Maximum number of fractions examined
%Check index of fractionals that are between 0 and 1
index = find(x_best ~= 0 & x_best ~= 1 );
%the size of the branching index vector is the minimum of r and the nr of
%fractions
nr_of_branches = min(r,length(index));
%so long as not all values in x_i is 0 or 1
if isempty(index) == 0;    
    %add all the fractional values to array for fractional
    %values
    fractionals = x_best(index);
end
%Array for objective values.
Obj = zeros(nr_of_branches,1);
%Array for possible best indexes
best_index = zeros(nr_of_branches,1);
for t = 1:nr_of_branches;
    %temporary bound, last letter says we let x_i_k > a
    l_t_u = l;
    %find the index of the maximum fractional in fractionals and the maximum fraction.
    [~, max_fractional_index_in_fractionals] = max(fractionals);
    %set the maximum fraction in fractionals to zero to avoid finding it again
    fractionals(max_fractional_index_in_fractionals) = 0;
    %Remember this index
    best_index(t) = max_fractional_index_in_fractionals;
    %find max fractional index in x_best
    x_best_max_index = index(max_fractional_index_in_fractionals);
    %Change temporary lower bound for variable with maximum fraction.
    l_t_u(x_best_max_index) = 1;
    %solve RLMP(w,l_t_u,u)
    [x_i] = RMLP(l_t_u,u,D,V_perturbated);
    %calculate objective value using current x_i and corresponding revenues
    obj_u = sum(x_i(:).*V(:));
    %add the objective value to the objective value vector
    Obj(t,1) = obj_u;
    
    
end
%find the maximal  objective value in Obj
[max_value, max_index] = max(Obj);
j_star = Best_index(max_index);

end