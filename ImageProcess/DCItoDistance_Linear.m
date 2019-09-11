function [distances, qualities, phases] = DCItoDistance_Linear(datstruct, params, TIMEDELAY)
%Jacob Bernstein

%Input:
%%% datstruct.DCS

%Output:
%%% datstruct.distances
%%% datstruct.qualities
switch nargin
    case 1
        params = [];
        TIMEDELAY = [];
    case 2
        TIMEDELAY = [];
end
if isempty(TIMEDELAY)
    TIMEDELAY=2*17.5e-9;
    %TIMEDELAY=0;
end

SPEEDOFLIGHT = 3e8;%m/s
%N_WATER = 1.33;

if ~isfield(datstruct,'modFreq')
    datstruct.modFreq = 1;
end

if ~isfield(datstruct,'frequency')
    datstruct.frequency = 24e6/(1+datstruct.modFreq);
end

wavelength = SPEEDOFLIGHT/(datstruct.frequency*datstruct.RefractiveIndex*2);
phasedelay = TIMEDELAY*datstruct.frequency;

if size(datstruct.DCS,3) == 2
    [phases, qualities] = arrayfun(@distLin,...
        squeeze(datstruct.DCS(:,:,1)),squeeze(datstruct.DCS(:,:,2)));
else
    [phases, qualities] = arrayfun(@distLin,...
        squeeze(datstruct.DCS(:,:,1))-squeeze(datstruct.DCS(:,:,3)),...
        squeeze(datstruct.DCS(:,:,2))-squeeze(datstruct.DCS(:,:,4)));
end
phases = phases-phasedelay;
distances = phases*wavelength;
end

function [p,q] = distLin(DCI0,DCI1)
    amp = abs(DCI0) + abs(DCI1);
    %TODO - check for oversaturated pixels
    if (DCI0 ==0 && DCI1 == 0)
        p = 0;
        q = 0;
    else
        q = sqrt(DCI0^2 + DCI1^2);
        normDCI0 = DCI0/amp;
        normDCI1 = DCI1/amp;
        if normDCI1 > 0
            p = 0.5*(1 - normDCI0/2);
        else
            p = mod(normDCI0/2, 1);
        end
    end    
    if isa(DCI0, 'single')
        p = single(p);
        q = single(q);
    end
end

