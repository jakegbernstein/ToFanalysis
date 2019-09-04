%Helper function for reading binary files, helps keep it all in one place
%NEEDS UPDATE - dme660 api uses a different value for NaN
function DCS = readbin(filename,imagesize,DCSperimage)
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
    tmprawdat(tmprawdat == 2^12 - 1) = NaN;
    tmprawdat = tmprawdat - 2^11;
    DCS = permute(reshape(tmprawdat',imagesize(2),imagesize(1),DCSperimage),[2 1 3]);
    fclose(fid);
end