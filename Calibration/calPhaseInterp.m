function delay = calPhaseInterp(DCS, caldata)

%1: Measure phase
phase = atan((DCS(:,:,2)-DCS(:,:,4))./(DCS(:,:,1)-DCS(:,:,3)));
pishiftinds = find((DCS(:,:,1)-DCS(:,:,3)) > 0);
phase(pishiftinds) = phase(pishiftinds) + pi;

%2: Interpolate back to dll
delay = zeros(size(DCS,1),size(DCS,2));
for i=1:size(DCS,1)
    for j=1:size(DCS,2)
        delay(i,j) = reverseinterp(phase(i,j), squeeze(caldata(i,j,:)));
    end
end

end

function d = reverseinterp(ph, cal)
    if ph < cal(1)
        ph = ph+pi;
    end
    piv = find(dif(cal) < 0);
    if len(piv > 0)
        error
    else
        cal(piv+1:end) = cal(piv+1:end) + 2*pi;
    end
    d = interp1(cal,1:length(cal),ph);
end