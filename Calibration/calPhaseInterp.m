function [distance, quality, calphase] = calPhaseInterp(DCS, calibration)
%function delay = calPhaseInterp(DCS, caldata, goodpixels)

%0: 
C = 3e8;
period = 1/calibration.modfreq; 
phasestep = (1e-9*calibration.dllstep)/period;
phaseoffset = (2*calibration.targetdistance/(C))/period;
wavelength = C*period/2;

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
        distance(i,j) = wavelength*phase(i,j);
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
