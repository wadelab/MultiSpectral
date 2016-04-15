function Spectra=creatingLprime(dpy)
% Spectra=creatingLprime(dpy)
% 
% dpy.LprimePosition = a value between 0 and 1 to specify location of the L prime
% peak between the L and M cones. Where 0 is M cone and 1 is L cone
% For example,to set Lprime peak half way between L and M, LprimePos=0.5
%
% Import stockman CFs and create an Lprime CF by interpolating between the 
% M and L cone fundamentals.
%
% written by LW 050315

%set the location of the L prime with inputted LprimePos
locationLprime=dpy.LprimePosition; %e.g. 0.5 for half way

if locationLprime<1 || 0<locationLprime
    disp('Continue with LprimePosition values')
else
    error('Cannot use values outside 0 and 1 for the LprimePos with this script')
end

%desired WL range
WLrange=dpy.WLrange; %N.B. for now must be 400 and 720, else interp won't work - would need to edit part 1 and 2 values too if this changes

%load in the 0.1nm stockmanCFs (downloaded from CVRL website)
load('stockman01nmCF.mat');
%assign cones and WLs to variables
Lcone=stockman.Lcone;
Mcone=stockman.Mcone;
Scone=stockman.Scone;
WL=stockman.wavelength;

%concatenate with WLs
LconeWL=cat(2,WL,Lcone);
MconeWL=cat(2,WL,Mcone);
SconeWL=cat(2,WL,Scone);

%calculate L and M cone peaks by averaging the WL values that correspond to
%a spectra val of 1

%for the L cone
l=1; %index
for thisWL=1:length(LconeWL) %for each row (wavelength)
    if LconeWL(thisWL,2)==1 %check if the spectra in col 2 equals 1
        lconePeakVals(l,1)=LconeWL(thisWL,1);%save out the wavelength if spectra val was 1
        l=l+1; %update index
    else continue
    end
end
stockmanLpeak=mean(lconePeakVals); %average the lconePeakVals (in case more than 1) to get L cone peak wavelength

%repeat for the M cone
m=1; %index
for thisWL=1:length(MconeWL) %for each row (wavelenth)
    if MconeWL(thisWL,2)==1 %check if spectra equals 1
        mconePeakVals(m,1)=MconeWL(thisWL,1); %if so, save out corresponding wavelength
        m=m+1; %update index
    else continue
    end
end
stockmanMpeak=mean(mconePeakVals); %average the mconePeakVals 

%resample to desired WLrange (needed to avoid duplicate values, which can't 
%be used in the interp), and then concatenate with desired WLrange
Lcone1nmResample=interp1(LconeWL(:,1),LconeWL(:,2),WLrange); %l cone
Lcone1nmWL=cat(2,WLrange,Lcone1nmResample);
Mcone1nmResample=interp1(MconeWL(:,1),MconeWL(:,2),WLrange); %m cone
Mcone1nmWL=cat(2,WLrange,Mcone1nmResample);
Scone1nmResample=interp1(SconeWL(:,1),SconeWL(:,2),WLrange); %s cone
Scone1nmWL=cat(2,WLrange,Scone1nmResample);


%split values into two halves, i.e. 0 to 1, and 1 to 0, as interp can't process
%full curve in one go due to the increasing then decreasing values
%This is now automated, so finds all '1' peak values and uses first 1 to be
%end point for the first half of curve, and last 1 to be starting point of
%second half of curve

%L cone
Lindx=1;
for thisL=1:length(Lcone1nmWL)
    if Lcone1nmWL(thisL,2)==1
        WLindexL(Lindx,1)=thisL;
        Lindx=Lindx+1;
    end
end
LconePart1=Lcone1nmWL(1:WLindexL(1),:);
LconePart2=Lcone1nmWL(WLindexL(end):end,:);

%M cone
Mindx=1;
for thisM=1:length(Mcone1nmWL)
    if Mcone1nmWL(thisM,2)==1
        WLindexM(Mindx,1)=thisM;
        Mindx=Mindx+1;
    end
end
MconePart1=Mcone1nmWL(1:WLindexM(1),:);
MconePart2=Mcone1nmWL(WLindexM(end):end,:);

%S cone
Sindx=1;
for thisS=1:length(Scone1nmWL)
    if Scone1nmWL(thisS,2)==1
        WLindexS(Sindx,1)=thisS;
        Sindx=Sindx+1;
    end
end
SconePart1=Scone1nmWL(1:WLindexS(1),:);
SconePart2=Scone1nmWL(WLindexS(end):end,:);

% %manual splitting into curves using known row vals - not ideal though so
% now automated above. kept here in case there are any issues with the
% above code
% LconePart1=Lcone1nmWL(1:170,:); %l cone prev 170
% LconePart2=Lcone1nmWL(172:end,:); % prev 172
% MconePart1=Mcone1nmWL(1:143,:); %m cone prev143
% MconePart2=Mcone1nmWL(144:end,:); %prev144
% SconePart1=Scone1nmWL(1:43,:); %s cone prev43
% SconePart2=Scone1nmWL(44:114,:); %prev44 to114

% % this check has also been cut as there wasn't a built in solution if
% values didn't monotonically increase, so it'll error anyway
% %use this to check that values are monotonically increasing, highlight where the error is if not
% for thisRow=1:length(LconePart1)-1
%     if LconePart1(thisRow,2)>=LconePart1(thisRow+1,2)
%         fprintf('Row %d greater than row %d\n',thisRow,thisRow+1)
%     else
%         continue
%     end
% end

%specify range of sensitivity values for Lprime and desired peak
valRangePart1=(0.01:0.005:1)'; %values to interpolate in to for first half of curve (low to high)
valRangePart2=flipud(valRangePart1); %values to interpolate to for second half of curve (i.e. high to low)
LPrimePeak=round((stockmanLpeak-stockmanMpeak)*locationLprime); %round peak so integer

% Interpolate Part 1 of the curves to given sensitivity range
xL1 = interp1(LconePart1(:,2),LconePart1(:,1),valRangePart1); %l cone
xM1 = interp1(MconePart1(:,2),MconePart1(:,1),valRangePart1); %m cone
xS1 = interp1(SconePart1(:,2),SconePart1(:,1),valRangePart1); %s cone
% Interpolate Part 2 of the curves to given sensitivities. 
xL2 = interp1(LconePart2(:,2),LconePart2(:,1),valRangePart2); %l cone
xM2 = interp1(MconePart2(:,2),MconePart2(:,1),valRangePart2); %m cone
xS2 = interp1(SconePart2(:,2),SconePart2(:,1),valRangePart2); %s cone

%calculate LPrime WLs for the given sensitivity range using the 
%interpolated L and M sensitivities.
%part 1
lPrimePart1(:,1) = xM1 + ((xL1-xM1)*(LPrimePeak/(stockmanLpeak-stockmanMpeak)));
%part2
lPrimePart2(:,1) = xM2 + ((xL2-xM2)*(LPrimePeak/(stockmanLpeak-stockmanMpeak)));

%combine part 1 and part 2.  First need to to flip the values for the
%second part (see note above), so that the WL values will increase across full
%range
fullValRange=cat(1,valRangePart1,valRangePart2);

%concatenate into full curve - N.B. these LMS curves aren't really used, but
%may as well be recreated while Lprime is created
allLconeCF=cat(1,xL1,xL2);
allMconeCF=cat(1,xM1,xM2);
allSconeCF=cat(1,xS1,xS2);
allLprimeconeCF=cat(1,lPrimePart1,lPrimePart2); %this is the useful one

cones.allLconeCFWLs=cat(2,allLconeCF,fullValRange);
cones.allMconeCFWLs=cat(2,allMconeCF,fullValRange);
cones.allSconeCFWLs=cat(2,allSconeCF,fullValRange);
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
finalLcone1nmResample=interp1(WL,Lcone,WLrange); %l cone
finalMcone1nmResample=interp1(WL,Mcone,WLrange); %m cone
finalScone1nmResample=interp1(WL,Scone,WLrange); %s cone

% %or could use the recreated curve, but best to only have one 'new' curve,
% i.e. the Lprime
% finalLcone1nmResample=interp1(cones.allLconeCFWLs(:,1),cones.allLconeCFWLs(:,2),WLrange); %l cone
% finalMcone1nmResample=interp1(cones.allMconeCFWLs(:,1),cones.allMconeCFWLs(:,2),WLrange); %m cone
% finalScone1nmResample=interp1(cones.allSconeCFWLs(:,1),cones.allSconeCFWLs(:,2),WLrange); %s cone

%Lprime
finalLprimecone1nmResample=interp1(cones.allLprimeconeCFWLs(:,1),cones.allLprimeconeCFWLs(:,2),WLrange);

%save out spectra with wavelengths (WL,L,L',M,S)
Spectra=cat(2,WLrange,finalLcone1nmResample,finalLprimecone1nmResample,finalMcone1nmResample,finalScone1nmResample);

