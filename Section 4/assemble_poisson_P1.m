function [A, b] = assemble_poisson_P1(coords, elements, f_handle)
%ASSEMBLE_POISSON_P1  Assemble stiffness matrix and load vector
% for -Delta u = f with P1 elements on a given triangulation.
%
% coords   : (numNodes x 2)
% elements : (numElems x 3)
% f_handle : @(x,y) f(x,y)

numNodes  = size(coords,1);
numElems  = size(elements,1);

A = sparse(numNodes, numNodes);
b = zeros(numNodes,1);

% Quadrature rule on reference triangle: 3-point (order 2)
% Reference barycentric points (for hat-K: (0,0), (1,0), (0,1)):
bary = [ 1/6, 1/6, 4/6;
         4/6, 1/6, 1/6;
         1/6, 4/6, 1/6 ];
w = [1/3, 1/3, 1/3];  % weights sum to 1; area factor will multiply later

for K = 1:numElems
    nodes = elements(K,:);
    xK = coords(nodes,:);  % 3x2

    % Compute element area and gradients of P1 basis functions
    [area, grad_phi] = local_P1_geometry(xK);
    % grad_phi: 3x2, row i = grad(phi_i) (constant on K)

    % Local stiffness matrix
    Ke = zeros(3,3);
    for i = 1:3
        for j = 1:3
            Ke(i,j) = area * (grad_phi(i,:)*grad_phi(j,:)');
        end
    end

    % Local load vector (using quadrature)
    be = zeros(3,1);
    for q = 1:3
        % Physical quadrature point: x_q = sum_i lambda_i * a_i
        lambda = bary(q,:);
        xq = lambda * xK;   % 1x2
        fq = f_handle(xq(1), xq(2));

        % P1 basis at barycentric point: just lambda_i
        phi_q = lambda(:);  % 3x1

        be = be + w(q) * fq * phi_q * area;
    end

    % Assembly
    for i = 1:3
        I = nodes(i);
        b(I) = b(I) + be(i);
        for j = 1:3
            J = nodes(j);
            A(I,J) = A(I,J) + Ke(i,j);
        end
    end
end
end