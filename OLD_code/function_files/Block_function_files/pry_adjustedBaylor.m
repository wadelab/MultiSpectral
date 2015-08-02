function spectraData=pry_adjustedBaylor(wavelengths,conePeaks)
% spectraData=pry_adjustedBaylor(wavelengths,conePeaks)
% This function creates an adjusted baylor nomogram that accounts for
% macular pigment and lens transmittance.
%
% wavelengths = range of wavelengths, e.g. [400:2:700]
% conePeaks = the cone peaks to be used, e.g. [570 542 442]
%
% This uses the macular transmittance and lens transmittance functions from
% psychtoolbox
%
% written by LW and AW 12 Aug 2013

% Load in the stockmanData for comparison - the cone peaks from this data are
% 570 542 442 (determined using 'stockman_wavelengthPeaks.m' code)
stock=load('stockmanData.mat');
stockman=stock.stockmanData;

%set wavelengths and cone peaks for running the baylor nomogram
wavelengths=wavelengths';
conePeaks=conePeaks';


%% Use MacularTransmittance to get MP values for our wavelength range
[macTransmit]=MacularTransmittance(wavelengths);
macTransmit=macTransmit';

% figure(1) 
% plot(wavelengths,macTransmit) 
% title('MP Transmittance')


%% Use LensTransmittance to get lens Densities for our wavelength range
[lensTransmit] = LensTransmittance(wavelengths);
lensTransmit=lensTransmit';

% figure(2)
% plot(wavelengths,lensTransmit)
% title('Lens transmittance')


%% Create original Baylor Nomogram
Baylor=BaylorNomogram(wavelengths,conePeaks);

% % Plot original Baylor
% figure(3)
% plot(wavelengths,Baylor)
% title('Original Baylor Nomogram')

% % Plot original Baylor and stockman
% figure(6)
% Combined=[Baylor;stockman];
% plot(wavelengths,Combined)
% title('Combined stockman fundamentals and original Baylor Nomogram')
% ylim([0 1]);


%% Create Adjusted Baylor
Baylor=Baylor';
adjustedBaylor=zeros(length(wavelengths),length(conePeaks)); %create blank matrix
for c=1:size(conePeaks);
    adjustedBaylor(:,c)=Baylor(:,c).*macTransmit(:,1).*lensTransmit(:);  %original baylor values minus MP (MP=transmittance*density)
adjustedBaylor(:,c)=adjustedBaylor(:,c)/max(adjustedBaylor(:,c));
end %next cone peak

spectraData=adjustedBaylor;

% % Plot Adjusted Baylor
% figure(4)
% plot(wavelengths,adjustedBaylor)
% title('Adjusted Baylor Nomogram:  Baylor-MP')

% % Plot adjusted Baylor and stockman
% figure(5)
% CombinedAdjust=[spectraData';stockman];
% plot(wavelengths,CombinedAdjust)
% title('Combined stockman fundamentals and Adjusted Baylor Nomogram')
% ylim([0 1]);

return
