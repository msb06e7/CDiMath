function [coords, elements, boundaryNodes] = create_uniform_mesh(Nx, Ny)
%CREATE_UNIFORM_MESH  Uniform triangulation of unit square (0,1)x(0,1)
%
%   Nx, Ny : number of intervals in x and y directions
%
%   coords        : (numNodes x 2) node coordinates
%   elements      : (numElems x 3) connectivity (indices into coords)
%   boundaryNodes : logical index of boundary nodes

% Grid points
x = linspace(0,1,Nx+1);
y = linspace(0,1,Ny+1);
[XX,YY] = meshgrid(x,y);

coords = [XX(:), YY(:)];
numNodes = size(coords,1);

% Connectivity: two triangles per rectangle
elements = [];
for j = 1:Ny
    for i = 1:Nx
        % Node numbers in the rectangle (i,j) to (i+1,j+1)
        n1 = (j-1)*(Nx+1) + i;
        n2 = n1 + 1;
        n3 = n1 + (Nx+1);
        n4 = n3 + 1;

        % Two triangles: (n1,n2,n4) and (n1,n4,n3)
        elements = [elements;
                    n1, n2, n4;
                    n1, n4, n3];
    end
end

% Boundary nodes: x=0 or x=1 or y=0 or y=1
eps = 1e-12;
bx = (abs(coords(:,1)) < eps) | (abs(coords(:,1)-1) < eps);
by = (abs(coords(:,2)) < eps) | (abs(coords(:,2)-1) < eps);
boundaryNodes = bx | by;
end