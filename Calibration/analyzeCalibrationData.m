function [calibration, flatimage] = analyzeCalibrationData(metafilename, inparams)
%Jacob Bernstein
%Description

%Constants
IMAGESIZE=[240,320];
DCSPERIMAGE=4;
SPEEDOFLIGHT=3E8;
NUMDLL=50;

%Process inputs
calibration=struct('phase',[],'badpixels',[],'meantemperature',[],'goodpixels',[],'targetdistance',[],'dllstep',[]);
wd = pwd;
switch nargin
    case 0
        [metafilename, metafilepath] = uigetfile('*.csv','Select metadata file');
        cd(metafilepath)
        inparams = [];
    case 1
        inparams = [];
end

%Take care of input parameters
if isempty(inparams)
    inparams = struct();
end

if ~isfield(inparams,'debugmode') || isempty(inparams.debugmode)
    inparams.debugmode = false;
end   

if ~isfield(inparams,'targetdistance') || isempty(inparams.targetdistance)
    inparams.targetdistance = input('Input target distance in meters: \n');
end

if ~isfield(inparams,'dllstep') || isempty(inparams.dllstep)
    inparams.dllstep = input('Input dll step in nanoseconds: \n');
end

if ~isfield(inparams,'useframes')
    inparams.useframes = [];
end

if ~isfield(inparams,'genfigures')
    inparams.genfigures = {'pixel-by-pixel','temp','meanDCS','meanPhase','sampleimage','movie'};
end

%
if inparams.debugmode
    figure
end

calibration.targetdistance = inparams.targetdistance;
calibration.dllstep = inparams.dllstep;
wdparts = split(pwd,filesep);
calibration.dataset = wdparts{end};

%% Plot Temperature over calibration capture
[~,~,filetype] = fileparts(metafilename);
if isequal(filetype, '.mat')
    load(metafilename);
else
    [files, frames, movies] = parseCSV(metafilename);
end
if ~isempty(inparams.useframes)
    useframes = inparams.useframes;
    for i=useframes
        frames(i).Temp = [files([frames(i).fileinds]).Temp];
    end
    calibration.meantemperature = mean([frames(useframes).Temp]);
else
    movieind = input('Which movie to analyze? (-1 for all frames)\n');
    if movieind == -1
        %NOTE: THIS CODE IS HACKY AND COULD BREAK DEPENDING ON HOW METADATA IS PARSED AND HOW MANY TEMPERATURE MEASUREMENTS ARE MADE PER FRAME
        temps = [files.Temp];
        fig_temp = figure;
        plot(temps)
        xlabel('Frame Number')
        ylabel('Temperature (C)')
        title('epc660 average temperature')
        useframes = input('Which frames should be used for calibration?\n');
        calibration.meantemperature = mean(temps(useframes));
    else
        movie = movies(movieind);
        firstframe = movie.frameinds(1);
        %NOTE: It looks like the csv reader works differently on linux vs pc!
        if isstr(files(1).Temp)
            tempimage = find(~cellfun('isempty',strfind({files([frames(firstframe).fileinds]).measureTemp},'TRUE')));
            for i=1:length(movie.frameinds)
                frames(movie.frameinds(i)).Temp = files(frames(movie.frameinds(i)).fileinds(tempimage)).Temp;
                movie.temps(i) = str2num(frames(movie.frameinds(i)).Temp);
            end
        elseif isnumeric(files(1).Temp)
            tempimage = find(~isnan([files([frames(firstframe).fileinds]).Temp]));
            for i=1:length(movie.frameinds)
                frames(movie.frameinds(i)).Temp = files([frames(movie.frameinds(i)).fileinds(tempimage)]).Temp;
                movie.temps(i) = frames(movie.frameinds(i)).Temp;
            end
        else
            error('WTF is going on w/ Temp metadata?')
        end
        
        fig_temp = figure;
        plot(movie.temps)
        xlabel('Frame Number')
        ylabel('Temperature (C)')
        title('epc660 average temperature')
        
        useframes = input('Which frames should be used for calibration?\n');
        calibration.meantemperature = mean(movie.temps(useframes));
    end
end



%% Load data; Average DCS values of each dll step
if inparams.debugmode
    fprintf('Loading data\n')
end
tic
flatimage(NUMDLL) = struct('allDCS',[],'meanDCS',[],'meanDCS1',[],'meanDCS2',[],'meanDCS3',[],'meanDCS4',[],'phase',[],'meanphase',[]);
for i=1:NUMDLL
    flatimage(i).meanDCS = zeros([IMAGESIZE, DCSPERIMAGE],'single');
    flatimage(i).allDCS = zeros([IMAGESIZE, DCSPERIMAGE, length(useframes)], 'single');
    flatimage(i).allquality = zeros([IMAGESIZE, length(useframes)]);
    for f = 1:length(useframes)
        filenum = frames(useframes(f)).fileinds(i);
        flatimage(i).allDCS(:,:,:,f) = readbin(files(filenum).Filename, IMAGESIZE, DCSPERIMAGE);
        flatimage(i).allquality(:,:,f) = sqrt(sum(flatimage(i).allDCS(:,:,:,f).^2,3))/2;
    end
    flatimage(i).meanDCS = mean(flatimage(i).allDCS,4);
    flatimage(i).meanDCS1 = mean2(squeeze(flatimage(i).meanDCS(:,:,1)));
    flatimage(i).meanDCS2 = mean2(squeeze(flatimage(i).meanDCS(:,:,2)));
    flatimage(i).meanDCS3 = mean2(squeeze(flatimage(i).meanDCS(:,:,3)));
    flatimage(i).meanDCS4 = mean2(squeeze(flatimage(i).meanDCS(:,:,4)));
    flatimage(i).meanquality = mean(flatimage(i).allquality,'all');
    flatimage(i).devquality = mean2(std(flatimage(i).allquality,0,3));
    %toc
end
%toc

meanphase = atan(([flatimage.meanDCS2] - [flatimage.meanDCS4]) ./ ([flatimage.meanDCS1] - [flatimage.meanDCS3]));
pishiftinds = find([flatimage.meanDCS1] - [flatimage.meanDCS3] > 0);
meanphase(pishiftinds) = meanphase(pishiftinds) + pi;

%% Plot mean DCS values, phase
if ~isempty(find(strcmpi(inparams.genfigures,'meanDCS')))
    figure
    subplot(2,1,1)
    plot([flatimage.meanDCS1])
    hold on
    plot([flatimage.meanDCS2])
    plot([flatimage.meanDCS3])
    plot([flatimage.meanDCS4])
    xlabel('dll step')
    ylabel('mean DCS value')
    legend('DCS0','DCS1','DCS2','DCS3')
    
    subplot(2,1,2)
    plot(meanphase)
    xlabel('dll step')
    ylabel('Mean phase')
end

%% Calculate phase of each pixel for each averaged dll step
if inparams.debugmode
    fprintf('Calculating phase of each pixel\n')
end
%tic

for i=1:NUMDLL
    flatimage(i).allphase = zeros([IMAGESIZE,1,size(flatimage(i).allDCS,4)]);
    for j = 1:size(flatimage(i).allDCS,4)
        %flatimage(i).phase = atan((flatimage(i).meanDCS(:,:,2)-flatimage(i).meanDCS(:,:,4))./(flatimage(i).meanDCS(:,:,1)-flatimage(i).meanDCS(:,:,3)));
        flatimage(i).allphase(:,:,:,j) = atan((flatimage(i).allDCS(:,:,2,j)-flatimage(i).allDCS(:,:,4,j))./(flatimage(i).allDCS(:,:,1,j)-flatimage(i).allDCS(:,:,3,j)));               
    end
    flatimage(i).allphase = squeeze(flatimage(i).allphase);
    flatimage(i).phase = mean(flatimage(i).allphase,3);
    pishiftinds = find(flatimage(i).meanDCS(:,:,1) - flatimage(i).meanDCS(:,:,3) >= 0 );
    flatimage(i).phase(pishiftinds) = flatimage(i).phase(pishiftinds) + pi;
    flatimage(i).meanphase = mean2(flatimage(i).phase);
    flatimage(i).devphase = mean2(std(flatimage(i).allphase,0,3));
end

%toc


%% Build calibrationmatrix
calibration.phase = reshape([flatimage.phase],[IMAGESIZE, NUMDLL]);
calibration.badpixels = [];
calibration.goodpixels = ones(IMAGESIZE);
for i=1:IMAGESIZE(1)
    for j=1:IMAGESIZE(2)
        tmpcal = squeeze(calibration.phase(i,j,:));
        tmppiv = find(diff(tmpcal) <= 0);
        if length(tmppiv) > 1
            calibration.badpixels(:,end+1) = [i; j];
            calibration.goodpixels(i,j) = 0;
        else
            tmpcal(tmppiv+1:end) = tmpcal(tmppiv+1:end) + 2*pi;
            calibration.phase(i,j,:) = tmpcal;
        end
    end
end
phaseplot = reshape(permute(calibration.phase,[3,1,2]),NUMDLL,[]);

if ~isempty(find(strcmpi(inparams.genfigures,'pixel-by-pixel')))
    figure
    plot(phaseplot(:,1:10:end))
    xlabel('dll step')
    ylabel('phase')
    title('Pixel-by-Pixel Phase Calibration (1 of every 10 pixels)')
end

%% Make movie of flat field phase vs dll
if ~isempty(find(strcmpi(inparams.genfigures,'movie')))
    flatfigure = figure;
    flatframes(NUMDLL) = struct('cdata',[],'colormap',[]);
    flatmovie = VideoWriter('flatframes.avi');
    flatmovie.open();
    for i=1:NUMDLL
        imagesc(flatimage(i).phase)
        colorbar
        drawnow
        flatframes(i) = getframe(flatfigure);
        writeVideo(flatmovie, flatframes(i));
    end
end

%% Calculate phase std of each pixel at each dll step
rawphases = zeros([IMAGESIZE, length(useframes)]);


%% Make movie of flat field  z-score of each pixel vs dll

%% Find bad pixels



calibration.modfreq = files(frames(useframes(1)).fileinds(1)).frequency;
calibration.frequency = calibration.modfreq;
save(sprintf('Calibration%.1fC.mat',calibration.meantemperature),'calibration')
cd(wd)