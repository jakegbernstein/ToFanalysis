function [xyz, ptcloud] = sensor2xyz(datstruct, params, makeplot)

switch nargin
    case 1
        params = struct();
        makeplot = false;
    case 2
        makeplot = false;
end
    
if ~isfield(params,'focallength')
    params.focallength = 5.5; %mm
end

if ~isfield(params,'minqual')
    params.minqual = 100;
end

if ~isfield(params,'offset')
    params.offset =0;
end

if ~isfield(params,'LEDoffset')
    params.LEDoffset = -4*.0254;
end

PIXELWIDTH = 0.020; %mm
IMAGESIZE = [240,320];
IMAGECENTER = (IMAGESIZE + [1,1])/2;

delta = atan(PIXELWIDTH/params.focallength);
n = 1;
for i = 1:size(datstruct.distances,1)
    for j = 1:size(datstruct.distances, 2)
        if datstruct.qualities(i,j) > params.minqual
            %xyz(n,:) = pixel2xyzLEDoffset([i,j],datstruct.distances(i,j) + params.offset);
            xyz(n,:) = pixel2xyz([i,j],datstruct.distances(i,j) + params.offset);
            n = n+1;
        end
    end
end

ptcloud = pointCloud(xyz);
if makeplot
    figure
    pcshow(ptcloud)
end

function xyz = pixel2xyzLEDoffset(pixelind,d)    
    %
    offcenter = pixelind - IMAGECENTER;
    decl = delta*offcenter(1);
    D = 2*d;
    r = (D^2 - params.LEDoffset^2)/(2*(D-params.LEDoffset*sin(decl)));
    %
    
    theta = delta*sqrt(sum(offcenter.^2));
    phi = atan(offcenter(1)/offcenter(2));
    %
    if offcenter(2) < 0
        phi = phi + pi;
    end
    z = r*cos(theta);
    x = r*sin(theta)*cos(phi);
    y = r*sin(theta)*sin(phi);
    xyz = [x, y, z];
end

function xyz = pixel2xyz(pixelind,r)
    offcenter = pixelind - IMAGECENTER;
    theta = delta*sqrt(sum(offcenter.^2));
    phi = atan(offcenter(1)/offcenter(2));
    if offcenter(2) < 0
        phi = phi + pi;
    end
    z = r*cos(theta);
    x = r*sin(theta)*cos(phi);
    y = r*sin(theta)*sin(phi);
    xyz = [x, y, z];
end

end

