function [frame, files] = processFrame(frame, files, inds, TIMEDELAY)

%frame structure
%%% Input 
%%%  .fileinds - indices of files structure that are part of the frame
%%%  .type - 'single','HDR', or 'average'

%%% Output
%%%  .distances
%%%  .qualities

IMAGESIZE=[240,320];
saveDCS = false;
load Calibration

%NOTE - vector transposed to make 1xN array
switch nargin
    case 2
        inds = frame.fileinds; 
        TIMEDELAY = [];
    case 3
        TIMEDELAY = [];
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

%Pre-allocate image data storage
if saveDCS
    frame.DCS = zeros(IMAGESIZE(1),IMAGESIZE(2),DCSperimage,length(inds),'single');
end
frame.distances = zeros(IMAGESIZE(1),IMAGESIZE(2),length(inds),'single');
frame.qualities = zeros(IMAGESIZE(1),IMAGESIZE(2),length(inds),'single');
frame.phases = zeros(IMAGESIZE(1),IMAGESIZE(2),length(inds),'single');

for i = 1:length(inds)
    if isfield(files(inds(i)),'filename')
        tmpfilename = files(inds(i)).filename;
    else
        tmpfilename = files(inds(i)).Filename;
    end
    tempDCS = readbin(tmpfilename,IMAGESIZE,DCSperimage);
    if saveDCS
        frame.DCS(:,:,:,i) = tempDCS;
    end
    %[files(i).distances, files(i).qualities, files(i).phases] = DCItoDistance_Linear(files(i),[],TIMEDELAY);
    
    [tmpdistances, tmpqualities, tmpphases] = calPhaseInterp(tempDCS, calibration);
    %tmpphases = calPhaseInterp(tempDCS, calibration);
    frame.distances(:,:,i) = tmpdistances;
    frame.qualities(:,:,i) = tmpqualities;
    frame.phases(:,:,1)    = tmpphases;
    
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