%GeneratePotentialFixings Generate path fixings to send to the restricted
%problem

%input:
%Restricted master LP; RMLP(w,l,u) with costvector w and variables that model variable fixings to 0 and 1, l and u
%integrality tolerance: epsilon, constant used in potential function: delta,
%steps whithout progress before spacer step: k_s,maximum number of steps
%without progress before termination of algoritm: k_max.

%NOTE1:Change objective values to bounds
function B_star = GeneratePotentialFixings(l,u,x)
%initial values
epsilon = 0.1; delta = 0.3; %integrality tolerance: epsilon, constant used in potential function: delta,
alfa = 0.5; gamma = 15; %constant used to update costvector: alfa, bonus weight for spacer step: gamma, 
i=0; k=0; %Step counters, i is the number of iterations, k is the number of iterations without progress
% total_perturbation = zeros(lenth(x),1)
%w_p = w; %Initial costvector is the unperbated input costvector
%Random values to check code
n = size(x,1); 
w_p = ones(n,1); 
k_max = n; 
%l = zeros(n,1);
%u = ones(n,1);
k_s = 5; 
total_perturbation = zeros(n,1); 
%x_i = rand(n,1);

B_star = []; %Vector of indexes of potential fixings
v_star = -inf; %Potential function is set to minus infinity initially
while k < k_max;
    %solve the Restricted Master LP for the current perbutated cost vector,
    %x_i is the fractional solutions.
    x_i = RMLP(total_perturbation,l,u,[]);
    %Random values to check code
    %x_i = rand(n,1);    
    %identify index for variables close to but not equal to one.
    B_i = find(x_i > 1 - epsilon & l == 0);    
    %calculate the potential function used to determine if we are making
    %progress or not.
    obj = rand(1,1); % random value replacing the objective value 
    v_x_i = obj + delta*length(B_i);
    
    %check if all entries in x_i consists of zeroes and ones. There is
    %probably a smarter way then this.
    
    %for x_i_k = x_i';
        %might need to switch to tolerances here, count the nr of
        %noninteger entries in x_i
    %    if x_i_k ~= 0 && x_i_k ~= 1;
    %        counter_non_integer_variables = counter_non_integer_variables + 1;
    %    end
    %end
    % !ABDOU! alternative to the previous lines
    counter_non_integer_variables = length( find(x_i<1 & x_i>0) );
    
    %if nr of non-integer entries is zero then all of the variables
    %that are one are potential fixings. Might need tolerance here
    %aswell.
    if counter_non_integer_variables == 0;
        B_star = B_i;
        % !ABDOU! don't you return here!
    end   
    
    
    %Spacer step is done if no progress for k_s steps
    if mod(k,k_s) == 0 && k > 0;
        %The index of the largest fractional variable is added to the
        %potential fixings vector.
        
        %Check index of fractionals that are between 0 and 1
        index = find(x_i ~= 0 & x_i ~= 1 );
        %Check index of fractionals that are between 0 and 1 not already in B_star
        fractional_index = setdiff(index , B_star);
        %array for all fractionals between 0 and 1
        fractionals = zeros(length(fractional_index),1);
        %so long as not all values in x_i is 0 or 1
        if isempty(fractional_index) == 0; 
            %add all the fractional values to our array for fractional
            %values  
            fractionals(:,1) = x_i(fractional_index);
            
            %find the index of the maximum fractional in fractionals.
            [~, max_fractional_index_in_fractionals] = max(fractionals);
            
            % (TO CHECK)
            %find the index of corresponding maximal fractional in x_i
            j_star = fractional_index(max_fractional_index_in_fractionals) ;
            %Give bonus weight gamma to perturbation value of x_i(j_star)
            total_perturbation(j_star) = total_perturbation(j_star) + gamma;
            %Add x_i(j_star) to the list of potential fixings
            B_star = [B_star ;j_star];
        end
        
    %The cost vector is perturbed to hopefully drive fractionals x_i_k
    %towards integrality
    
    %when the potential function v_x_i increase we make progress and
    %update our set of potential fixings.
    if v_x_i > v_star;
        %Update the vector for potential fixings, potential function
        %and since we made progress we reduce the number of steps w/o
        %progress.
        B_star = union(B_star, B_i); v_star = v_x_i; k = k - 1;
    end
    %the perturbation  made to all elements in cost vector w
    % NOTE: w_p = 1 (warm up)
    perturbation = alfa*w_p.*(x_i).^2; 
    %The total perturbaiton over all iterations of algoritm
    total_perturbation = total_perturbation + perturbation;
    end      
    i = i + 1; k = k + 1;

end
%If B_star is empty then choose a potential variable to fix by
%strongbranching. May also try heuristically to fix the highest fraction
if isempty(B_star) == 1;
    j_star = strongbranching(x_i,l,u);
    B_star = j_star;
end