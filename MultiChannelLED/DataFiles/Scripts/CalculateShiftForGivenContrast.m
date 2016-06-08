function Data = CalculateShiftForGivenContrast
% Data = CalculateShiftForGivenContrast
% 
% Produces an estimate of the shift in peak wavelength necessary for a cone  
% to acquire a specified level of contrast splatter (across all silenced
% cones) for a given cone isolating condition.
%
% Load in a datafile containing outputted cone excitation and cone contrast 
% info for shifted cone spectra.  Interpolate points in smaller step sizes.
%
% Extract shifts corresponding to specified cone contrasts e.g:
%   L   =   0.33
%   M   =   0.41
%   S   =   5
%
%
% Takes the larger of the two shift values matching the contrast (one in
% either direction from original lambdaMax).
%
% written by LEW 080616

%prompt to select the data file
theDataFile=uigetfile(pwd,'Select the datafile for a single condition');
TheData=importdata((theDataFile));

%save condition name
condition=TheData.data.dpy.ExptID; %expt ID
numSpec=TheData.data.dpy.NumSpec; %number of cone spectra

if numSpec==3
    coneLabels={'L','M','S'};
    contrastLevel=[0.33,0.41,5];
elseif numSpec==4
    coneLabels={'L','LP','M','S'};
    contrastLevel=[0.33,0.33,0.41,5];
end

%Store the range of wavelength shifts used e.g. -5:0.5:5
WLrange=TheData.ShiftedConeExcitation.WLshiftVals';

%specify the desired range - using 0.01 so a level will correspond to the
%shifts specified in StDev above
newWLrange=(min(WLrange):0.01:max(WLrange))';

%store the cone contrasts - note that we are using actual calculated cone
%contrast values, not the ConeContrastChange 
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
    Data.Neg.WLrange=Data.Neg.WLrange(end-((length(Data.Neg.WLrange)/2)-1):end); 
    Data.Neg.newWLrange=Data.Neg.newWLrange(end-((length(Data.Neg.WLrange)/2)-1):end); 
    Data.Neg.coneContrasts=Data.Neg.coneContrasts(end-((length(Data.Neg.WLrange)/2)-1):end);
    Data.Neg.NewConeContrasts=interp1(Data.Neg.WLrange,Data.Neg.coneContrasts,Data.Neg.newWLrange); %neg
end

try
Data.Pos.NewConeContrasts=interp1(Data.Pos.WLrange,Data.Pos.coneContrasts,Data.Pos.newWLrange); %pos
catch
    disp('Could not run Pos interp, values do not monotonically increase.  Attempting smaller range.')
    Data.Pos.WLrange=Data.Pos.WLrange(1:(length(Data.Neg.WLrange)/2)); 
    Data.Pos.newWLrange=Data.Pos.newWLrange(1:(length(Data.Neg.WLrange)/2)); 
    Data.Pos.coneContrasts=Data.Pos.coneContrasts(1:(length(Data.Neg.WLrange)/2));

    Data.Pos.NewConeContrasts=interp1(Data.Pos.WLrange,Data.Pos.coneContrasts,Data.Pos.newWLrange); %pos
end

%for each cone, find the relevant row for the cone contrast, and extract 
%the wavelength shift value
for thisCone=1:numCones
    curContrast=contrastLevel(thisCone);
    %for neg shift
    rowNegContrastIndx=(round(Data.Neg.NewConeContrasts(:,thisCone),2)==-curContrast);
    Data.Neg.ShiftValue(1,thisCone)=mean(Data.Neg.newWLrange(rowNegContrastIndx,1));
    %for pos shift
    rowPosContrastIndx=(round(Data.Pos.NewConeContrasts(:,thisCone),2)==curContrast);
    Data.Pos.ShiftValue(1,thisCone)=mean(Data.Pos.newWLrange(rowPosContrastIndx,1));
    
    %combine and find max val for each cone
    Data.Combined.ConeShifts(:,thisCone)=cat(1,Data.Neg.ShiftValue(1,thisCone),Data.Pos.ShiftValue(1,thisCone));
    [~,maxIndx]=max(abs(Data.Combined.ConeShifts(:,thisCone)));
    Data.Combined.MaxAbsConeShift(1,thisCone)=abs(Data.Combined.ConeShifts(maxIndx,thisCone));
end
end