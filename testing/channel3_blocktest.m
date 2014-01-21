
clear all
close all;
daqreset

s = daq.createSession('ni');
ch=s.addAnalogOutputChannel('cDAQ1Mod2',0:2, 'Voltage');


ch
s


%data = (sin(linspace(0,2*pi*50,100000)+pi/3)*2)'+3; %last number = brightness/amplitude




conepeaks=[564 534 420]; %N.B. 3 example cone peaks L M S
% Compute nomograms
wavelengths=[400:1:700];
 
T=BaylorNomogram(wavelengths(:),conepeaks(:));
T=T';

LED_Peaks=[410 500 630]; % in nm,
LED_FWHM=[24.52 33.31 16.21] % = 2.3548 sigma
LED_SIGMA=LED_FWHM/2.3548;


%produce the spectrum for each LED
for thisLED=1:length(LED_Peaks);
    LEDSpectrum(:,thisLED)=exp((-(wavelengths(:)-LED_Peaks(thisLED)).^2)/(2*LED_SIGMA(thisLED))^2);
end


%To determine the settings of each LED for maximum absorption of each
%cone, we first calculate the LED2CONE value using the LEDspectrum and
%nomograms, and then we invert this so that we can input the cone
%excitations that we want and be given the appropriate LED values to achieve that.
LED2CONE=LEDSpectrum'*T;

% % The inverse of this gives you the CONE2LED matrix
CONE2LED=pinv(LED2CONE)

% Now we will make stimuli that excites particular cones



%%%%%%%%%% will changing the s.Rate adjust the flicker hz? can we set the
%%%%%%%%%% range of s.Rate values e.g 1:5:50 and loop through all of these
%%%%%%%%%% for each cone excitation condition? e.g. put full cycle in a
%%%%%%%%%% loop, "for s.Rate(:) ....s.queueoutputdata(datas).... end"

freq=200; 

%%% S cone excitation
nSeconds = 5; 
nPoints=s.Rate*nSeconds;
coneContrast=zeros(nPoints,3); % 3 example cones

SconeContrast=[0 0 1]; % L M S

coneContrastMagnitude=10; % Percent
tempMod=sin(linspace(0,2*pi*freq,nPoints));
coneContrast=tempMod'*SconeContrast;

%calculate the LED contrasts for the specific cone excitations specified in the
%coneContrast 
LEDContrast=coneContrast*CONE2LED;

% Turn these modulations (contrasts) into real LED outputs
baseValue=4.5; 
maxValue=4.9;
LEDOutputs=baseValue+(maxValue-baseValue)*LEDContrast*coneContrastMagnitude;
max(LEDOutputs)
min(LEDOutputs)
data=LEDOutputs;
data(end,:)=5.5;  %%turns off the LED at the end







%%% M cone excitation
clear coneContrast;
clear LEDContrast;

nSeconds = 5; 
nPoints=s.Rate*nSeconds;
coneContrast=zeros(nPoints,3); % 3 cones

MconeContrast=[0 1 0];

coneContrastMagnitude=10; % Percent
tempMod=sin(linspace(0,2*pi*freq,nPoints));
coneContrast=tempMod'*MconeContrast;

%calculate the LED contrasts for the specific cone excitations specified in the
%coneContrast 
LEDContrast=coneContrast*CONE2LED;

% Turn these modulations (contrasts) into real LED outputs
baseValue=4.5; 
maxValue=4.9;
LEDOutputs2=baseValue+(maxValue-baseValue)*LEDContrast*coneContrastMagnitude;
max(LEDOutputs2)
min(LEDOutputs2)
data2=LEDOutputs2;
data2(end,:)=5.5;  %%turns off the LED at the end






    
%%% L cone excitation
clear coneContrast;
clear LEDContrast;

nSeconds = 5; 
nPoints=s.Rate*nSeconds;
coneContrast=zeros(nPoints,3); % 3 cones

LconeContrast=[1 0 0]; 

coneContrastMagnitude=10; % Percent
tempMod=sin(linspace(0,2*pi*freq,nPoints));
coneContrast=tempMod'*LconeContrast;

%calculate the LED contrasts for the specific cone excitations specified in the
%coneContrast 
LEDContrast=coneContrast*CONE2LED;

% Turn these modulations (contrasts) into real LED outputs
baseValue=4.5; 
maxValue=4.9;
LEDOutputs3=baseValue+(maxValue-baseValue)*LEDContrast*coneContrastMagnitude;
max(LEDOutputs3)
min(LEDOutputs3)
data3=LEDOutputs3;
data3(end,:)=5.5;  %%turns off the LED at the end







%%%pause between datasets
clear coneContrast;
clear LEDContrast;

nSeconds = 2; 
nPoints=s.Rate*nSeconds;
coneContrast=zeros(nPoints,3); % 3 cones

pauseconeContrast=[0 0 0]; 

coneContrastMagnitude=10; % Percent
tempMod=sin(linspace(0,2*pi*freq,nPoints));
coneContrast=tempMod'*pauseconeContrast;

%calculate the LED contrasts for the specific cone excitations specified in the
%coneContrast 
LEDContrast=coneContrast*CONE2LED;

% Turn these modulations (contrasts) into real LED outputs
baseValue=5.5; 
maxValue=5.5;
LEDOutputs4=baseValue+(maxValue-baseValue)*LEDContrast*coneContrastMagnitude;
max(LEDOutputs4)
min(LEDOutputs4)
pause=LEDOutputs4;
pause(end,:)=5.5;  %%turns off the LED at the end




%string data conditions
datas=cat(1,data,pause,data2,pause,data3); 

% %%plot figures
% estConeCont=LEDContrast*LED2CONE;
% figure(1);
% plot(estConeCont-coneContrast);
% title('Estimated error');
% 
% figure(2);
% imagesc(LEDContrast);
% title('LED Contrast');
% 
% figure(3);
% plot(data);
% title('Data');


s.queueOutputData(datas);
s.startForeground();

close all;
s.release();

daqreset;