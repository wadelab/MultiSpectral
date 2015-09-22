function Spectra=creatingLMSspectra(dpy)
% Spectra=creatingLMSspectra(dpy)
% dpy containing:
% WLrange = the range of wavelengths to output e.g. 400:1:720
% ConeTypes = specify the cone types needed, e.g. LMS, LLpS, or LpMS
% 
% Import stockman CFs and output single matrix of desired wavelengths and
% cone spectra
%
% written by LW 190815

%desired WL range
WLrange=dpy.WLrange; 

%load in the 0.1nm stockmanCFs
load('stockman01nmCF.mat');
%assign cones and WLs to variables
Lcone=stockman.Lcone;
Mcone=stockman.Mcone;
Scone=stockman.Scone;
WL=stockman.wavelength;

%resample to desired WLrange
LconeResample=interp1(WL,Lcone,WLrange); %l cone
MconeResample=interp1(WL,Mcone,WLrange); %m cone
SconeResample=interp1(WL,Scone,WLrange); %s cone

switch dpy.ConeTypes
    case {'LMS'}
        %save out spectra with wavelengths (WL,L,M,S)
        Spectra=cat(2,WLrange,LconeResample,MconeResample,SconeResample);
    case {'LLpS'}
        %we want normal L and S spectra, and the Lprime
        %calculate the full 4cone spectra and extract the Lp value from 
        %L Lp M S range
        dpy.LprimePosition=0.5;
        tempSpectra=creatingLprime(dpy);
        Lprime=tempSpectra(:,3); %column 3 because 1 is WL and 2 is L
        Spectra=cat(2,WLrange,LconeResample,Lprime,SconeResample);
    case {'LpMS'}
        %we want normal M and S spectra, and the Lprime
        %calculate the full 4cone spectra and extract the Lp value from 
        %L Lp M S range
        dpy.LprimePosition=0.5;
        tempSpectra=creatingLprime(dpy);
        Lprime=tempSpectra(:,3); %column 3 because 1 is WL and 2 is L
        Spectra=cat(2,WLrange,Lprime,MconeResample,SconeResample);
end
end
