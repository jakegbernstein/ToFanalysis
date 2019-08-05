function filelist = selectImageFiles(inStruct)
load(['./metadata/',inStruct.vidsegfile]) 
%This loads variables 'vidsegs' and 'parsedfiles'
allfiles = parsedfiles(vidsegs(inStruct.vidseg).inds);
cams = unique([parsedfiles.camnum]);
for i=1:length(cams)
    tmpind = find([allfiles.camnum] == cams(i));
    for j=1:length(tmpind)
        filelist(j,i) = allfiles(tmpind(j));
    end
end

if ~isempty(inStruct.cams)
    filelist = filelist(:,1+inStruct.cams);
end

if ~isempty(inStruct.subvideo)
    filelist = filelist(inStruct.subvideo(1):inStruct.subvideo(2),:);
end

if ~(inStruct.decimation == 1)
    filelist = filelist(1:inStruct.decimation:end,:);
end



end