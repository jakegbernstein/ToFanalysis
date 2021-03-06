function [frame, files] = processFrame(frame, files)

%frame structure
%%% Input 
%%%  .fileinds - indices of files structure that are part of the frame
%%%  .type - 'single','HDR', or 'average'

%%% Output
%%%  .distances
%%%  .qualities

IMAGESIZE=[240,320];

inds = frame.fileinds; 
if size(inds,1) > 1
    inds = inds';
end
inds_3D = inds([files(inds).mode] == 1);
inds_2D = inds([files(inds).mode] == 0);
%NOTE - vector transposed to make 1xN array

%Catch different field tags for the camera
if isfield(files(inds(1)),'cams')
    cams = unique([files(inds).cams]);
elseif isfield(files(inds(1)),'Camera')
    cams = unique([files(inds).Camera]);
else
    error('No cams or Camera field')
end

%Process 3D images
for i = inds_3D
    if files(i).piDelay
        tmpDCSperimage = 4;
    else
        tmpDCSperimage = 2;
    end
    if isfield(files(i),'filename')
        tmpfilename = files(i).filename;
    else
        tmpfilename = files(i).Filename;
    end
    files(i).DCS = readbin(tmpfilename,IMAGESIZE,tmpDCSperimage);
    [files(i).distances, files(i).qualities, files(i).phases] = DCItoDistance_Linear(files(i));
    %files(i).distances = files(i).distances;
    %files(i).qualities = files(i).qualities;
    %files(i).phases =    files(i).phases;
end 

if strcmpi(frame.type,'average')
    frame.distances = mean(reshape([files(inds).distances],IMAGESIZE(1),IMAGESIZE(2),[]),3);
    frame.qualities = mean(reshape([files(inds).qualities],IMAGESIZE(1),IMAGESIZE(2),[]),3);
    frame.phases =    mean(reshape([files(inds).phases],   IMAGESIZE(1),IMAGESIZE(2),[]),3);
    frame.frequency = files(inds(1)).frequency;
end

for i = inds_2D
    %Load in grayscale images...
    %WRITE THIS LATER
end
    

%This is for merging together a single frame w/ two cameras
if strcmpi(frame.type,'single') && (length(unique([files(frame.inds).cams])) > 1)

end

if strcmpi(frame.type,'HDR')
    
end