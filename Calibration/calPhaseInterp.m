function [distance, quality, calphase] = calPhaseInterp(DCS, calibration, params)
%function delay = calPhaseInterp(DCS, caldata, goodpixels)

switch nargin
    case 2
        params = [];
end

if ~isfield(params,'LEDoffset') || isempty(params.separation)
    params.separation = 0;
end

if ~isfield(params,'focallength') || isempty(params.focallength)
    params.focallength = 5.5; %mm
end

PIXELWIDTH = 0.020; %mm
IMAGESIZE = [240,320];
IMAGECENTER = (IMAGESIZE + [1,1])/2;

delta = atan(PIXELWIDTH/params.focallength);

%0: 
C = 3e8;
period = 1/calibration.modfreq; 
phasestep = (1e-9*calibration.dllstep)/period;
phaseoffset = (2*calibration.targetdistance/(C))/period;
wavelength = C*period;

%1: Measure phase
calphase = atan((DCS(:,:,2)-DCS(:,:,4))./(DCS(:,:,1)-DCS(:,:,3)));
pishiftinds = find((DCS(:,:,1)-DCS(:,:,3)) >= 0);
calphase(pishiftinds) = calphase(pishiftinds) + pi;

naninds = find(isnan(calphase));
calibration.goodpixels(naninds) = 0;

phasecal = permute(calibration.phase,[3 1 2]);

%2: Interpolate back to dll
tic
phase = zeros(size(DCS,1),size(DCS,2),'single');
quality = zeros(size(DCS,1),size(DCS,2),'single');
distance = zeros(size(DCS,1),size(DCS,2),'single');

badpixels = [];
for i=1:size(DCS,1)
    %for j=1:size(DCS,2)
    for j=find(calibration.goodpixels(i,:))
        %delay(i,j) = reverseinterp(phase(i,j), squeeze(caldata(i,j,:)));
        tmpdelay = reverseinterp(calphase(i,j), phasecal(:,i,j));
        phase(i,j) = mod(phaseoffset + tmpdelay*phasestep,1);
        if params.separation == 0
            distance(i,j) = wavelength*phase(i,j)/2;
        else
            D = wavelength*phase(i,j);
            offcenter = i - IMAGECENTER(1);
            decl = delta*offcenter;
            distance(i,j) = (D^2 - params.LEDoffset^2)/(2*(D-params.LEDoffset(sin(decl))));
        end
        quality(i,j) = sqrt(sum(DCS(i,j,:).^2));
    end
end
toc

end


function d = reverseinterp(ph, cal)
    %d = interp1(cal,1:length(cal),ph);
    rind = find(ph < cal,1);
    if rind == 1
        slope = cal(rind+1) - cal(rind);
    else
        slope = cal(rind) - cal(rind-1);
    end
    d = rind - (cal(rind)-ph)/slope;
end
