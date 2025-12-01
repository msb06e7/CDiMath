function [f_handle, u_exact, grad_u_exact] = select_test_problem(tp)
%SELECT_TEST_PROBLEM  Define f, exact solution u, and grad u
%
%   tp = 1 : u = sin(pi x) sin(pi y)
%   tp = 2 : u = x^2(1-x)^2 y^2(1-y)^2

if tp == 1
    % u = sin(pi x) sin(pi y)
    u_exact = @(x,y) sin(pi*x).*sin(pi*y);

    % grad u = (du/dx, du/dy)
    grad_u_exact = @(x,y) [ ...
        pi*cos(pi*x).*sin(pi*y), ...
        pi*sin(pi*x).*cos(pi*y) ];

    % f = -Delta u = 2 pi^2 sin(pi x) sin(pi y)
    f_handle = @(x,y) 2*pi^2*sin(pi*x).*sin(pi*y);

elseif tp == 2
    % u = x^2(1-x)^2 y^2(1-y)^2
    u_exact = @(x,y) (x.^2 .* (1-x).^2) .* (y.^2 .* (1-y).^2);

    % Compute grad u explicitly:
    % Let u(x,y) = g(x)*g(y), g(t) = t^2(1-t)^2
    % g'(t) = 2t(1-t)^2 - 2t^2(1-t) = 2t(1-t)(1-2t)
    gx  = @(t) t.^2 .* (1-t).^2;
    gpx = @(t) 2*t.*(1-t).*(1-2*t);

    grad_u_exact = @(x,y) [ ...
        gpx(x).*gx(y), ...
        gx(x).*gpx(y) ];

    % f = -Delta u = -(u_xx + u_yy)
    % We could derive u_xx, u_yy explicitly, but for testing purposes
    % it's often simpler to compute them symbolically or approximate.
    % 여기서는 정확한 f를 쓰고 싶다면 미리 손으로 u_xx, u_yy를 계산해서 넣어주면 됨.
    % 간단히 위해 여기서는 numerical differentiation을 쓰지 않고,
    % 미리 계산해 둔 형태를 사용하자.

    % g''(t) = 2(1-t)^2 - 8t(1-t) + 2t^2
    gpp = @(t) 2*(1-t).^2 - 8*t.*(1-t) + 2*t.^2;

    f_handle = @(x,y) -( gpp(x).*gx(y) + gx(x).*gpp(y) );

else
    error('Unknown test problem.');
end
end