%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  Test program: Bundle Iteration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

global DEBUG
DEBUG = 1;

global Phi % objective value
global i
global mu

% gereral parameters
M = 3;
N = 20;
k_max = 20;
u_init = 1;
epsilon = 10^-1; % accuracy tolerance

%%% Bundle iteration
it_max = 20;
err = zeros(1,it_max);
for it=1:it_max
    if DEBUG
         fprintf('Test BM starting ... \n');
    end
    stop = false;
    k = 1;
    x = rand(N,M);
    serious = zeros(1,k_max);
    while ((~stop) && (k < k_max))
        
        % display iteration numberl
        if DEBUG
            fprintf('>>> iteration %d ... \n',k);
        end
        
        [stop, serious_] = BM(k, k_max, epsilon, x, u_init);
        serious(k) = serious_;
        
        % next iteration
        k = k+1;
    end
    err(it) = norm(mu-20);
end

plot(1:it_max, err, '-ro', 'LineWidth',2);
title('absolute error')
ylabel('error')
xlabel('iteration')