function [filelist,path] = selectImagesFromCSV(csvfilename)

switch nargin
    case 0
        [file,path] = uigetfile('*.csv');
        csvfilename = fullfile(path,file);
    case 1
        path = fileparts(which(csvfilename));
end
T = readtable(csvfilename);

fprintf('There are %d files.\n',size(T,1)');
fileinds = input('Which files do you want to load?\n');
filecell = T{fileinds,1};
for i=1:length(filecell)
    filelist(i).filename = filecell{i};
end
