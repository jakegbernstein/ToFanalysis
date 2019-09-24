%Helper function for reading binary files, helps keep it all in one place
%NEEDS UPDATE - dme660 api uses a different value for NaN
function [DCS, satpixels] = readbin(filename,imagesize,DCSperimage,satpixelthreshold)  
    switch nargin
        case 1
            imagesize = [240, 320];
            DCSperimage = 4;
            satpixelthreshold = [];
        case 2
            DCSperimage = 4;
            satpixelthreshold = [];
        case 3
            satpixelthreshold = [];
    end
    
    if isempty(satpixelthreshold)
        satpixelthreshold = 2000;

    %Check if filename has .bin ending
    [~,filestem] = fileparts(filename);
    filename = [filestem,'.bin'];
    tmpfiles = dir;
    if find(contains({tmpfiles.name},filename))
        fid = fopen(filename);
    else
        fid = fopen(['./images/',filename]);
    end
    tmprawdat = fread(fid,Inf,'uint16');    
    tmprawdat = single(tmprawdat - 2^11);
    DCS = permute(reshape(tmprawdat',imagesize(2),imagesize(1),DCSperimage),[2 1 3]);
    badpixels = find(abs(DCS) > satpixelthreshold);
    [satrow,satcol,~] = ind2sub([imagesize, DCSperimage], badpixels);
    for i=1:length(satrow)
        DCS(satrow(i),satcol(i),:) = repmat(nan,1,DCSperimage);
    end
    satpixels = unique(sub2ind(imagesize,satrow,satcol));
    fclose(fid);
end