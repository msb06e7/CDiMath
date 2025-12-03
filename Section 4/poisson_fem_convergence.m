% poisson_fem_convergence.m
%
% Numerical validation for the 2D Poisson problem
%   -Delta u = f in (0,1)^2,  u = 0 on boundary
% using conforming P1 finite elements on uniform triangulations.

clear; clc;

% Initial number of intervals per direction
N0 = 4;           % h0 = 1/N0
numLevels = 5;    % refinement levels k = 1,...,numLevels

% Loop over test problems
% tp = 1 : u = sin(pi x) sin(pi y)
% tp = 2 : u = x^2(1-x)^2 y^2(1-y)^2
for tp = 1:2
    fprintf('==============================================\n');
    fprintf('Test problem %d\n', tp);
    fprintf('==============================================\n');

    h_values = zeros(numLevels,1);
    E_H1     = zeros(numLevels,1);
    E_L2     = zeros(numLevels,1);

    for k = 1:numLevels
        % Number of intervals and mesh size
        N = N0 * 2^(k-1);      % number of intervals in each direction
        h = 1/N;
        h_values(k) = h;

        % Generate mesh (uniform triangulation of unit square)
        [coords, elements, boundaryNodes] = create_uniform_mesh(N, N);

        % Select test problem: f, exact solution, and its gradient
        [f_handle, u_exact, grad_u_exact] = select_test_problem(tp);

        % Assemble stiffness matrix and load vector
        [A, b] = assemble_poisson_P1(coords, elements, f_handle);

        % Apply homogeneous Dirichlet boundary conditions: u = 0 on boundary
        numNodes = size(coords,1);
        interior = true(numNodes,1);
        interior(boundaryNodes) = false;

        A_ii = A(interior, interior);
        b_i  = b(interior);

        % Solve linear system
        u_i = A_ii \ b_i;
        u_h = zeros(numNodes,1);
        u_h(interior) = u_i;

        % Compute errors in H1 and L2 norms
        [err_H1, err_L2] = compute_errors_P1(coords, elements, u_h, ...
                                             u_exact, grad_u_exact);

        E_H1(k) = err_H1;
        E_L2(k) = err_L2;

        fprintf('Level %d: N = %3d, h = %.4e,  ||e||_H1 = %.4e,  ||e||_L2 = %.4e\n', ...
                 k, N, h, err_H1, err_L2);
    end

    % Estimate convergence rates
    p_H1 = zeros(numLevels-1,1);
    p_L2 = zeros(numLevels-1,1);
    for k = 2:numLevels
        p_H1(k-1) = log(E_H1(k-1)/E_H1(k)) / log(h_values(k-1)/h_values(k));
        p_L2(k-1) = log(E_L2(k-1)/E_L2(k)) / log(h_values(k-1)/h_values(k));
    end

    fprintf('\nConvergence rates (Test problem %d):\n', tp);
    fprintf('  k   h          ||e||_H1      rate_H1   ||e||_L2      rate_L2\n');
    fprintf('-----------------------------------------------------------------\n');
    for k = 1:numLevels
        if k == 1
            fprintf('  %d   %.3e   %.3e      ---      %.3e      ---\n', ...
                    k, h_values(k), E_H1(k), E_L2(k));
        else
            fprintf('  %d   %.3e   %.3e   %.3f   %.3e   %.3f\n', ...
                    k, h_values(k), E_H1(k), p_H1(k-1), E_L2(k), p_L2(k-1));
        end
    end
    fprintf('\n');

    % Log-log plot of H1 and L2 errors vs h
    figure(tp); clf;

    loglog(h_values, E_H1, '-o', ...
           'LineWidth', 1.5, 'MarkerSize', 6, 'Color', 'b'); hold on;
    loglog(h_values, E_L2, '-s', ...
           'LineWidth', 1.5, 'MarkerSize', 6, 'Color', 'r');

    % Reference lines: O(h), O(h^2)
    loglog(h_values, h_values, '--', ...
           'LineWidth', 1.2, 'Color', 'k');         % O(h)
    loglog(h_values, h_values.^2, ':', ...
           'LineWidth', 1.2, 'Color', 'k');         % O(h^2)

    hold off;

    set(gca, 'XDir', 'reverse');
    xlabel('h');
    ylabel('error');
    legend('||e||_{H^1}', '||e||_{L^2}', 'O(h)', 'O(h^2)', ...
           'Location', 'best');
    title(sprintf('Error vs h (Test problem %d)', tp));
    grid on;
end