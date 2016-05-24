function Spectra=creatingLprime(dpy)
% Spectra=creatingLprime(dpy)
% 
% dpy.LprimePosition = a value between 0 and 1 to specify location of the L prime
% peak between the L and M cones. Where 0 is M cone and 1 is L cone
% For example,to set Lprime peak half way between L and M, LprimePos=0.5
% 
% Import stockman CFs and create an Lprime CF by interpolating between the 
% M and L cone fundamentals. First shifts the L and M cones as specified
% for the subject.
%
% written by LW 050315

%set the location of the L prime with inputted LprimePos
locationLprime=dpy.LprimePosition; %e.g. 0.5 for half way

if locationLprime<1 || 0<locationLprime
    disp('Continue with LprimePosition values')
else
    error('Cannot use values outside 0 and 1 for the LprimePos with this script')
end

WLrange = dpy.WLrange; %desired WL range
%set the L and M cone peaks as specified, or default to the original peak
if isfield('Lpeak',dpy)==1
    Lpeak = dpy.Lpeak; %the subject's L peak
else 
    Lpeak = 570.5; %default
end
if isfield('Mpeak',dpy)==1
    Mpeak = dpy.Mpeak; %the subject's M peak
else
    Mpeak = 543; %default
end

%load in the 0.1nm stockmanCFs
load('stockman01nmCF.mat');
%assign WLs to variable
WL=stockman.wavelength;
%interpolate CFs to desired WL range
Lcone=interp1(WL,stockman.Lcone,WLrange);
Mcone=interp1(WL,stockman.Mcone,WLrange);
Scone=interp1(WL,stockman.Scone,WLrange);
CombinedRaw=cat(2,WLrange,Lcone,Mcone,Scone);

%% find the WL peak of the each cone, i.e. where sensitivity is 1
%L cone
LconeOriginal_indx = find(CombinedRaw(:,2) == 1);
%get the mean if more than one value is 1, round indx num to correspond to a row
LconeOriginal_indx = round(mean(LconeOriginal_indx));
%M cone
MconeOriginal_indx = find(CombinedRaw(:,3) == 1);
%get the mean if more than one value is 1, round indx num to correspond to a row
MconeOriginal_indx = round(mean(MconeOriginal_indx));

%% get the indx of the wavelength for the desired cone peaks
%L cone
try
    LpeakIndx=find(CombinedRaw(:,1) == Lpeak);
catch
    %if there isn't an exact match check across a slightly larger range and
    %use the average (rounded to match an actual row)
    LpeakIndx=find(CombinedRaw(:,1) <= (Lpeak+1) & CombinedRaw >= (Lpeak-1));
    LpeakIndx=round(mean(LpeakIndx));
end
%M cone
try
    MpeakIndx=find(CombinedRaw(:,1) == Mpeak);
catch
    %if there isn't an exact match check across a slightly larger range and
    %use the average (rounded to match an actual row)
    MpeakIndx=find(CombinedRaw(:,1) <= (Mpeak+1) & CombinedRaw >= (Mpeak-1));
    MpeakIndx=round(mean(MpeakIndx));
end

%% Shift the Entire column of sensitivity values 
%so that peak is on the peakIndx, by adding/removing rows from start and end of column
%L cone
shiftDistance=abs(LconeOriginal_indx-LpeakIndx); %rows to shift
newLConeSpec=CombinedRaw(:,2); %save out original spectra for the cone being shifted

%if shifting to shorter wavelength peak
if LconeOriginal_indx > LpeakIndx
    newLConeSpec=newLConeSpec(shiftDistance+1:end,1); %remove first rows corresponding to total number needing to shift
    newLConeSpec(end+1:end+shiftDistance,1)=0; %add 0's to end rows corresponding to total number needing to shift
%if shifting to longer wavelength peak
elseif LconeOriginal_indx < LpeakIndx
    newLConeSpec=cat(1,zeros(shiftDistance,1),newLConeSpec); %create zeros to add to front of spectra
    newLConeSpec=newLConeSpec(1:(length(newLConeSpec)-shiftDistance),:); %remove last rows from spectra
end
%N.B. if peak already matches, no adjustment needed

%M cone
shiftDistance=abs(MconeOriginal_indx-MpeakIndx); %rows to shift
newMConeSpec=CombinedRaw(:,3); %save out original spectra for the cone being shifted

%if shifting to shorter wavelength peak
if MconeOriginal_indx > MpeakIndx
    newMConeSpec=newMConeSpec(shiftDistance+1:end,1); %remove first rows corresponding to total number needing to shift
    newMConeSpec(end+1:end+shiftDistance,1)=0; %add 0's to end rows corresponding to total number needing to shift
%if shifting to longer wavelength peak
elseif MconeOriginal_indx < peakIndx
    newMConeSpec=cat(1,zeros(shiftDistance,1),newMConeSpec); %create zeros to add to front of spectra
    newMConeSpec=newMConeSpec(1:(length(newMConeSpec)-shiftDistance),:); %remove last rows from spectra
end
%N.B. if peak already matches, no adjustment needed

%% store L and M cone peaks for sub
subLpeak=Lpeak; 
subMpeak=Mpeak;  

%concatenate with the wavelengths
LconeWL=cat(2,WLrange,newLConeSpec);
MconeWL=cat(2,WLrange,newMConeSpec);
SconeWL=cat(2,WLrange,Scone);

%% interpolate L and M curves, in two halves.
%split values into two halves, i.e. 0 to 1, and 1 to 0, as interp can't process
%full curve in one go due to the increasing then decreasing values
%This is now automated, so finds all '1' peak values and uses first 1 to be
%end point for the first half of curve, and last 1 to be starting point of
%second half of curve

%L cone
Lindx=1;
for thisL=1:length(LconeWL)
    if LconeWL(thisL,2)==1
        WLindexL(Lindx,1)=thisL;
        Lindx=Lindx+1;
    end
end
LconePart1=LconeWL(1:WLindexL(1),:);
LconePart2=LconeWL(WLindexL(end):end,:);

%M cone
Mindx=1;
for thisM=1:length(MconeWL)
    if MconeWL(thisM,2)==1
        WLindexM(Mindx,1)=thisM;
        Mindx=Mindx+1;
    end
end
MconePart1=MconeWL(1:WLindexM(1),:);
MconePart2=MconeWL(WLindexM(end):end,:);

%S cone
Sindx=1;
for thisS=1:length(SconeWL)
    if SconeWL(thisS,2)==1
        WLindexS(Sindx,1)=thisS;
        Sindx=Sindx+1;
    end
end
SconePart1=SconeWL(1:WLindexS(1),:);
SconePart2=SconeWL(WLindexS(end):end,:);


%specify range of sensitivity values for Lprime and desired peak
valRangePart1=(0.001:0.001:1)'; %values to interpolate in to for first half of curve (low to high)
valRangePart2=flipud(valRangePart1); %values to interpolate to for second half of curve (i.e. high to low)
LPrimePeak=round((subLpeak-subMpeak)*locationLprime); %round peak so integer

% Interpolate Part 1 of the curves to given sensitivity range
xL1 = interp1(LconePart1(:,2),LconePart1(:,1),valRangePart1); %l cone
xM1 = interp1(MconePart1(:,2),MconePart1(:,1),valRangePart1); %m cone
%xS1 = interp1(SconePart1(:,2),SconePart1(:,1),valRangePart1); %s cone
% Interpolate Part 2 of the curves to given sensitivities. 
xL2 = interp1(LconePart2(:,2),LconePart2(:,1),valRangePart2); %l cone
xM2 = interp1(MconePart2(:,2),MconePart2(:,1),valRangePart2); %m cone
%xS2 = interp1(SconePart2(:,2),SconePart2(:,1),valRangePart2); %s cone

%calculate LPrime WLs for the given sensitivity range using the 
%interpolated L and M sensitivities.
%part 1
lPrimePart1(:,1) = xM1 + ((xL1-xM1)*(LPrimePeak/(subLpeak-subMpeak)));
%part2
lPrimePart2(:,1) = xM2 + ((xL2-xM2)*(LPrimePeak/(subLpeak-subMpeak)));

%combine part 1 and part 2.  First need to to flip the values for the
%second part (see note above), so that the WL values will increase across full
%range
fullValRange=cat(1,valRangePart1,valRangePart2);

%concatenate into full curve - N.B. these LMS curves aren't really used, but
%may as well be recreated while Lprime is created
allLconeCF=cat(1,xL1,xL2);
allMconeCF=cat(1,xM1,xM2);
%allSconeCF=cat(1,xS1,xS2);
allLprimeconeCF=cat(1,lPrimePart1,lPrimePart2); %this is the useful one

cones.allLconeCFWLs=cat(2,allLconeCF,fullValRange);
cones.allMconeCFWLs=cat(2,allMconeCF,fullValRange);
cones.allSconeCFWLs=cat(2,Scone,WL);
cones.allLprimeconeCFWLs=cat(2,allLprimeconeCF,fullValRange);

%labels for cone variables - these must match those above! excluding the
%'cone.' part of the name
conevariables={'allLconeCFWLs','allMconeCFWLs','allSconeCFWLs','allLprimeconeCFWLs'};
%remove any NaN rows from vals for each cone
for thisConeVar=1:size(conevariables,2)
    currentCone=conevariables{thisConeVar};
    j=1; %index
    for thisRow=1:length(cones.(currentCone))
        if isnan(cones.(currentCone)(j,1))
            cones.(currentCone)(j,:)=[];
        else
            j=j+1;
        end
    end
end
    
% 
% %interpolate across the desired WL range set above, so in necessary format for use in
% %script
% %resample to desired WLrange (needed to avoid duplicate values, which can't 
% %be used in the interp)

%use original LMS values
finalLcone=newLConeSpec; %l cone
finalMcone=newMConeSpec; %m cone
finalScone=Scone; %s cone

% %or could use the recreated curve, but best to only have one 'new' curve,
% i.e. the Lprime
% finalLcone1nmResample=interp1(cones.allLconeCFWLs(:,1),cones.allLconeCFWLs(:,2),WLrange); %l cone
% finalMcone1nmResample=interp1(cones.allMconeCFWLs(:,1),cones.allMconeCFWLs(:,2),WLrange); %m cone
% finalScone1nmResample=interp1(cones.allSconeCFWLs(:,1),cones.allSconeCFWLs(:,2),WLrange); %s cone

%Lprime
finalLprimecone1nmResample=interp1(cones.allLprimeconeCFWLs(:,1),cones.allLprimeconeCFWLs(:,2),WLrange);

%save out spectra with wavelengths (WL,L,L',M,S)
Spectra=cat(2,WLrange,finalLcone,finalLprimecone1nmResample,finalMcone,finalScone);

