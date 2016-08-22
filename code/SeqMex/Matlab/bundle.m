%bundle Computes the new dual iterate using aggregate bundle quadratic method
function [mu_new, lambda, Psi_new, u_new, stop, SPs_id, i_new, Phi_new, g_new, cst_new] = ...
    bundle(k, paths2fix, c, mu_curr, Psi_curr, Phi, g, u_curr, i_curr, cst, Restricted, ...
    Cap)
%% macro
global DISAGG
global DEBUG

%% Parameters
m_L = 0.1; % step quality parameter
u_min = 10^-10; % minimal value for the step size

%% New prices/multipliers
% Solve the quadratic problem and get the predicted dual value
[y, Phi_predicted, lambda] = bundlequadprog(mu_curr, Psi_curr, g, u_curr, Cap, k);

%% New objective value
% get the achieved dual value
if(Restricted)
    %     [totalRev, cap_cons, SPs_id, Phi_SP] = ...
    %         SP_RMLP(capCons, y, paths2fix, c);
else
    [totalRev, cap_cons, SPs_id, Phi_SP] = ...
        mexSP('compute', y);
end
[Phi_new, g_new, cst_new] = compute_phi_g(totalRev, cap_cons, y, Phi_SP, Cap);
Sum_Phi_new = sum(Phi_new) + cst_new;

%% Descents
% current objective
Phi_curr =  sum(Phi(i_curr, :)) + cst(i_curr);

% descents
achieved = Phi_curr - Sum_Phi_new;
predicted = Phi_curr - Phi_predicted;

%% (non-)serious iteration
if predicted < 10^-13
    if(DEBUG)
        disp(predicted);
    end
    stop = true;
    u_new = u_curr;
    i_new = i_curr;
    mu_new = mu_curr;
else
    stop = false;
    % Check if we take a serious step or not
    ratio = achieved/predicted;
    if ratio >= m_L || k == 1 % serious step
        i_new = k+1;
        u_new = max([u_min u_curr/10 2*u_curr*(1-ratio)]); % new step parameter
        mu_new = y;
        % update Psi
        cc = zeros(size(Psi_curr));
        if(DISAGG)
            R = size(Psi_curr,2);
            for r=1:R
                for l=1:k
                    cg = g(:,:,r,l);
                    cc(l,r) = cg(:)'*(y(:)-mu_curr(:));
                end
            end
        else
            for l=1:k
                cg = g(:,:,l);
                cc(l,1) = cg(:)'*(y(:)-mu_curr(:));
            end
        end
        Psi_curr = Psi_curr + cc;
    else % null step
        i_new = i_curr;
        u_new = min([10*u_curr 2*u_curr*(1-(ratio))]); % new step parameter
        mu_new = mu_curr;
    end
end
% add the new hyperplane
if(DISAGG)
    cc = zeros(size(Phi_new'));
    R = size(Phi_new,1);
    for r=1:R
        cg = g_new(:,:,r);
        cc(1,r) = cg(:)'*(mu_new(:)-y(:));
    end
    Psi_new = [Psi_curr; Phi_new' + cc];
else
    cc = g_new(:)'*(mu_new(:)-y(:));
    Psi_new = [Psi_curr; sum(Phi_new)+cst_new+ cc];
end