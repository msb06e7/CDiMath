function [area, grad_phi] = local_P1_geometry(xK)
%LOCAL_P1_GEOMETRY  Area and gradients of local P1 basis on a triangle
%
% xK : (3 x 2) coordinates of triangle vertices [a1; a2; a3]
%
% Returns:
%   area     : area of K
%   grad_phi : (3 x 2) gradient of local basis functions
%              row i = grad phi_i (constant on K)

x1 = xK(1,1); y1 = xK(1,2);
x2 = xK(2,1); y2 = xK(2,2);
x3 = xK(3,1); y3 = xK(3,2);

B = [ x2 - x1, x3 - x1;
      y2 - y1, y3 - y1 ];   % 2x2

area = 0.5 * abs(det(B));

% Gradients of barycentric coordinates lambda_2, lambda_3 in physical coords
C = inv(B)';  % 2x2, columns are grad of lambda_2, lambda_3

grad_lambda2 = C(:,1)';  % 1x2
grad_lambda3 = C(:,2)';  % 1x2
grad_lambda1 = -grad_lambda2 - grad_lambda3;

grad_phi = [grad_lambda1;
            grad_lambda2;
            grad_lambda3];
end