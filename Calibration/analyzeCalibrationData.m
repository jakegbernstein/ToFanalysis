function calibration = analyzeCalibrationData(metafilename)
%Jacob Bernstein
%Description

%Constants
IMAGESIZE=[240,320];
DCSPERIMAGE=4;
SPEEDOFLIGHT=3E8;
NUMDLL=50;

%Process inputs
calibration=struct();
wd = pwd;
switch nargin
    case 0
        [metafilename, metafilepath] = uigetfile('*.csv','Select metadata file');
        cd(metafilepath)
end

[files, frames, movies] = parseCSV(metafilename);
if length(movies) > 1
    movieind = input('Which movie to analyze?\n');
else
    movieind = 1;
end
movie = movies(1);

%% Plot Temperature over calibration capture
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

%% Load data; Average DCS values of each dll step
tic
for i=1:NUMDLL
    flatimage(i).DCS = zeros([IMAGESIZE, DCSPERIMAGE]);
    for f = 1:length(useframes)
        filenum = frames(useframes(f)).fileinds(i);
        files(filenum).DCS = readbin(files(filenum).Filename, IMAGESIZE, DCSPERIMAGE);
        flatimage(i).DCS = flatimage(i).DCS + files(filenum).DCS;
    end
    flatimage(i).DCS = flatimage(i).DCS/length(useframes);
    flatimage(i).meanDCS1 = mean2(squeeze(flatimage(i).DCS(:,:,1)));
    flatimage(i).meanDCS2 = mean2(squeeze(flatimage(i).DCS(:,:,2)));
    flatimage(i).meanDCS3 = mean2(squeeze(flatimage(i).DCS(:,:,3)));
    flatimage(i).meanDCS4 = mean2(squeeze(flatimage(i).DCS(:,:,4)));
end
toc

meanphase = atan(([flatimage.meanDCS2] - [flatimage.meanDCS4]) ./ ([flatimage.meanDCS1] - [flatimage.meanDCS3]));
pishiftinds = find([flatimage.meanDCS1] - [flatimage.meanDCS3] > 0);
meanphase(pishiftinds) = meanphase(pishiftinds) + pi;

%% Plot mean DCS values, phase
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

%% Calculate phase of each pixel for each averaged dll step
for i=1:NUMDLL
    flatimage(i).phase = atan((flatimage(i).DCS(:,:,2)-flatimage(i).DCS(:,:,4))./(flatimage(i).DCS(:,:,1)-flatimage(i).DCS(:,:,3)));
    pishiftinds = find(flatimage(i).DCS(:,:,1) - flatimage(i).DCS(:,:,3) > 0 );
    flatimage(i).phase(pishiftinds) = flatimage(i).phase(pishiftinds) + pi;
    flatimage(i).meanphase = mean2(flatimage(i).phase);
end  

%% Make movie of flat field phase vs dll
figure
flatmovie = 

%% Calculate z-score of each pixel at each dll step

%% Make movie of flat field  z-score of each pixel vs dll

%% Find bad pixels




save('Calibration','calibration')
cd(wd)