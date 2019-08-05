function [vidsegs,filelist] = binFileSelector(inputfolder)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

%Inputs and parameters
switch nargin
    case 0
        inputfolder = uigetdir();

end

maxvideoperiod = 4;

%Get a list of all the files
startfolder = pwd;
cd(inputfolder);
allfilestruct = dir('*.bin');
allfiles = {allfilestruct.name};

%Use regular expressions to find each file's time, capture type, and camera
%number
%Reformat as a structure array, and keep original filename
parsedfiles = cellfun(@parsefilename,allfiles);

%Find continuous video segments:
%Sort files by time
%Find blocks where durations between each frame is less than max threshold
vidsegs = [];
[temptimeorder, temptimeinds] = sort([parsedfiles.date]);
breakinds = find(seconds(diff(temptimeorder)) > maxvideoperiod);
breakinds(end+1) = length(temptimeorder);
tempvidstartind=1;
for i=breakinds
    if i-tempvidstartind > 1
        newsegind = length(vidsegs) + 1;
        vidsegs(newsegind).inds = temptimeinds(tempvidstartind:i);
        vidsegs(newsegind).filenames = {parsedfiles([vidsegs(newsegind).inds]).filename}
    end
    tempvidstartind = i+1;
end

%{
sortedinds = zeros(size(parsedfiles));
tempfileind = 1;

while ~isempty(tempfileind)
    matchdateinds = find(strcmp(parsedfiles(tempfileind).date, {parsedfiles.date}));
    sortedinds(matchdateinds) = 1;
    [temptimeorder, temptimeinds] = sort([parsedfiles(matchdateinds).time]);
    shotdelays = diff(temptimeorder);
    breakinds = find(shotdelays > maxvideoperiod);
    %Figure out which breaks are single shots, which are videos
    %%%ASSUME ALL SHOTS DOUBLE CAMERA
    %Store video metadata in structure array
    tempvidstartind = 1;
    for i =1:length(breakinds)
        if breakinds(i) - tempvidstartind > 1
            newsegind = length(vidsegs) + 1;
            vidsegs(newsegind).inds = matchdateinds(temptimeinds(tempvidstartind:breakinds(i)));
                    end
        tempvidstartind = breakinds(i) + 1;
    end
    %...
    tempfileind = find(~sortedinds,1);
end
%}
filelist = parsedfiles;        
save('../metadata/vidsegs.mat','vidsegs','parsedfiles')


end

function out = parsefilename(fname)
    %file format is DateAndTime_2D/3D_Cam#.bin
    %exp = '(?<month>\d{2})(?<day>\d{2})(?<hour>\d{2})(?<min>\d{2})(?<sec>\d{2}.\d*)_+(?<mode>[23]D)_+(?<camnum>\d).bin';
    exp = '(?<datestr>\d*.\d*)_+(?<mode>[23]D)_+(?<camnum>\d).bin';
    fs = regexp(fname,exp,'names');
    out.date = datetime(fs.datestr,'InputFormat','MMddHHmmss.SSS');
    %fs.time = str2double(fs.time);
    out.camnum = str2double(fs.camnum);
    out.filename = fname;
    %filestruct.shottype = [];
end
    