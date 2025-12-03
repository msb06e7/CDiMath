function [gd, ns, sf] = CarGeom()
    % CarGeom
    % Geometry for a Cybertruck-like body over flat ground
    % in a large rectangular channel.

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
        -0.5, ... % D
        -1.7  ... % E
    ];

    y0_orig = [ ...
        -0.4, ... % A bottom (original)
        -0.4, ... % B bottom (original)
         0.4, ... % C top of rectangle
         0.9, ... % D roof peak
         0.4  ... % E top of rectangle
    ];

    xA = x0(1);
    xB = x0(2);
    xD_target = xA + (5/12) * (xB - xA);   
    x0(4) = xD_target;

    %-----------------------------
    y_top_rect = y0_orig(3);        
    desired_rect_height = 0.5;      

    y_bottom_new = y_top_rect - desired_rect_height;  

    y1 = y0_orig;
    y1(1) = y_bottom_new;  
    y1(2) = y_bottom_new;  
    
    %-----------------------------
    bottom_now = y1(2);        
    L_now     = y1(3) - y1(2); 
    L_new     = (9/7) * L_now;  

    yC_new = bottom_now + L_new;  

    y1(3) = yC_new;  

    %-----------------------------
    yGtop0      = -1.0;              % ground top (base coords)
    target_gap0 = 0.15;             
    target_bottom0 = yGtop0 + target_gap0;   

    bottom_after_shrink = y1(1);    
    dy = target_bottom0 - bottom_after_shrink;   

    y0 = y1 + dy;  

    %-----------------------------
    A_y = y0(1);        
    E_y = y0(5);        
    left_vert_length = E_y - A_y;       
    delta = left_vert_length / 8;        

    
    y0(3) = y0(3) + delta;   
    y0(4) = y0(4) + delta;   
    y0(5) = y0(5) + delta;   

  

    %-----------------------------
    % 7.Scaled car polygon
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