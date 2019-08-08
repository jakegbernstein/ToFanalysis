function cmap = returnColorMap(nHues,nShades,mapname,mapfile)
%Jacob Bernstein

switch nargin
    case 2
        mapfile = 'colormaps.mat';
        mapname = 'brightwheel';
    case 3
        mapfile = 'colormaps.mat';
end

temp = load(mapfile,mapname);
startmap = getfield(temp,mapname);
%Original map wraps around at start end. Want to use subset so there is
%clear start and end
startmap = startmap(23:85,:,:);
cmap(:,:,1) = cinterp(squeeze(startmap(:,:,1)),nHues,nShades);
cmap(:,:,2) = cinterp(squeeze(startmap(:,:,2)),nHues,nShades);
cmap(:,:,3) = cinterp(squeeze(startmap(:,:,3)),nHues,nShades);

end

function cbar = cinterp(startbar,nHues,nShades)
[Xin,Yin] =   meshgrid(linspace(0,1,size(startbar,2)),linspace(0,1,size(startbar,1)));
[Xout,Yout] = meshgrid(linspace(0,1,nShades),linspace(0,1,nHues));
cbar = interp2(Xin,Yin,startbar,Xout,Yout);
end
