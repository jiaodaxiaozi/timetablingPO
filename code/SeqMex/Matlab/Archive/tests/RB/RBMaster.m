%Indata is an initial fractional solution x using bundle method.

%NOTE1:Check if more input or output are needed

%random vector to check things work
x = rand(25,1);
%nr of fractional variables n
n = length(x);

%l and u are initially just zeros and ones which mean no variables are
%fixed yet
l = zeros(n,1);
u = ones(n,1);

%checking number of integer infeasibilities
n_ii = 0;
for x_i = x';
    if x_i ~= 0 && x_i ~= 1;
        n_ii = n_ii + 1;
    end
end


%Variable to check things work k
k = 0;
%loop until no integer infeasibilitys remain
while n_ii >= 1 && k ~= 50;
    B_star = GeneratePotentialFixings(l,u,x);
    [l,u] = ApplyFixings(B_star,l,u);
    k = k + 1;
end


%return integer vector x