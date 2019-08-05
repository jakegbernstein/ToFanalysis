function datstruct = DCItoDistance_Linear(datstruct, params)
%Jacob Bernstein

%Output:
%%% datstruct.distances
%%% datstruct.qualities
SPEEDOFLIGHT = 3e8;
N_WATER = 1.33;

switch nargin
    case 1
        params = [];
end

if ~isfield(params,'modfreq')
    params.modfreq = 12e6;
end

wavelength = SPEEDOFLIGHT/(params.modfreq*N_WATER*2);

if size(datstruct.raw,3) == 2
    [datstruct.phases, datstruct.qualities] = arrayfun(@distLin,...
        squeeze(datstruct.raw(:,:,1)),squeeze(datstruct.raw(:,:,2)));
else
    [datstruct.phases, datstruct.qualities] = arrayfun(@distLin,...
        squeeze(datstruct.raw(:,:,1))-squeeze(datstruct.raw(:,:,3)),...
        squeeze(datstruct.raw(:,:,2))-squeeze(datstruct.raw(:,:,4)));
end
datstruct.distances = datstruct.phases*wavelength/(2*pi);
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
            p = pi*(1 - normDCI0/2);
        else
            p = mod(normDCI0*pi/2, 2*pi);
        end
    end    
end

