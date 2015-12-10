%If x_i_k = a for some element of x_i then strong branching introduces the
%constraint x_i_k < a. this prouduces a new subproblem that is solved. Then
%the same is done but with the constrain x_i_k > a. This is repeated for
%all fractionals or a subset of the fractionals in x_i. The constraint that
%gives the best bound is then chosen. The way to choose subset may vary.
%Here I choose the r largest fractions. Here we might only want to find a
%variable to set to 1. In that case then we only look at the optimal
%objective value for x_i_k > a.


function j_star = strongbranching(x_i,l,u)
%r = 25;
%Random values to check code
%x_i = rand(r-5,1);l = zeros(r-5,1); u = ones(r-5,1);

%Check index of fractionals that are between 0 and 1
index_frac = find(x_i ~= 0 & x_i ~= 1);
%the size of the branching index vector is the minimum of r and the nr of
%fractions
nr_of_branches = min(r,length(index_frac));
index_branching = zeros(nr_of_branches,1); %!ABDOU! index_branching is not used!
%array for all fractionals between 0 and 1
fractionals = zeros(nr_of_branches,1);
%so long as not all values in x_i is 0 or 1
if isempty(index_frac) == 0;    
    %add all the fractional values to our array for fractional
    %values
    fractionals(:,1) = x_i(index_frac);
end
%Array for objective values.
Obj = zeros(nr_of_branches,1);
%NOTE: can nr_of_branches become zero?
for t = 1:nr_of_branches;
    %temporary bounds, last letter says if we let x_i_k < a or x_i_k > a
    l_t_u = l;
    u_t_u = u;
    l_t_d = l;
    u_t_d = u;
    %find the index of the maximum fractional in fractionals and the maximum fraction.
    [max_fraction_in_fractionals, max_fractional_index_in_fractionals] = max(fractionals); %!ABDOU! max_fraction_in_fractionals is not used!
    %set the maximum fraction in fractionals to zero to avoid finding it again
    fractionals(max_fractional_index_in_fractionals) = 0;
    %find max fractional index in x_i
    x_i_max_index = index_frac(max_fractional_index_in_fractionals);
    %NOTE: calculating this may be unnecessary. May be replaced by max_fraction_in_fractionals. Find maximum value in x_i, 
    x_i_max_value = x_i(x_i_max_index);
    %Change temporary lower bound for variable with maximum fraction.
    l_t_u(x_i_max_index) = x_i_max_value;
    %solve RLMP(w,l_t_u,u) which gives objective value obj_u, we should
    %also do this whith a changed upper bound but it would mean that
    %variable is zero.
    [~, obj_u] = RLMP( w, l_t_u, u, []);
    %random value to test code
    %obj_u = 100*rand(1,1);
    %add the objective value to the objective value vector
    Obj(t,1) = obj_u;
    
    
end
%find the best objective value in Obj, max or min, we want to minimize our upper bound so should be min?
[min_value, min_index] = min(Obj); %!ABDOU! min_value is not used!
j_star = min_index;

end