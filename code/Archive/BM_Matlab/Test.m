clc
clear all
%Mall
M = zeros(15,60);
n = numel(M);
%Nullvägen
A_null = M;
tmp = ones(1,60);
A_null(end,:) = tmp;

%Roterad identitetväg
I = eye(15);
I_flip = flipud(I);

I_1 = M;
I_1(1:15,1:15) = I_flip;
I_1(1,16:end) = 1;

I_2 = M;
I_2(end,1) = 1;
I_2(1:15,2:16) = I_flip;
I_2(1,17:end) = 1;

I_3 = M;
I_3(end,1:2) = 1;
I_3(1:15,3:17) = I_flip;
I_3(1,18:end) = 1;

I_4 = M;
I_4(end,1:3) = 1;
I_4(1:15,4:18) = I_flip;
I_4(1,19:end) = 1;

I_5 = M;
I_5(end,1:4) = 1;
I_5(1:15,5:19) = I_flip;
I_5(1,20:end) = 1;

I_6 = M;
I_6(end,1:45) = 1;
I_6(1:15,46:60) = I_flip;

%Långsam väg
L_1 = M;
k = 1;
for i = 1:15;
    L_1(end+1-i,k:k+2) = 1;
    k = k + 2;
end
L_1(1,k+1:end) = 1;

L_2 = M;
k = 4;
L_2(end,1:k - 1) = 1;
for i = 1:15;
    L_2(end+1-i,k:k+2) = 1;
    k = k + 2;
end
L_2(1,k+1:end) = 1;

L_3 = M;
k = 8;
L_3(end,1:k - 1) = 1;
for i = 1:15;
    L_3(end+1-i,k:k+2) = 1;
    k = k + 2;
end
L_3(1,k+1:end) = 1;

L_4 = M;
k = 16;
L_4(end,1:k - 1) = 1;
for i = 1:15;
    L_4(end+1-i,k:k+2) = 1;
    k = k + 2;
end
L_4(1,k+1:end) = 1;

L_5 = M;
k = 30;
L_5(end,1:k - 1) = 1;
for i = 1:15;
    L_5(end+1-i,k:k+2) = 1;
    k = k + 2;
end
% L_5(1,k+1:end) = 1

%Reshape for vectors
B_null = reshape(A_null,[n,1]);
C_1 = reshape(I_1',[n,1]);
C_2 = reshape(I_2',[n,1]);
C_3 = reshape(I_3',[n,1]);
C_4 = reshape(I_4',[n,1]);
C_5 = reshape(I_5',[n,1]);
C_6 = reshape(I_6',[n,1]);
D_1 = reshape(L_1',[n,1]);
D_2 = reshape(L_2',[n,1]);
D_3 = reshape(L_3',[n,1]);
D_4 = reshape(L_4',[n,1]);
D_5 = reshape(L_5',[n,1]);

%Inequality constraint matrix
A = [C_1 C_2 C_3 C_4 C_5 C_6 D_1 D_2 D_3 D_4 D_5 C_1 C_2 C_3 C_4 C_5 C_6 D_1 D_2 D_3 D_4 D_5 C_1 C_2 C_3 C_4 C_5 C_6 D_1 D_2 D_3 D_4 D_5];

r = size(A,2)/11;

%Inequality capacity
b = ones(size(A,1),1);
b(1:60) = size(A,2)/11;
b(841:900) = size(A,2)/11;

%Equality constraints
Aeq = zeros(r,size(A,2));
Aeq(1,1:11) = 1;
Aeq(2,12:22) = 1;
Aeq(3,23:33) = 1;

%Equality capacity
beq = [1 1 1]';

%Bounds
lb = zeros(size(A,2),1);
ub = ones(size(A,2),1);

%revenues
f = -ones(size(A,2),1);

[x,fval,exitflag,output,lambda] = linprog(f,A,b,Aeq,beq,lb,ub,[]);

