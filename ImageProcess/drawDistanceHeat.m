function datstruct = drawDistanceHeat(datstruct, params)
%Jake Bernstein

%Description

%Input:
%datstruct.distances
%datstruct.phases
%datstruct.qualities
%datstruct.infilename
%params.outfolder

%Output:
%datstruct.image
%image file

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

cmap = returnColorMap(params.nHues,params.nShades);

datstruct.image = zeros([size(datstruct.distances),3]);
for i = 1:size(datstruct.distances,1)
    for j = 1:size(datstruct.distances,2)
        hueInd = phase2hue(datstruct.phases(i,j));
        shadeInd = qual2shade(datstruct.qualities(i,j));
        datstruct.image(i,j,:) = squeeze(cmap(hueInd,shadeInd,:));
    end
end

imwrite(datstruct.image,strrep(datstruct.out.filename,'.bin','.png'));


%%%Helper functions
    function hueInd = phase2hue(phase)
        hueInd = max(ceil(phase*params.nHues/(2*pi)),1);
    end

    function shadeInd = qual2shade(qual)
        maxqual = 2048;
        shadeInd = max(ceil(params.nShades*qual/100),1);
        shadeInd = min(shadeInd, params.nShades);
    end
end

