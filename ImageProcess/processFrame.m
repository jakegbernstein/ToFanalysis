function [frame, files] = processFrame(frame, files, inds, saveDCS, calibrationfile)

%frame structure
%%% Input 
%%%  .fileinds - indices of files structure that are part of the frame
%%%  .type - 'single','HDR', or 'average'

%%% Output
%%%  .distances
%%%  .qualities

switch nargin
    case 4
        calibrationfile = [];
end
if isempty(calibrationfile)
    calibrationfile = "Calibration44C.mat";
end

IMAGESIZE=[240,320];
load(calibrationfile);
calparams = struct('LEDoffset', 8.5*.0254);

%NOTE - vector transposed to make 1xN array
switch nargin
    case 2
        inds = [];
        saveDCS = false;
    case 3
        saveDCS =false;
end
        
if isempty(inds)
    inds = frame.fileinds; 
end

if size(inds,1) > 1
    inds = inds';
end
%Catch different field tags for the camera
if isfield(files(inds(1)),'cams')
    cams = unique([files(inds).cams]);
elseif isfield(files(inds(1)),'Camera')
    cams = unique([files(inds).Camera]);
else
    error('No cams or Camera field')
end

if files(inds(1)).piDelay
    DCSperimage = 4;
else
    DCSperimage = 2;
end

%Count number of grayscale and DCS images; Pre-allocate image data storage
framemodes = [files(frame.fileinds).mode];
numgrayscale = length(find(framemodes == 0));
numDCS = length(find(framemodes == 1));
inds_grayscale = find(framemodes == 0);
inds_DCS = find(framemodes == 1);

if numDCS > 0
    frame.hasDistance = 1;
    if saveDCS
        frame.DCS = zeros(IMAGESIZE(1),IMAGESIZE(2),DCSperimage,numDCS,'single');
    end
    frame.distances = zeros(IMAGESIZE(1),IMAGESIZE(2),numDCS,'single');
    frame.qualities = zeros(IMAGESIZE(1),IMAGESIZE(2),numDCS,'single');
    frame.phases = zeros(IMAGESIZE(1),IMAGESIZE(2),numDCS,'single');
else
    frame.hasDistance = 0;
end

if numgrayscale > 0
    frame.hasGrayscale = 1;
    frame.grayscale = zeros(IMAGESIZE(1),IMAGESIZE(2),numgrayscale);
else
    frame.hasGrayscale = 0;
end

%Process DCS images
for i = 1:length(inds_DCS)
    if isfield(files(inds(inds_DCS(i))),'filename')
        tmpfilename = files(inds(inds_DCS(i))).filename;
    else
        tmpfilename = files(inds(inds_DCS(i))).Filename;
    end         
    tempDCS = readbin(tmpfilename,IMAGESIZE,DCSperimage);
    if saveDCS
        frame.DCS(:,:,:,i) = tempDCS;
    end
    %[files(i).distances, files(i).qualities, files(i).phases] = DCItoDistance_Linear(files(i),[],TIMEDELAY);
    [tmpdistances, tmpqualities, tmpphases] = calPhaseInterp(tempDCS, calibration, calparams);
    %tmpphases = calPhaseInterp(tempDCS, calibration);
    frame.distances(:,:,i) = tmpdistances;
    frame.qualities(:,:,i) = tmpqualities;
    frame.phases(:,:,1)    = tmpphases;    
end 

%Proces Grayscale images
for i = 1:length(inds_grayscale)
    if isfield(files(inds(inds_grayscale(i))),'filename')
        tmpfilename = files(inds(inds_grayscale(i))).filename;
    else
        tmpfilename = files(inds(inds_grayscale(i))).Filename;
    end         
    frame.grayscale = readbin(tmpfilename,IMAGESIZE,1);
end 

% if strcmpi(frame.type,'average')
%     frame.distances = mean(reshape([files(inds).distances],IMAGESIZE(1),IMAGESIZE(2),[]),3);
%     frame.qualities = mean(reshape([files(inds).qualities],IMAGESIZE(1),IMAGESIZE(2),[]),3);
%     frame.phases =    mean(reshape([files(inds).phases],   IMAGESIZE(1),IMAGESIZE(2),[]),3);
%     frame.frequency = files(inds(1)).frequency;
% end

%This is for merging together a single frame w/ two cameras
if strcmpi(frame.type,'single') && (length(unique([files(frame.fileinds).Camera])) > 1)

end

if strcmpi(frame.type,'HDR')
    
end