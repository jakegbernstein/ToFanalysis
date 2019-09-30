function [files, frames, movies] = parseCSV(csvfilename, outfilename)

frameheader = 'framenum';
vidheader = 'vidnum';

switch nargin
    case 0
        csvfilename = [];
        outfilename = [];
    case 1
        outfilename = [];        
end

wd = pwd;
if isempty(csvfilename)
    [csvfilename, tpath] = uigetfile('*.csv','Select CSV metadata file');
    cd(tpath)
end

if isempty(outfilename)
    [~,outfilename] = fileparts(csvfilename);
end

T = readtable(csvfilename);
%Check whether the CSV file gives refractive index. If not, ask.
if isempty(find(contains(T.Properties.VariableNames,'RefractiveIndex')))
    ninwater = input('Where were images taken? Input ''0'' for water, ''1'' for air\n');
    if ninwater
        T.RefractiveIndex = repmat(1,size(T,1),1);
    else
        T.RefractiveIndex = repmat(1.33,size(T,1),1);
    end
end
        
%Check whether the CSV file has frequency, or just modFreq, the variable used in the GUI
if isempty(find(contains(T.Properties.VariableNames,'frequency')))
    T.frequency = 24e6./(1+T.modFreq);
end

%Create the 'files' array
for i = 1:size(T,1)
    files(i) = table2struct(T(i,:));
    %Check if Temperature is a string
    if isstr(files(i).Temp)
        files(i).Temp = str2num(strtok(files(i).Temp,'[]'));
    end
end

%Convert Time to matlab datenum
for i=1:length(files)
    YMDpos = 6:11; %HACK!!!
    %MORE HACK
    timestr = num2str(files(i).Time);
    if isempty(strfind(timestr,'.'))
        timestr = [timestr,'.000'];
    end
    if strfind(timestr,'.') == 6
        timestr = ['0',timestr];
    end
    
    dstr = [files(i).Filename(YMDpos),timestr];
    files(i).Time = datenum(dstr,'yymmddHHMMSS.FFF');
end


%Create the 'frames' array
frameinds = unique(T.(frameheader))';
for i = frameinds
    frames(i).fileinds = find(T.(frameheader) == i);
    frames(i).RefractiveIndex = files(frames(i).fileinds(1)).RefractiveIndex;
    frames(i).movienum = files(frames(i).fileinds(1)).(vidheader);
    frames(i).vidnum = files(frames(i).fileinds(1)).vidnum;

    %Workaround for csv files created with now frame tage
    if find(contains(T.Properties.VariableNames,'frametag'))
        frames(i).type = T{frames(i).fileinds(1),'frametag'}{1};
    else
        tempfn = T{frames(i).fileinds(1),'Filename'}{1};
        exp = '_\d{3}-\d{2}';
        if regexp(tempfn, exp)
            frames(i).type = 'HDR';
        else
            frames(i).type = 'single';
        end
    end        
end


%Create the 'movies' array
movieinds = unique(T.(vidheader))';
movieinds = movieinds(movieinds ~= -1);
if ~isempty(movieinds)
    %FIX THIS LATER
    for i=1:length(movieinds)
        movies(i).frameinds = find([frames.movienum] == movieinds(i));
    end
else
    movies = [];
end
save(outfilename, 'files', 'frames', 'movies');
cd(wd)