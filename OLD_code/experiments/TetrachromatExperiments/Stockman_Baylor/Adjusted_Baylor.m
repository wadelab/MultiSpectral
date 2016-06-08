function spectraData=pry_adjustedBaylor(wavelengths,conePeaks)
% spectraData=pry_adjustedBaylor(wavelengths,conePeaks)
% This function created an adjusted baylor nomogram that accounts for
% macular pigment and lens transmittance
%
% this uses the macular transmittance and lens transmittance functions from
% psychtoolbox
%
% written by LW and AW 12 Aug 2013


close all;
% Load in the stockmanData for comparison - the cone peaks from this data are
% 570 542 442 (determined using 'stockman_wavelengthPeaks.m' code)
stock=load('stockmanData.mat');
stockman=stock.stockmanData;

%set wavelengths and cone peaks for running the baylor nomogram
wavelengths=400:2:700;
wavelengths=wavelengths';
%conePeaks=[570 542 442];
conePeaks=[559 545 531 419];
conePeaks=conePeaks';


%% Use MacularTransmittance to get MP values for our wavelength range
[macTransmit, MacDensity]=MacularTransmittance(wavelengths);
macTransmit=macTransmit';
for i=1:size(wavelengths)
   MP(i,1)=(macTransmit(i,1)*MacDensity(i,1));
end

figure(1)
plot(wavelengths,MP)
title('MP')


% MP Density 
for m=1:size(wavelengths)
   Density(m,1)=MacDensity(m,1);
end

% MP transmit
for m=1:size(wavelengths)
   Transmit(m,1)=macTransmit(m,1);
end

% MP 
for m=1:size(wavelengths)
   MP(m,1)=Transmit(m,1)*Density(m,1);
end

%% Not sure if we need this too...?
%Use LensTransmittance to get lens Densities for our wavelength range
[lensTransmit,lensDensity] = LensTransmittance(wavelengths);
lensTransmit=lensTransmit';

figure(2)
plot(wavelengths,lensTransmit)
title('lens')





%% Create original Baylor Nomogram
Baylor=BaylorNomogram(wavelengths,conePeaks);

% Plot original Baylor
figure(3)
plot(wavelengths,Baylor)
title('Original Baylor Nomogram')

% Plot original Baylor and stockman
figure(6)
Combined=[Baylor;stockman];
plot(wavelengths,Combined)
title('Combined stockman fundamentals and original Baylor Nomogram')
ylim([0 1]);



%% Create Adjusted Baylor
Baylor=Baylor';
adjustedBaylor=zeros(length(wavelengths),length(conePeaks)); %create blank matrix
for c=1:size(conePeaks);
    adjustedBaylor(:,c)=Baylor(:,c).*Transmit(:,1).*lensTransmit(:);  %original baylor values minus MP (MP=transmittance*density)
adjustedBaylor(:,c)=adjustedBaylor(:,c)/max(adjustedBaylor(:,c));
end %next cone peak

% Plot Adjusted Baylor
figure(4)
plot(wavelengths,adjustedBaylor)
title('Adjusted Baylor Nomogram:  Baylor-MP')

% Plot adjusted Baylor and stockman
figure(5)
adjustedBaylor=adjustedBaylor';
CombinedAdjust=[adjustedBaylor;stockman];
plot(wavelengths,CombinedAdjust)
title('Combined stockman fundamentals and Adjusted Baylor Nomogram')
ylim([0 1]);











