function [Spectra,dpy]=creatingShiftedConeSpectra(dpy)
% [Spectra,dpy]=creatingShiftedConeSpectra(dpy)
% 
% creates spectra for L M and S cones, where the L or M cone has a shifted
% peak, as determined by dpy variables:
%
% dpy.shiftCone = either 'L' or 'M' cone
%    .shiftPeak = the new peak wavelength (lambdaMax) for the specified cone
%    .WLrange   = the range of wavelengths required for the output e.g. 400:0.5:720
% 
% Import stockman CFs and output single matrix of desired wavelengths and
% LMS spectra.
% The spectra for the shifted cone will be created by shifting the entire 
% Lcone or Mcone spectra by the necessary amount to align the peak with the
% desired new cone peak position.
%
% written by LW 220516


WLrange = dpy.WLrange; %desired WL range
shiftPeak = dpy.shiftPeak; %the shift in nm from the original cone peak
shiftCone = dpy.shiftCone; %the cone to shift

%check whether need to work from the standard stockman CFs, or if any peaks
%have been specified for the L or M cones
if isfield(dpy,'Lpeak')==1 || isfield(dpy,'Mpeak')==1
    Spectra=creatingLprime(dpy); %also exports an Lprime in col3, which we don't need here
    WL=Spectra(:,1);
    Lcone=interp1(WL,Spectra(:,2),WLrange);
    Mcone=interp1(WL,Spectra(:,4),WLrange);
    Scone=interp1(WL,Spectra(:,5),WLrange);
    dpy.theBaseSpectraUsed='usedSpecifiedPeaks';

else %if not pre-defined
%load in the 0.1nm stockmanCFs
load('stockman01nmCF.mat');
dpy.theBaseSpectraUsed='normalStockman';
%assign WLs to variable
WL=stockman.wavelength;
%interpolate CFs to desired WL range
Lcone=interp1(WL,stockman.Lcone,WLrange);
Mcone=interp1(WL,stockman.Mcone,WLrange);
Scone=interp1(WL,stockman.Scone,WLrange);
end
CombinedRaw=cat(2,WLrange,Lcone,Mcone,Scone);
CombinedLabels={'WL','Lcone','Mcone','Scone'};
%get the indx for the cone to shift - by comparing strings
coneIndx=strncmp(CombinedLabels,shiftCone,1);

%find the WL peak of the cone (coneIndx), i.e. where sensitivity is 1
coneToShiftWL_indx = find(CombinedRaw(:,coneIndx) == 1);
%get the mean if more than one value is 1, round indx num to correspond to a row
coneToShiftWL_indx = round(mean(coneToShiftWL_indx));

%store original peak
dpy.originalPeakWL=CombinedRaw(coneToShiftWL_indx,1);
%calculate the shifted peak wavelength
dpy.shiftPeakWL=CombinedRaw(coneToShiftWL_indx,1)+shiftPeak;

%get the indx of the wavelength for the desired cone peak
try
    peakIndx=find(CombinedRaw(:,1) == dpy.shiftPeakWL);
catch
    %if there isn't an exact match check across a slightly larger range and
    %use the average (rounded to match an actual row)
    peakIndx=find(CombinedRaw(:,1) <= (dpy.shiftPeakWL+1) & CombinedRaw >= (dpy.shiftPeakWL-1));
    peakIndx=round(mean(peakIndx));
end

%Shift the Entire column of sensitivity values so that peak is on the
%peakIndx, by adding/removing rows from start and end of column
shiftDistance=abs(coneToShiftWL_indx-peakIndx); %rows to shift
newConeSpec=CombinedRaw(:,coneIndx); %save out original spectra for the cone being shifted

%if shifting to shorter wavelength peak
if coneToShiftWL_indx > peakIndx
    newConeSpec=newConeSpec(shiftDistance+1:end,1); %remove first rows corresponding to total number needing to shift
    newConeSpec(end+1:end+shiftDistance,1)=0; %add 0's to end rows corresponding to total number needing to shift
%if shifting to longer wavelength peak
elseif coneToShiftWL_indx < peakIndx
    newConeSpec=cat(1,zeros(shiftDistance,1),newConeSpec); %create zeros to add to front of spectra
    newConeSpec=newConeSpec(1:(length(newConeSpec)-shiftDistance),:); %remove last rows from spectra
end
%N.B. if peak already matches, no adjustment needed

%save out spectra with wavelengths (WL,L,M,S)
if strcmp(shiftCone,'L')==1 %if shifting L cone
    Spectra=cat(2,WLrange,newConeSpec,Mcone,Scone);
elseif strcmp(shiftCone,'M')==1 %if shifting M cone
    Spectra=cat(2,WLrange,Lcone,newConeSpec,Scone);
end

