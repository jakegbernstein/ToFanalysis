function p = getrootpath(foldername)
switch nargin
    case 0
        foldername = 'Prometheus Calibration';
end
     
leafpath = mfilename('fullpath');
found = regexp(leafpath,['.*', foldername],'match');
if ~isempty(found)
    p = found{1};
else
    error('Cannot find root folder')
end