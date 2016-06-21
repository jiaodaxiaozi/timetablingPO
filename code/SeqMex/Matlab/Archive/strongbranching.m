function j_star = strongbranching(x_0,l,u,V,P)
%NOTE: need the total number of requests here, is it the global R?
global R

int_tol = 10^-6;
r = 20;%Maximum number of fractions examined
%Check index of fractionals that are between 0 and 1
index = find((x_0 >= int_tol) & (x_0 <= 1-int_tol) & (l ~= 1) & (u ~= 0));
%The number of fractions analyzed
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
    %temporary lower bound
    l_t_u = l;
    %find the index of the maximum fractional in fractionals and the maximum fraction.
    [~, max_fractional_index_in_fractionals] = max(fractionals);
    %set the maximum fraction in fractionals to zero to avoid finding it again
    fractionals(max_fractional_index_in_fractionals) = 0;
    %Remember this index
    best_index(t) = max_fractional_index_in_fractionals;
    %find max fractional index in x_0
    x_0_max_index = index(max_fractional_index_in_fractionals);
    %Change temporary lower bound for variable with maximum fraction.
    l_t_u(x_0_max_index) = 1;
    %solve RLMP if number of variables fixed by bounds is not integer
    integer_variables = length(find(l_t_u == 1));
    if integer_variables < R;
        x_i = RMLP(V,l_t_u,u);
    else
        x_i = l_t_u;
    end
    %calculate objective value using current x_i and corresponding revenues
    obj_u = sum(x_i(:).*V(:));
    %add the objective value to the objective value vector
    Obj(t,1) = obj_u;   
end
%find the maximal  objective value in Obj
[~, max_index] = max(Obj);
%Find corresponding index in x_0
j_star = index(best_index(max_index));
end