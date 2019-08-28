function [xyz, ptcloud] = sensor2xyz(datstruct, params)

switch nargin
    case 1
        params = struct();
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

PIXELWIDTH = 0.020; %mm
IMAGESIZE = [240,320];
IMAGECENTER = (IMAGESIZE + [1,1])/2;

delta = atan(PIXELWIDTH/params.focallength);
n = 1;
for i = 1:size(datstruct.distances,1)
    for j = 1:size(datstruct.distances, 2)
        if datstruct.qualities(i,j) > params.minqual
            xyz(n,:) = pixel2xyz([i,j],datstruct.distances(i,j) + params.offset);
            n = n+1;
        end
    end
end

ptcloud = pointCloud(xyz);
figure
pcshow(ptcloud)

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

