%GeneratePotentialFixings Generate path fixings to send to the restricted
function [B_star,x_i] = GeneratePotentialFixings(l,u)

global DEBUG


global V

%initial values
epsilon = 0.2; delta = 0.3; %integrality tolerance: epsilon, constant used in potential function: delta,
alfa = 0.3; G = 1; % constant used to update costvector: alfa, bonus weight for spacer step: G, 
i=0; k=0; %Step counters, i is the number of iterations, k is the number of iterations without progress
k_s = 5; %Number of steps w/o progress before spacer step
k_max = 10; %maximum number of allowed iterations
n_i = true; %True if integer infeasibilities exist 
int_tol = 10^-3; %Tolerance for intervals around 0 and 1
B_star = []; %Vector of indexes of potential fixings
v_star = -inf; %Potential function is set to minus infinity initially
V_perturbed = ones(size(V(:))); 

while k < k_max;
    % display iteration number
    if DEBUG
       fprintf('- GPF: iteration %d ... \n',k);
    end
    %solve the Restricted Master LP for the current perbutated cost vector,
    %x_i is the fractional solutions.
    x_i = RMLP(V_perturbed,l,u);
    
    %calculate the potential function used to determine if we are making
    %progress or not.
    obj = sum(x_i(:).*V(:));
    
    %identify index for variables close to but not fixed.
    B_i = find(x_i > 1 - epsilon & l == 0 & u == 1);    
    
    %calculate the potential function
    v_x_i = obj + delta*length(B_i);
    
    %check if all entries in x_i are zeroes or ones.
    index = find((x_i >= int_tol) & (x_i <= 1-int_tol));
    %If integer solution then potential fixes found
    if isempty(index) == 1;
        n_i = false;
        B_star = B_i;
        return;
    end
          
    %Spacer step is done if no progress for k_s steps
    if mod(k,k_s) == 0 && k > 0 && n_i == true;
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
            j_star = fractional_index(max_fractional_index_in_fractionals);
            %Give bonus weight G to perturbation value of x_i(j_star)
            V_perturbed(j_star) = V_perturbed(j_star) + G;           
        end
    else
        if v_x_i > v_star;
            %Update variables
            B_star = B_i; v_star = v_x_i; k = k - 1;
        end
        %the perturbation  made to all elements in income matrix
        V_perturbed = alfa*V_perturbed.*(x_i).^2 + V_perturbed;
    end     
    i = i + 1;
    k = k + 1;
end
%If B_star is empty then choose a potential variable to fix by
%strongbranching.
if isempty(B_star) == 1;
    j_star = strongbranching(x_i,l,u,V);
    B_star = j_star;
end