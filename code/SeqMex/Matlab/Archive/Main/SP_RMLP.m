function [totalRev, cap_cons, SPs_id, Phi_SP] = SP_RMLP(capCons, y, paths2fix, c)

global R
global P
global B
global T
global Revenues

SPs_id = zeros(R,1);
Phi_SP = zeros(R,1);
cap_cons = zeros(B,T,R);
totalRev = zeros(R,1);
% compute the shortest path for each request
for r=1:R
    if(paths2fix(r) == 0)
        % init with the null path
        SPs_id(r) = 1;
        Phi_SP(r) = Revenues(1,r)*c(1,r);
        cap_cons(:,:,r) = zeros(B,T);
        totalRev(r) = 0;
        % choose the shortest path among the generated paths
        for p=2:P
            cc = double(capCons(:,:,p,r));
            Phi_tmp = Revenues(p,r)*c(p,r)-cc(:)'*y(:);
            if(Phi_tmp > Phi_SP(r))
                SPs_id(r) = p;
                Phi_SP(r) = Phi_tmp;
                cap_cons(:,:,r) = cc;
                totalRev(r) = Revenues(p,r)*c(p,r);
            end
        end
    else
        p = paths2fix(r);
        SPs_id(r) = p;
        cc = double(capCons(:,:,p,r));
        Phi_SP(r) = Revenues(p,r)* c(p,r)-cc(:)'*y(:);
        cap_cons(:,:,r) = capCons(:,:,p,r);
        totalRev(r) = Revenues(p,r)* c(p,r);
    end
end

end