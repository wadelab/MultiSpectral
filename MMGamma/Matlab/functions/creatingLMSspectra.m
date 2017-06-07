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

% do not use this for now, until we know which cone peaks work best
% % stockmansharpe nomogram L M and S peaks of 558.9 530.3 and 420.7
% % respectively
% Lcone=StockmanSharpeNomogram(WLrange,558.9);
% Mcone=StockmanSharpeNomogram(WLrange,530.3);
% Scone=StockmanSharpeNomogram(WLrange,420.7);
% 
% %transpose (don't actually need to resample as correct sampling already
% %used in nomogram)
% LconeResample=Lcone'; %l cone
% MconeResample=Mcone'; %m cone
% SconeResample=Scone'; %s cone

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
        if isfield(dpy,'LprimePosition')==1
            tempSpectra=creatingLprime(dpy);            
            Lprime=tempSpectra(:,3); %column 3 because 1 is WL and 2 is L
            Spectra=cat(2,WLrange,LconeResample,Lprime,SconeResample);
        elseif isfield(dpy,'Mpeak')==1
            dpy.LMpeak=dpy.Mpeak;
            [tempSpectra,~]=creating2coneSpectra(dpy);
            Lprime=tempSpectra(:,2); %in second column after wl vals
            Spectra=cat(2,WLrange,LconeResample,Lprime,SconeResample);            
        end
            
    case {'LpMS'}
        %we want normal M and S spectra, and the Lprime
        %calculate the full 4cone spectra and extract the Lp value from 
        %L Lp M S range
        if isfield(dpy,'LprimePosition')==1
            tempSpectra=creatingLprime(dpy);            
            Lprime=tempSpectra(:,3); %column 3 because 1 is WL and 2 is L
            Spectra=cat(2,WLrange,Lprime,MconeResample,SconeResample);
        elseif isfield(dpy,'Lpeak')==1
            dpy.LMpeak=dpy.Lpeak;
            [tempSpectra,~]=creating2coneSpectra(dpy);
            Lprime=tempSpectra(:,2); %in second column after wl vals
            Spectra=cat(2,WLrange,Lprime,MconeResample,SconeResample);            
        end
end

end
