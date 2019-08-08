function [outStruct,inStruct] = processVideo(inStruct)
%Process a Prometheus ToF Video
%Jacob Bernstein
%Future Ocean Lab

%Description

%inStruct (input Structure) parameters:
%%% .rootfolder - contains 'images', 'metadata', and 'processruns' folders
%%% .vidsegfile - file inside ./metadata with the filenames of video
%%%         segments
%%% .vidseg - video segment to analyze, based on 'vidsegs' struture array
%%% .cams - array of cameras to process (process all cameras if empty)
%%% .subvideo - [startindex stopindex] if want to look at subvideo
%%%         (complete video if empty)
%%% .decimation - decimation factor to look at every n'th frame 
%%%         (default: 1)
%%% .preprocess - params for the preprocessor
%%% .imageprocess - structure array of function names and input params
%%% .postprocess - structure array of function names and output params

%Hardcoded params - may get replaced be file metadata later
IMAGESIZE =[240,320];
DCSPERIMAGE = 4;

%Check and process inputs
switch nargin
    case 0
        inStruct = struct;
end

if ~isfield(inStruct,'rootfolder')
    inStruct.rootfolder = uigetdir();
end
cd(inStruct.rootfolder);

if ~isfield(inStruct,'vidsegfile')
    inStruct.vidsegfile = uigetfile();
end

if ~isfield(inStruct,'vidseg')
    %ADD output information about video segments
    inStruct.vidseg = input('Input video segment number\n');
end

if ~isfield(inStruct,'cams')
    inStruct.cams = [];
end

if ~isfield(inStruct,'subvideo')
    inStruct.subvideo = [];
end

if ~isfield(inStruct,'decimation')
    inStruct.decimation = 1;
end

if ~isfield(inStruct,'imageprocess')
    inStruct.imageprocess(1).fnname = 'DCItoDistance_Linear';
    inStruct.imageprocess(2).fnname = 'drawDistanceHeat';
end

if ~isfield(inStruct,'postprocess')
    inStruct.postprocess(1).fnname = 'makeVideo';
    tmppar = struct;
    inStruct.postprocess(1).params = tmppar;
end

if ~isfield(inStruct,'outfolder') || isempty(inStruct.outfolder)
    inStruct.outfolder = ['processruns/',datestr(now,'yymmdd_HHMMSS')];
end

mkdir(inStruct.outfolder);
filelist = selectImageFiles(inStruct);

%Load each file, and then process with the image processing stack
imagedistances = zeros(IMAGESIZE(1),IMAGESIZE(2),size(filelist,1),size(filelist,2));
imagequalities = zeros(IMAGESIZE(1),IMAGESIZE(2),size(filelist,1),size(filelist,2));
imagephases    = zeros(IMAGESIZE(1),IMAGESIZE(2),size(filelist,1),size(filelist,2));

if ~isfield(inStruct,'distancefile') || isempty(inStruct.distancefile)
    for i=1:size(filelist,1)
        for j=1:size(filelist,2)
            tmpdat.out.filename = filelist(i,j).filename;
            tmpdat.DCS = readbin(tmpdat.out.filename);
            cd(inStruct.outfolder);
            tmpdat.distances = [];
            tmpdat.qualities = [];
            tmpdat.phases = [];
            for k=1:length(inStruct.imageprocess)
                if ~isfield(inStruct.imageprocess(k),'params')
                    inStruct.imageprocess(k).params = [];
                end
                tmpfunc = str2func(inStruct.imageprocess(k).fnname);
                tmpdat = tmpfunc(tmpdat, inStruct.imageprocess(k).params);
                %tmpdat = feval(inStruct.imageprocess(k).fnname, tmpdat, inStruct.imageprocess(k).params);
                
            end
            imagedistances(:,:,i,j) = tmpdat.distances;
            imagequalities(:,:,i,j) = tmpdat.qualities;
            imagemeta(i,j) = tmpdat.out;
            cd(inStruct.rootfolder);
        end
    end
    cd(inStruct.outfolder)
    outStruct.imagedistances = imagedistances;
    outStruct.imagequalities = imagequalities;
    outStruct.imagephases = imagephases;
    outStruct.imagemeta = imagemeta;
    save('dataoutput.mat','imagedistances','imagequalities','imagephases','imagemeta');   
else
    outStruct = load(inStruct.distancefile);
    cd(inStruct.outfolder);
end



%%%Postprocess entire dataset

for i=1:length(inStruct.postprocess)
    if ~isfield(inStruct.postprocess(i),'params')
        inStruct.postprocess(i).params = [];
    end
    tmpfunc = str2func(inStruct.postprocess(i).fnname);
    outStruct = tmpfunc(outStruct, inStruct.postprocess(i).params);
end

%Helper function for reading binary files, helps keep it all in one place
    function DCS = readbin(filename)
        fid = fopen(['./images/',filename]);
        tmprawdat = fread(fid,Inf,'uint16');
        tmprawdat(tmprawdat == 2^12 - 1) = NaN;
        tmprawdat = tmprawdat - 2^11;
        DCS = permute(reshape(tmprawdat',IMAGESIZE(2),IMAGESIZE(1),DCSPERIMAGE),[2 1 3]);
        fclose(fid);
    end
end

