function images = dme660processCSV(filename, LEDprofilename, pars)
%Jacob Bernstein
%4/6/2019
%Process image frames from espros DME660 demo system

%% Process Inputs
switch nargin
    case 1
        LEDprofilename = '201904051132_12MHz8Cycles.csv';
        pars = [];
    case 2
        pars = [];
end

%% Parameters
pars.minquality = 25;
pars.goodquality = 100;
pars.bestquality = 1000;


%% Load Data
invDCI = analyzeLEDoutput(LEDprofilename);
rawdat = csvread([filename,'.csv']);
%metafid = fopen([filename,'.txt']);
%TODO: process metadata to know number of samples, size, capture params
%FORNOW: hardcode
imagesize=[320,240];
DCIperimage = 4;

%Process raw data into easier format: [row, column, DCIframe, imagenum]
dat = permute(reshape(rawdat',imagesize(1),imagesize(2),DCIperimage,[]),[2 1 3 4]);

for i=1:size(dat,4)    
    [images(i).distance, images(i).quality] = arrayfun(invDCI,dat(:,:,1,i),dat(:,:,2,i),dat(:,:,3,i),dat(:,:,4,i));
    [images(i).goodx,images(i).goody] = find(images(i).quality > pars.goodquality);
    images(i).goodz = 100*arrayfun(@(x,y) images(i).distance(x,y), images(i).goodx, images(i).goody);
    images(i).pcloud = pointCloud([images(i).goodx, images(i).goody, images(i).goodz]);
end

player = pcplayer([0,320],[0,240],[0,100]);

i = 1;
while isOpen(player)
    view(player,images(i).pcloud)
    pause(.25)
    i = 1 + mod(i,length(images));
end


end

