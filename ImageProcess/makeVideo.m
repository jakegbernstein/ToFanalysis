function datstruct = makeVideo(datstruct, params)

switch nargin
    case 1
        params = [];
end

%Check input parameters
if ~isfield(params,'moviename')
    params.moviename = 'movie';
end

if ~isfield(params,'profile')
    %Uncomment one:
    params.profile = 'Uncompressed AVI';
    %params.profile = 'Archival'; %Lossless motion JPEG 2000
    %params.profile = 'Motion JPEG AVI';
    %params.profile = 'MPEG-4';
end

if ~isfield(params,'framerate')
    params.framerate = 10;
end

if ~isfield(params,'nHues')
    params.nHues = 1000;
end

if ~isfield(params, 'nShades')
    params.nShades = 100;
end

if ~isfield(params,'qualitythreshold')
    params.qualitythreshold = 50;
end

if ~isfield(params,'zlim')
    params.zlim = [3,7];
end

if ~isfield(params,'subvideo')
    params.subvideo = [];
end

if ~isfield(params,'decimation')
    params.decimation = 1;
end

%Preprocess the data
cmap = returnColorMap(params.nHues, params.nShades);
nrows = size(datstruct.imagedistances,1);
ncols = size(datstruct.imagedistances,2);
nframes = size(datstruct.imagedistances,3);
ncams = size(datstruct.imagedistances,4);

if isempty(params.subvideo)
    params.subvideo = [1 nframes]
end

framelist = [params.subvideo(1) : params.decimation : params.subvideo(2)];

%Initialize movie writer
v = VideoWriter(params.moviename, params.profile);
v.FrameRate = params.framerate;
open(v)

%Generate the frames and write them to the move

l = 1;
for k= framelist
    tmpimage = zeros(nrows, ncols, 3);
    for i = 1:nrows
        for j = 1:ncols
            if isnan(datstruct.imagequalities(i,j,k,l))
                tmpimage(i,j,:) = [0;0;0];
            else
                hueInd = dist2hue(datstruct.imagedistances(i,j,k,l));
                shadeInd = qual2shade(datstruct.imagequalities(i,j,k,l));
                tmpimage(i,j,:) = squeeze(cmap(hueInd,shadeInd,:));
            end
        end
    end
    writeVideo(v,tmpimage);
end

%Close the movie
close(v)

    function hueInd = dist2hue(dist)
        if dist < params.zlim(1)
            hueInd = 1;
        elseif dist > params.zlim(2)
            hueInd = params.nHues;
        else
            hueInd = ceil( params.nHues*(dist-params.zlim(1))/(diff(params.zlim)) );
        end
    end

    function shadeInd = qual2shade(qual)
        maxqual = 2048;
        shadeInd = max(ceil(params.nShades*qual/100),1);
        shadeInd = min(shadeInd, params.nShades);
    end

end
