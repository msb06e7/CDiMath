function [gd, ns, sf] = CarGeom()
    % CarGeom
    % Geometry for a Cybertruck-like body over flat ground
    % in a large rectangular channel.
    %
    % 조건 요약:
    % - 기본 차체 다각형에서 하부 직사각형 높이를 줄임.
    % - 지면과의 gap은 기존의 1.5배 (base 기준 0.15)로 유지.
    % - 오른쪽 변 길이는 기존의 9/7 배가 되도록 C의 높이를 조정.
    % - 차량 최상단 꼭짓점 D는 하부 변 AB의 1/3 지점 위로 수평 이동.
    % - 마지막으로, 상부 세 점 C,D,E를 왼쪽 세로선분( A–E ) 길이의 1/8 만큼 위로 올림.
    % - 전체 도메인은 scale=10 배 확대.

    %-----------------------------
    % 0. Global scale (domain size)
    %-----------------------------
    scale = 10.0;  % [-3,3]x[-2,2] -> [-30,30]x[-20,20]

    %-----------------------------
    % 1. Outer box (base coordinates, BEFORE scale)
    %-----------------------------
    xL0 = -3; xR0 =  3;
    yB0 = -2; yT0 =  2;

    xL = scale * xL0;
    xR = scale * xR0;
    yB = scale * yB0;
    yT = scale * yT0;

    R1 = [3; 4; ...
          xL;  xR;  xR;  xL; ...
          yB;  yB;  yT;  yT];

    %-----------------------------
    % 2. Original car polygon (base coords, BEFORE modification)
    %
    %   A: front bottom   (-1.7, -0.4)
    %   B: rear  bottom   ( 2.0, -0.4)
    %   C: rear  top      ( 2.0,  0.4)
    %   D: roof peak      (-0.5,  0.9)
    %   E: front top      (-1.7,  0.4)
    %-----------------------------
    x0 = [ ...
        -1.7, ... % A
         2.0, ... % B
         2.0, ... % C
        -0.5, ... % D (임시, 아래에서 이동)
        -1.7  ... % E
    ];

    y0_orig = [ ...
        -0.4, ... % A bottom (original)
        -0.4, ... % B bottom (original)
         0.4, ... % C top of rectangle
         0.9, ... % D roof peak
         0.4  ... % E top of rectangle
    ];

    %----- D를 하부 길이의 1/3 지점 위로 수평 이동 -----
    xA = x0(1);
    xB = x0(2);
    xD_target = xA + (5/12) * (xB - xA);   % A + (1/3)(B-A)
    x0(4) = xD_target;

    %-----------------------------
    % 3. 하부 직사각형 세로 길이 줄이기
    %    - top(E,C)는 유지, bottom(A,B)만 올리기
    %-----------------------------
    y_top_rect = y0_orig(3);        % = 0.4
    desired_rect_height = 0.5;      % 원래 0.8 -> 0.5로 얇게

    y_bottom_new = y_top_rect - desired_rect_height;  % 0.4 - 0.5 = -0.1

    y1 = y0_orig;
    y1(1) = y_bottom_new;  % A bottom = -0.1
    y1(2) = y_bottom_new;  % B bottom = -0.1
    % 이 시점:
    %   A,B: -0.1
    %   C,E:  0.4
    %   D:    0.9

    %-----------------------------
    % 4. 오른쪽 위 꼭짓점 C 높이 조정
    %    → 오른쪽 변 길이를 기존의 9/7 배로
    %-----------------------------
    bottom_now = y1(2);         % B의 y = -0.1
    L_now     = y1(3) - y1(2);  % 기존 길이 = 0.5
    L_new     = (9/7) * L_now;  % 새 길이

    yC_new = bottom_now + L_new;  % 새 C_y

    y1(3) = yC_new;  % C만 올림, E와 D는 그대로

    %-----------------------------
    % 5. 차체 전체를 아래로 평행이동
    %    → 지면과의 gap을 기존의 1.5배로 (0.15) 맞추기
    %-----------------------------
    yGtop0      = -1.0;              % ground top (base coords)
    target_gap0 = 0.15;              % 0.1 의 1.5배
    target_bottom0 = yGtop0 + target_gap0;   % = -0.85

    bottom_after_shrink = y1(1);     % A의 y ( = -0.1 )
    dy = target_bottom0 - bottom_after_shrink;   % = -0.85 - (-0.1) = -0.75

    y0 = y1 + dy;   % A..E 모두 같은 만큼 아래로 평행이동
    % 이 상태에서:
    %   A,B bottom = -0.85 (gap = 0.15 유지)
    %   C,D,E도 같이 내려감

    %-----------------------------
    % 6. 상부 세 점(C,D,E)을 왼쪽 세로선분( A–E ) 길이의 1/8만큼 위로 올리기
    %    - A는 그대로 (gap 유지)
    %    - E의 위치를 기준으로 세로 길이 측정
    %-----------------------------
    A_y = y0(1);        % A의 y
    E_y = y0(5);        % E의 y
    left_vert_length = E_y - A_y;        % 왼쪽 세로선분 길이
    delta = left_vert_length / 8;        % 그 1/8 만큼 위로 올릴 양

    % C(3), D(4), E(5)를 위로 delta만큼 올림
    y0(3) = y0(3) + delta;   % C
    y0(4) = y0(4) + delta;   % D
    y0(5) = y0(5) + delta;   % E

    % A,B는 그대로 → 지면과 gap은 그대로 유지

    %-----------------------------
    % 7. 최종 scaled car polygon
    %-----------------------------
    xv = scale * x0;
    yv = scale * y0;

    nCar = numel(xv);
    C1 = [2; nCar; xv(:); yv(:)];

    %-----------------------------
    % 8. Ground rectangle (base coords)
    %-----------------------------
    xGleft0  = xL0;
    xGright0 = xR0;
    yGbot0   = yB0;

    xGleft  = scale * xGleft0;
    xGright = scale * xGright0;
    yGbot   = scale * yGbot0;
    yGtop   = scale * yGtop0;

    G1 = [3; 4; ...
          xGleft;  xGright; xGright; xGleft; ...
          yGbot;   yGbot;   yGtop;   yGtop];

    %-----------------------------
    % 9. Pad columns to same length
    %-----------------------------
    lenR1 = numel(R1);
    lenG1 = numel(G1);
    lenC1 = numel(C1);
    maxL  = max([lenR1, lenG1, lenC1]);

    R1p = [R1; zeros(maxL - lenR1, 1)];
    G1p = [G1; zeros(maxL - lenG1, 1)];
    C1p = [C1; zeros(maxL - lenC1, 1)];

    gd = [R1p, G1p, C1p];

    ns = char('R1', 'G1', 'C1').';
    sf = 'R1-G1-C1';
end