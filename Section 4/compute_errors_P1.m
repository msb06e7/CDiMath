function [err_H1, err_L2] = compute_errors_P1(coords, elements, u_h, ...
                                              u_exact, grad_u_exact)
%COMPUTE_ERRORS_P1  Compute H1 and L2 errors for P1 FEM solution.
%
% coords        : (numNodes x 2)
% elements      : (numElems x 3)
% u_h           : (numNodes x 1) FE solution
% u_exact       : @(x,y) exact solution
% grad_u_exact  : @(x,y) [u_x, u_y]

numElems = size(elements,1);

err_L2_sq = 0;
err_H1_semi_sq = 0;

% Quadrature rule (same as assembly)
bary = [ 1/6, 1/6, 4/6;
         4/6, 1/6, 1/6;
         1/6, 4/6, 1/6 ];
w = [1/3, 1/3, 1/3];

for K = 1:numElems
    nodes = elements(K,:);
    xK = coords(nodes,:);      % 3x2
    uK = u_h(nodes);           % 3x1

    [area, grad_phi] = local_P1_geometry(xK);

    % Gradient of u_h is constant on K: sum_i u_i * grad phi_i
    grad_uh = (uK.' * grad_phi);   % 1x2

    % Quadrature for L2 and H1 seminorm errors
    for q = 1:3
        lambda = bary(q,:);
        xq = lambda * xK;          % 1x2
        x = xq(1); y = xq(2);

        uq_exact = u_exact(x,y);
        grad_uq_exact = grad_u_exact(x,y);   % 1x2

        % u_h at quadrature point (P1 interpolation)
        uq_h = lambda * uK;        % scalar

        e_val = uq_exact - uq_h;
        e_grad = grad_uq_exact - grad_uh;

        err_L2_sq       = err_L2_sq       + w(q) * e_val^2       * area;
        err_H1_semi_sq  = err_H1_semi_sq  + w(q) * (e_grad*e_grad.') * area;
    end
end

err_L2 = sqrt(err_L2_sq);
err_H1 = sqrt(err_L2_sq + err_H1_semi_sq);   % full H1 norm
end