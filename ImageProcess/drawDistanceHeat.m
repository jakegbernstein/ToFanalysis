function [datstruct, params] = drawDistanceHeat(datstruct, params)
%Jake Bernstein

%Description

%Input:
%datstruct.distances
%datstruct.phases
%datstruct.qualities
%datstruct.infilename
%datstruct.out.filename
%params.outfolder

%Output:
%datstruct.image
%image file

SPEEDOFLIGHT = 3e8;

switch nargin
    case 1
        params = [];
end

if ~isfield(params, 'nHues')
    params.nHues = 1000;
end

if ~isfield(params, 'nShades')
    params.nShades = 100;
end

if isfield(params, 'zRes')
    %Overwrite nHues
end

if ~isfield(params, 'saveImage')
    params.saveImage = true;
end

if ~isfield(params,'displayImage')
    params.displayImage = false;
end

if ~isfield(params,'zlim')
    params.zlim = [0, SPEEDOFLIGHT/(2*datstruct.frequency*datstruct.RefractiveIndex)];
end

if ~isfield(params,'interactive')
    params.interactive = false;
end

if ~isfield(params,'qualthreshold')
    params.qualthreshold = 200;
end

if ~isfield(params,'flipy')
    params.flipy = true;
end

cmap = returnColorMap(params.nHues,params.nShades);
colormap(squeeze(cmap(:,100,:)));
run = true;
if params.displayImage
    figure
    colorbar
end
while(run)
    datstruct.image = zeros([size(datstruct.distances),3]);
    for i = 1:size(datstruct.distances,1)
        for j = 1:size(datstruct.distances,2)
            if isnan(datstruct.qualities(i,j))
                datstruct.image(i,j,:) = [0; 0; 0];
            else
                %hueInd = phase2hue(datstruct.phases(i,j));
                hueInd = dist2hue(datstruct.distances(i,j));
                shadeInd = qual2shade(datstruct.qualities(i,j));
                datstruct.image(i,j,:) = squeeze(cmap(hueInd,shadeInd,:));
            end
        end
    end

    if (params.flipy)
        datstruct.image = datstruct.image(end:-1:1,:,:);
    end

    if params.saveImage
        imwrite(datstruct.image,strrep(datstruct.out.filename,'.bin','.png'));
    end

    if params.displayImage
        datstruct.im = image(datstruct.image);
        colormap(squeeze(cmap(:,100,:)));
        colorbar('TickLabels',[params.zlim(1):diff(params.zlim)/10:params.zlim(2)]);
    end

    if params.interactive
        newzlim = input('Input new zlim, or 0 to quit\n');
        if isempty(newzlim) || isscalar(newzlim)
            run = false;
        else
            params.zlim = newzlim;
        end
    else
        run = false;
    end
    
end

%%%Helper functions
    function hueInd = dist2hue(dist)
        if dist <= params.zlim(1)
            hueInd = 1;
        elseif dist > params.zlim(2)
            hueInd = params.nHues;
        else
            hueInd = ceil( params.nHues*(dist-params.zlim(1))/(diff(params.zlim)) );
        end
    end

    function hueInd = phase2hue(phase)
        hueInd = max(ceil(phase*params.nHues/(2*pi)),1);
    end

    function shadeInd = qual2shade(qual)
        shadeInd = max(ceil(params.nShades*qual/params.qualthreshold),1);
        shadeInd = min(shadeInd, params.nShades);
    end
end

