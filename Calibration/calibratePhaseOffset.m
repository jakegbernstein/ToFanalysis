function offset = calibratePhaseOffset(frame, distmeasured)

%%% 1 - Show Calibration Image %%%
%Use same color scale as drawDistanceHeat

params.saveImage = false;
params.displayImage = true;
params.interactive = true;
[frame, params] = drawDistanceHeat(frame,params);
display('Draw a box around calibration area')
boxcoords = getrect;
%Fixing some bullshit:
if params.flipy
    boxcoords = [boxcoords(1),...
                 size(frame.distances,1) - boxcoords(2) - boxcoords(4),...
                 boxcoords(3),boxcoords(4)];
end
xinds = [ceil(boxcoords(1)):floor(boxcoords(1)+boxcoords(3))];
yinds = [ceil(boxcoords(2)):floor(boxcoords(2)+boxcoords(4))];
caldistance = mean(mean(frame.distances(yinds,xinds)));
offset = distmeasured - caldistance;


