function Spectra=creatingLprime(dpy)
% Spectra=creatingLprime(LprimePos)
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
    error('Cannot use values outside 0 and 1 with this script.  Must use specific cone peak values. See ...')
end

%desired WL range
WLrange=dpy.WLrange; %N.B. for now must be 400 and 720, else interp won't work - would need to edit part 1 and 2 values too if this changes
%can comment this bit out on lab mac
%addpath(genpath(' ')) enter path containing the stockman01nmCF

%load in the 0.1nm stockmanCFs
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

%calculate L and M cone peaks by averaging the WL values that equal 1
l=1;
for thisWL=1:length(LconeWL)
    if LconeWL(thisWL,2)==1
        lconePeakVals(l,1)=LconeWL(thisWL,1);
        l=l+1;
    else continue
    end
end
stockmanLpeak=mean(lconePeakVals); %l cone peak

m=1;
for thisWL=1:length(MconeWL)
    if MconeWL(thisWL,2)==1.0000
        mconePeakVals(m,1)=MconeWL(thisWL,1);
        m=m+1;
    else continue
    end
end
stockmanMpeak=mean(mconePeakVals); %m cone peak

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
%At the moment the relevant rows are worked out manually - TODO, make it
%automatic!
LconePart1=Lcone1nmWL(1:170,:); %l cone prev 170
LconePart2=Lcone1nmWL(172:end,:); % prev 172
MconePart1=Mcone1nmWL(1:143,:); %m cone prev143
MconePart2=Mcone1nmWL(144:end,:); %prev144
SconePart1=Scone1nmWL(1:43,:); %s cone prev43
SconePart2=Scone1nmWL(44:114,:); %prev44 to114

% %use this to check that values are monotonically increasing, highlight where the error is if not
% for thisRow=1:length(LconePart1)-1
%     if LconePart1(thisRow,2)>=LconePart1(thisRow+1,2)
%         fprintf('Row %d greater than row %d\n',thisRow,thisRow+1)
%     else
%         continue
%     end
% end
%specify sensitivity range and desired Lprime peak
valRange=(0.01:0.005:1)';
LPrimePeak=round((stockmanLpeak-stockmanMpeak)*locationLprime); %round so integer

% Interpolate Part 1 of the curves to given sensitivities
xL1 = interp1(LconePart1(:,2),LconePart1(:,1),valRange); %l cone
xM1 = interp1(MconePart1(:,2),MconePart1(:,1),valRange); %m cone
xS1 = interp1(SconePart1(:,2),SconePart1(:,1),valRange); %s cone
% Interpolate Part 2 of the curves to given sensitivities
xL2 = interp1(LconePart2(:,2),LconePart2(:,1),valRange); %l cone
xM2 = interp1(MconePart2(:,2),MconePart2(:,1),valRange); %m cone
xS2 = interp1(SconePart2(:,2),SconePart2(:,1),valRange); %s cone

%calculate LPrime WLs for the given sensitivity range using the 
%interpolated L and M sensitivities.
%part 1
lPrimePart1(:,1) = xM1 + (xL1-xM1)*(LPrimePeak/(stockmanLpeak-stockmanMpeak));
%part2
lPrimePart2(:,1) = xM2 + (xL2-xM2)*(LPrimePeak/(stockmanLpeak-stockmanMpeak));

%combine part 1 and part 2.  First need to to flip the values for the
%second part, so that the WL values will increase across full
%range
fullValRange=cat(1,valRange,flipud(valRange));

allLconeCF=cat(1,xL1,flipud(xL2));
allMconeCF=cat(1,xM1,flipud(xM2));
allSconeCF=cat(1,xS1,flipud(xS2));

allLprimeconeCF=cat(1,lPrimePart1,flipud(lPrimePart2));
cones.allLconeCFWLs=cat(2,allLconeCF,fullValRange);
cones.allMconeCFWLs=cat(2,allMconeCF,fullValRange);
cones.allSconeCFWLs=cat(2,allSconeCF,fullValRange);
cones.allLprimeconeCFWLs=cat(2,allLprimeconeCF,fullValRange);

%labels for cone variables - these much match those above! excluding the
%'cone.' part of the name
conevariables={'allLconeCFWLs','allMconeCFWLs','allSconeCFWLs','allLprimeconeCFWLs'};
%remove any NaN rows from vals for each cone
for thisConeVar=1:size(conevariables,2)
    currentCone=sprintf('%s',conevariables{thisConeVar});
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
finalLcone1nmResample=interp1(cones.allLconeCFWLs(:,1),cones.allLconeCFWLs(:,2),WLrange); %l cone
finalMcone1nmResample=interp1(cones.allMconeCFWLs(:,1),cones.allMconeCFWLs(:,2),WLrange); %m cone
finalScone1nmResample=interp1(cones.allSconeCFWLs(:,1),cones.allSconeCFWLs(:,2),WLrange); %s cone

% finalLcone1nmResample=Lcone; %l cone
% finalMcone1nmResample=Mcone; %m cone
% finalScone1nmResample=Scone; %s cone

finalLprimecone1nmResample=interp1(cones.allLprimeconeCFWLs(:,1),cones.allLprimeconeCFWLs(:,2),WLrange); %s cone

%save out spectra with wavelengths (WL,L,L',M,S)
Spectra=cat(2,WLrange,finalLcone1nmResample,finalLprimecone1nmResample,finalMcone1nmResample,finalScone1nmResample);

% 
% %plot figure
% figure()
% plot(Spectra(:,1),Spectra(:,2:end))
