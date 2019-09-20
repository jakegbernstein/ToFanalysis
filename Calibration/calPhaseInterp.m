function delay = calPhaseInterp(DCS, caldata, goodpixels)


%1: Measure phase
phase = atan((DCS(:,:,2)-DCS(:,:,4))./(DCS(:,:,1)-DCS(:,:,3)));
pishiftinds = find((DCS(:,:,1)-DCS(:,:,3)) >= 0);
phase(pishiftinds) = phase(pishiftinds) + pi;

naninds = find(isnan(phase));
goodpixels(naninds) = 0;

test = permute(caldata,[3 1 2]);

%2: Interpolate back to dll
tic
delay = zeros(size(DCS,1),size(DCS,2));
badpixels = [];
for i=1:size(DCS,1)
    %for j=1:size(DCS,2)
    for j=find(goodpixels(i,:))
        %delay(i,j) = reverseinterp(phase(i,j), squeeze(caldata(i,j,:)));
        delay(i,j) = reverseinterp(phase(i,j), test(:,i,j));
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
