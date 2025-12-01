function CarPotentialFlow2D()
    % CarPotentialFlow2D
    % Finite element approximation of potential flow around a car-like body
    % over flat ground, using the geometry defined in CarGeom.m.
    %
    % Domain: outer rectangle minus ground minus car polygon.
    % PDE:    -Delta Phi = 0
    % BC:     Inflow (left)  : dPhi/dn = 1
    %         Outflow (right): Phi = 0 (penalty Robin)
    %         Walls + car + ground: dPhi/dn = 0 (natural Neumann)
    %
    % Velocity: u = -grad Phi  → flow from left to right.

    %--------------------------------------------------------------
    % 1. Geometry and initial mesh
    %--------------------------------------------------------------
    [gd, ns, sf] = CarGeom();
    g = decsg(gd, sf, ns);

    % Outer box coordinates from first column (R1)
    R1 = gd(:,1);
    xRect = R1(3:6);
    yRect = R1(7:10);
    xL = min(xRect);
    xR = max(xRect);

    % initial mesh (size relative to domain length)
    domainSize = xR - xL;
    hmax = 0.02 * domainSize;   % 필요하면 0.05 정도로 더 줄여도 됨
    [p, e, t] = initmesh(g, 'hmax', hmax);

    % --- Mesh figure ---
    figure;
    pdemesh(p, e, t);
    axis equal;
    xlabel('x_1'); ylabel('x_2');
    title('FEM mesh for car + ground geometry');

    %--------------------------------------------------------------
    % 2. Diffusion coefficient a(x,y) = 1 (Laplace)
    %--------------------------------------------------------------
    a = @(x,y) 1 + 0.*x;
    A = StiffnessAssembler2D(p, t, a);

    %--------------------------------------------------------------
    % 3. Robin + Neumann boundary conditions
    %--------------------------------------------------------------
    [R, r] = RobinAssembler2D(p, e, ...
                              @(x,y) KappaCar(x,y,xL,xR), ...
                              @(x,y) gD_car(x,y), ...
                              @(x,y) gN_car(x,y,xL,xR));

    % solve linear system
    Phi = (A + R) \ r;

    %--------------------------------------------------------------
    % 4. Velocity u = -grad Phi and Bernoulli pressure
    %--------------------------------------------------------------
    [Phi_x, Phi_y] = pdegrad(p, t, Phi);
    u1 = -Phi_x;
    u2 = -Phi_y;

    speed = sqrt(u1.^2 + u2.^2);
    pB    = 0.5 * (1 - speed.^2);   % normalized Bernoulli pressure

    %--------------------------------------------------------------
    % 5. Plots
    %--------------------------------------------------------------

    % (a) Equipotential lines of Phi
    figure;
    pdeplot(p, e, t, 'XYData', Phi, 'Contour', 'on', 'ColorBar', 'on');
    axis equal;
    xlabel('x_1'); ylabel('x_2');
    title('Equipotential lines of \Phi around the car');

    % (b) Velocity field u = -grad Phi
    figure;
    pdeplot(p, e, t, 'FlowData', [u1; u2]);
    axis equal;
    xlabel('x_1'); ylabel('x_2');
    title('Velocity field u around the car');

    % (c) Normalized Bernoulli pressure p_B
    figure;
    pdeplot(p, e, t, 'XYData', pB, 'Contour', 'on', 'ColorBar', 'on');
    axis equal;
    xlabel('x_1'); ylabel('x_2');
    title('Normalized Bernoulli pressure p_B around the car');
end

% -------------------------------------------------------------------------
% Stiffness matrix assembly for -div(a grad u)
% -------------------------------------------------------------------------
function A = StiffnessAssembler2D(p, t, a)
    np = size(p, 2);
    nt = size(t, 2);
    A  = sparse(np, np);

    for K = 1:nt
        nodes = t(1:3, K).';
        xK = [p(1, nodes).' p(2, nodes).'];  % [x1 y1; x2 y2; x3 y3]

        [area, grad_phi] = localP1Geometry(xK);

        % element-center coefficient a
        xc = mean(xK(:,1));
        yc = mean(xK(:,2));
        aK = a(xc, yc);

        Ke = zeros(3,3);
        for i = 1:3
            for j = 1:3
                Ke(i,j) = Ke(i,j) + aK * area * dot(grad_phi(i,:), grad_phi(j,:));
            end
        end

        A(nodes, nodes) = A(nodes, nodes) + Ke;
    end
end

% -------------------------------------------------------------------------
% Local P1 geometry: area + gradients of hat functions
% -------------------------------------------------------------------------
function [area, grad_phi] = localP1Geometry(xK)
    x1 = xK(1,1); y1 = xK(1,2);
    x2 = xK(2,1); y2 = xK(2,2);
    x3 = xK(3,1); y3 = xK(3,2);

    B = [x2 - x1, x3 - x1;
         y2 - y1, y3 - y1];

    area = 0.5 * abs(det(B));

    C = inv(B).';    % columns = grad(lambda_2), grad(lambda_3)
    grad_lambda2 = C(:,1).';
    grad_lambda3 = C(:,2).';
    grad_lambda1 = -grad_lambda2 - grad_lambda3;

    grad_phi = [grad_lambda1;
                grad_lambda2;
                grad_lambda3];
end

% -------------------------------------------------------------------------
% Robin boundary assembler: dPhi/dn + kappa (Phi - gD) = gN
% -------------------------------------------------------------------------
function [R, r] = RobinAssembler2D(p, e, Kappa, gD, gN)
    np = size(p, 2);
    ne = size(e, 2);
    R  = sparse(np, np);
    r  = zeros(np, 1);

    for k = 1:ne
        n1 = e(1, k); n2 = e(2, k);
        x1 = p(:, n1); x2 = p(:, n2);

        edge_vec = x2 - x1;
        edge_len = norm(edge_vec);
        xm = 0.5 * (x1 + x2);    % midpoint

        kappa_m = Kappa(xm(1), xm(2));
        gD_m    = gD(xm(1), xm(2));
        gN_m    = gN(xm(1), xm(2));

        % if both zero, skip this edge
        if (kappa_m == 0) && (gN_m == 0)
            continue;
        end

        % 1D P1 mass matrix on the edge
        Ke = kappa_m * edge_len * [1/3 1/6;
                                   1/6 1/3];

        Fe = (kappa_m * gD_m + gN_m) * edge_len * [1/2; 1/2];

        nodes = [n1, n2];
        R(nodes, nodes) = R(nodes, nodes) + Ke;
        r(nodes)        = r(nodes)        + Fe;
    end
end

% -------------------------------------------------------------------------
% Boundary data for car configuration
% -------------------------------------------------------------------------
function val = KappaCar(x, y, xL, xR)
    % Strong penalty on outflow (right boundary) only:
    val = zeros(size(x));
    L = xR - xL;
    outflow = (x > xR - 0.05*L);
    val(outflow) = 1.0e6;
end

function val = gD_car(x, y)
    % Dirichlet value: Phi ≈ 0 on outflow
    val = zeros(size(x));
end

function val = gN_car(x, y, xL, xR)
    % Neumann flux: dPhi/dn = 1 on inflow (left boundary)
    % Outward normal n ≈ (-1,0) on the left, so
    %   dPhi/dn = grad Phi · n ≈ -dPhi/dx = 1 ⇒ dPhi/dx ≈ -1
    % which gives u = -grad Phi ≈ (1,0): flow left → right.
    val = zeros(size(x));
    L = xR - xL;
    inflow = (x < xL + 0.05*L);
    val(inflow) = 1.0;
end