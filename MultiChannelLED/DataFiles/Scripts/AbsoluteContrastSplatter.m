function Data = AbsoluteContrastSplatter
% Data = AbsoluteContrastSplatter
% 
% Produces estimate of absolute contrast splatter (across all silenced
% cones) for a given cone isolating condition, by accounting for a
% specified max difference in observer lambdaMax values compared to those
% used to produce the stimulus.
%
% Load in a datafile containing outputted cone excitation and cone contrast 
% info for shifted cone spectra.  Interpolate points in smaller step sizes.
%
% Extract contrasts corresponding to specified standard deviation in cone
% shifts.  Stdevs used by Spitschan et al (2015) are:
%   L   =   1.5
%   M   =   0.9
%   S   =   0.8
%
% For estimating the splatter on an L-prime, we will be conservative and
% assuming the higher Stdev of the L and M cones (i.e. 1.5)
%
% Takes the larger of the two contrast values (one either direction from
% original lambdaMax).
%
% written by LEW 070616

%prompt to select the data file
theDataFile=uigetfile(pwd,'Select the datafile for a single condition');
TheData=importdata((theDataFile));

%save condition name
condition=TheData.data.dpy.ExptID; %expt ID
numSpec=TheData.data.dpy.NumSpec; %number of cone spectra

if numSpec==3
    coneLabels={'L','M','S'};
    coneStdevLevel=[1.5,0.9,0.8];
elseif numSpec==4
    coneLabels={'L','LP','M','S'};
    coneStdevLevel=[1.5,1.5,0.9,0.8];
end

%Store the range of wavelength shifts used e.g. -5:0.5:5
WLrange=TheData.ShiftedConeExcitation.WLshiftVals';

%specify the desired range - using 0.1 so a level will correspond to the
%shifts specified in StDev above
newWLrange=(min(WLrange):0.1:max(WLrange))';

%store the cone contrasts - note that we are using actual calculated
%values, not the ConeContrastChange in contrast
coneContrast=TheData.ShiftedConeExcitation.ConeContrast;
numCones=size(TheData.ShiftedConeExcitation.ConeContrast,2);

%interpolate all the cone contrast values to the new range
%do separately for the negative and positive shifts (else interp wont work)

%save out all necessary values for Pos and Neg
Data.Neg.WLrange=WLrange(1:round(length(WLrange)/2)); %original WL shift range
Data.Neg.newWLrange=newWLrange(1:round(length(newWLrange)/2)); %new WL shift range
Data.Neg.coneContrasts=coneContrast(1:round(length(coneContrast)/2),:); %cone contrast

Data.Pos.WLrange=WLrange(end-(round(length(WLrange)/2)-1):end); %original WL shift range
Data.Pos.newWLrange=newWLrange(end-(round(length(newWLrange)/2)-1):end); %new WL shift range
Data.Pos.coneContrasts=coneContrast(end-(round(length(coneContrast)/2)-1):end,:); %cone contrast

%run the interp
try
Data.Neg.NewConeContrasts=interp1(Data.Neg.WLrange,Data.Neg.coneContrasts,Data.Neg.newWLrange); %neg
catch
    disp('Could not run Neg interp, values do not monotonically decrease.  Attempting smaller range.')
    Data.Neg.WLrange=Data.Neg.WLrange(end-19:end); 
    Data.Neg.newWLrange=Data.Neg.newWLrange(end-19:end); 
    Data.Neg.coneContrasts=Data.Neg.coneContrasts(end-19:end);
    Data.Neg.NewConeContrasts=interp1(Data.Neg.WLrange,Data.Neg.coneContrasts,Data.Neg.newWLrange); %neg
end

try
Data.Pos.NewConeContrasts=interp1(Data.Pos.WLrange,Data.Pos.coneContrasts,Data.Pos.newWLrange); %pos
catch
    disp('Could not run Pos interp, values do not monotonically increase.  Attempting smaller range.')
    Data.Pos.WLrange=Data.Pos.WLrange(1:20); 
    Data.Pos.newWLrange=Data.Pos.newWLrange(1:20); 
    Data.Pos.coneContrasts=Data.Pos.coneContrasts(1:20);

    Data.Pos.NewConeContrasts=interp1(Data.Pos.WLrange,Data.Pos.coneContrasts,Data.Pos.newWLrange); %pos
end

%for each cone, find the relevant row for the stdev, an extract the cone
%contrast value
for thisCone=1:numCones
    curStdev=coneStdevLevel(thisCone);
    %for neg shift
    rowNegShiftIndx=(round(Data.Neg.newWLrange,1)==-curStdev);
    Data.Neg.StDevValConeContrast(1,thisCone)=Data.Neg.NewConeContrasts(rowNegShiftIndx,thisCone);
    %for pos shift
    rowPosShiftIndx=(round(Data.Pos.newWLrange,1)==curStdev);
    Data.Pos.StDevValConeContrast(1,thisCone)=Data.Pos.NewConeContrasts(rowPosShiftIndx,thisCone);
    
    %combine and find max val for each cone
    Data.Combined.ConeContrasts(:,thisCone)=cat(1,Data.Neg.StDevValConeContrast(1,thisCone),Data.Pos.StDevValConeContrast(1,thisCone));
    [~,maxIndx]=max(abs(Data.Combined.ConeContrasts(:,thisCone)));
    Data.Combined.MaxConeContrasts(1,thisCone)=Data.Combined.ConeContrasts(maxIndx,thisCone);
end

%Calculate the absolute cone contrast by summing across all the SILENCED cone contrasts,
%i.e. cones that aren't being isolated for the condition.
%N.B. this could be neater, and more future proof. but for now it'll do...
switch condition
    case 'L'
        if numSpec==3
            silencedConeIndx=[2,3];
        elseif numSpec==4
            silencedConeIndx=[2,3,4];
        end
    case 'M'
        if numSpec==3
            silencedConeIndx=[1,3];
        elseif numSpec==4
            silencedConeIndx=[1,2,4];
        end
    case 'S'
        if numSpec==3
            silencedConeIndx=[1,2];
        elseif numSpec==4
            silencedConeIndx=[1,2,3];
        end
    case 'LP' %can't be 3 cones for this one
        if numSpec==4
            silencedConeIndx=[1,3,4];
        end
    case 'LMS'%no cones to silence in 3 cone condition
        if numSpec==4
            silencedConeIndx=[2];
        end
    case 'LM'
        if numSpec==3
            silencedConeIndx=[3];
        elseif numSpec==4
            silencedConeIndx=[2,4];
        end
end

%sum across the silenced-cones contrasts'
try
    Data.Combined.AbsoluteContrastSplatter=...
        sum(abs(Data.Combined.MaxConeContrasts(1,silencedConeIndx)));   
catch
    %set to zero if there are no silenced cones e.g. in LMS condition
    Data.Combined.AbsoluteContrastSplatter=0;
end
end