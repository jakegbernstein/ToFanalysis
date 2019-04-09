function inverseDCI = analyzeLEDoutput(filename,plotfigs)
%%%Jacob Bernstein
%%%4/5/2019
%%%Analyze LED light output power

%% Input processing
switch nargin
    case 1
        plotfigs = false;
end

%% Parameters
inverseDCI = [];
triggerthreshold = 0.825; %3.3V signal into 50 Ohms -> 1.65V peak-to-peak

%% File load and preprocessing
%%%Hard code in starting line when using SDS2340x oscilloscope
datastartline=19; %0-indexed
%%%
%%%Hard code in channels for LED and trigger signals
chan_LEDtime = 1;
chan_LED = 2;
chan_triggertime = 3;
chan_trigger = 4;

%Load in the data
rawdat = csvread(filename,datastartline,0);
scopeinterval = rawdat(2,chan_LEDtime) - rawdat(1,chan_LEDtime);
lightfreq = 12e6;
lightperiod = 1/lightfreq;

%Figure out interpolation value
[~,d] = rat(lightperiod/scopeinterval);
fineinterval = scopeinterval/d;
finetime = linspace(rawdat(1,chan_LEDtime),rawdat(end,chan_LEDtime),...
    1 + d*(rawdat(end,chan_LEDtime) - rawdat(1,chan_LEDtime))/scopeinterval);
fineLED  = interp1(rawdat(:,chan_LEDtime),rawdat(:,chan_LED), finetime, 'makima');
finetrig = interp1(rawdat(:,chan_triggertime),rawdat(:,chan_trigger), finetime, 'makima');
%% Analysis
%%%Calculate the mean waveform
%Trigger on falling value
%trigindices = find( (rawdat(1:end-1,chan_trigger) > triggerthreshold) &...
%                    (rawdat(2:end,  chan_trigger) < triggerthreshold));
trigindices = find( (finetrig(1:end-1) > triggerthreshold) &...
                    (finetrig(2:end)   < triggerthreshold));
wavelength = trigindices(2) - trigindices(1);
%Check to make sure our clocks are good
if ~isempty(find((trigindices(2:end)-trigindices(1:end-1)) ~= wavelength))
    warning("Your clocks are messed up!")
end
meanwaveform = mean(reshape(fineLED(trigindices(1)+(1:wavelength*(length(trigindices)-1))),wavelength,[]),2);

if plotfigs
    figure
    plot(fineinterval*(1:wavelength),meanwaveform)
    title('Mean LED Power Output')
    xlabel('Time (s)')
    ylabel('Power (A.U.)')
end

%%% Calculate DCI convolution as a function of temporal shift
DCI = @(shift) sum(meanwaveform(mod(shift+(1:wavelength),wavelength) <  wavelength/2)) -...
               sum(meanwaveform(mod(shift+(1:wavelength),wavelength) >= wavelength/2));
DCIconv = arrayfun(DCI,1:wavelength);
DCIconvshift = [DCIconv(.75*wavelength+1:end),DCIconv(1:.75*wavelength)];
DCIamplitude = abs(DCIconv)+abs(DCIconvshift);
normDCIconv = DCIconv ./ DCIamplitude;
normDCIconvshift = DCIconvshift ./ DCIamplitude;
normDCIconv(wavelength+1) = normDCIconv(1);
normDCIconvshift(wavelength+1) = normDCIconvshift(1);

if plotfigs
    figure
    subplot(3,1,1)
    plot((1:wavelength)/wavelength,DCIconv,'b')
    hold on
    plot((1:wavelength)/wavelength,DCIconvshift,'r')
    subplot(3,1,2)
    plot((1:wavelength)/wavelength,DCIamplitude)
    temp =ylim();
    ylim([0,temp(2)])
    subplot(3,1,3)
    plot((1:wavelength+1)/wavelength,normDCIconv,'b')
    hold on
    plot((1:wavelength+1)/wavelength,normDCIconvshift,'r')
end

%%% Calculate deviation of real LED waveform from ideal
%Construct ideal line based on zero crossings
p0rising = invertDCI(0,-1);
p0falling = invertDCI(0,1);
if abs(p0rising - p0falling) ~= .5
    warning('Duty cycle is not 50%')
end
idslope = 4/wavelength;
idstartind = ceil(p0rising*wavelength);
idstartval = idslope*(idstartind-p0rising*wavelength);
idconv(1+mod(idstartind-1+[0:wavelength-1],wavelength)) = arrayfun(@triwave,idstartval + idslope*[0:wavelength-1]);
figure
subplot(3,1,1)
plot(normDCIconv)
hold on
plot(idconv)
subplot(3,1,2)
plot(normDCIconv(1:end-1)-idconv)
subplot(3,1,3)
plot(abs((normDCIconv(2:end)-normDCIconv(1:end-1))))


    function out = triwave(amp)
        t = mod(amp,4);
        if t<1
            out = t;
        elseif t<3
            out = 2-t;
        else
            out = t-4;
        end
    end


%% Make inverse function
%Given DCI values, calculate phase shift
%Assume that DCI sections are monotonic
%Figure out section, then interpolate between points
    function [phase, quality] = invertDCI(DCI0,DCI1,varargin)
        switch nargin
            case 4
            DCI0 = DCI0 - varargin{1};
            DCI1 = DCI1 - varargin{2};
        end
        amp = abs(DCI0) + abs(DCI1);
        if find(isnan([DCI0,DCI1]))
            quality = NaN;
            phase = -1;
        elseif (DCI0 == 0 && DCI1 == 0)
            phase = -1;
            quality = 0;
        else
            quality = sqrt(DCI0^2 + DCI1^2);
            normDCI0 = DCI0/amp;
            normDCI1 = DCI1/amp;
            %Special case: normDCI0 = 1 or -1, then find where norm DCI1==0
            if normDCI0 >= max(normDCIconv)                
                riseind = find((normDCIconvshift(1:end-1) <= normDCI1) & ...
                               (normDCIconvshift(2:end)   >  normDCI1));
                slope = normDCIconvshift(riseind+1) - normDCIconvshift(riseind);
                est = (normDCI1 - normDCIconvshift(riseind))/slope;
                phase = mod((riseind + est)/wavelength, 1);
            elseif normDCI0 <= min(normDCIconv)
                fallind = find((normDCIconvshift(1:end-1) >= normDCI1) & ...
                               (normDCIconvshift(2:end)   <  normDCI1));                
                slope = normDCIconvshift(fallind+1) - normDCIconvshift(fallind);
                est = (normDCI1 - normDCIconvshift(fallind))/slope;
                phase = mod((fallind + est)/wavelength, 1);                
            else
                riseind = find((normDCIconv(1:end-1) <= normDCI0) & (normDCIconv(2:end) > normDCI0));
                fallind = find((normDCIconv(1:end-1) >= normDCI0) & (normDCIconv(2:end) < normDCI0));
                if ((normDCI1 > min(normDCIconvshift(riseind+(0:1)))) && (normDCI1 < max(normDCIconvshift(riseind+(0:1))))) || normDCI1 <= min(normDCIconvshift)
                    section = riseind+(0:1);
                else
                    section = fallind+(0:1);
                end
                slope = normDCIconv(section(2)) - normDCIconv(section(1));
                est = (normDCI0 - normDCIconv(section(1)))/slope;
                phase = mod((section(1) + est)/wavelength, 1);                
            end
        end
    end

inverseDCI = @invertDCI;
end

