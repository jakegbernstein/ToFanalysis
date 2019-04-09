function pics = dme660processCSV(filename, LEDprofilename)
%Jacob Bernstein
%4/6/2019
%Process image frames from espros DME660 demo system

%% Process Inputs
switch nargin
    case 1
        LEDprofilename = '201904051132_12MHz8Cycles.csv';
end

%% Load Data
invDCI = analyzeLEDoutput(LEDprofilename);
rawdat = csvread([filename,'.csv']);
%metafid = fopen([filename,'.txt']);
%TODO: process metadata to know number of samples, size, capture params
%FORNOW: hardcode
imagesize=[320,240];
DCIperimage = 4;
%numsamples = size(rawdat,1)/(imagesize(2) * DCIperimage);

%Process raw data into easier format: [row, column, DCIframe, imagenum]
dat = permute(reshape(rawdat',imagesize(1),imagesize(2),DCIperimage,[]),[2 1 3 4]);

for i=1:size(dat,4)    
    pics{i} = arrayfun(invDCI,dat(:,:,1,i),dat(:,:,2,i));
end


end

