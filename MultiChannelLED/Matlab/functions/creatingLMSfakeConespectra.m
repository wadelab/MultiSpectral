function Spectra=creatingLMSfakeConespectra(WLrange)
% Spectra=creatingLMSspectra(WLrange)
%
% WLrange = the range of wavelengths to output e.g. 400:1:720
% 
% Import stockman CFs and output single matrix of desired wavelengths and
% LMS spectra
%
% written by LW 190815

%desired WL range
WL1nm=WLrange; 

%load in the 0.1nm stockmanCFs
load('stockman01nmCF.mat');
%assign cones and WLs to variables
Lcone=stockman.Lcone;
Mcone=stockman.Mcone;
Scone=stockman.Scone;
WL=stockman.wavelength;

%resample to desired WLrange
Lcone1nmResample=interp1(WL,Lcone,WL1nm); %l cone
Mcone1nmResample=interp1(WL,Mcone,WL1nm); %m cone
Scone1nmResample=interp1(WL,Scone,WL1nm); %s cone

MScone=Mcone1nmResample(40:end,1);
MScone(end+1:end+39,1)=0;
%save out spectra with wavelengths (WL,L,M,S)
Spectra=cat(2,WL1nm,Lcone1nmResample,Mcone1nmResample,MScone,Scone1nmResample);
% 
% %plot figure
figure()
plot(Spectra(:,1),Spectra(:,2:end))
