% type RunExp into command window to open GUI 

clearvars -except ExptID SubjectID SessionNum %clear all existing variables except for the Session Details created with the GUI

% Load in a set of real calibration data obtained from our Prysmatix box
spectraAll=load('visibleLED.mat');

% figure(1);
% h=plot(400:2:700,spectraAll.linterp(:,[1 3 4 5]));
% this just colors the lines correctly in the plot
% set(h(1),'Color',[0 0 1]);
% set(h(2),'Color',[0 1 0]);
% set(h(3),'Color',[1 0 0]);
% set(h(4),'Color',[1 1 0]);

% Open up the DAQ device and return a session object. This can take quite a
% a while (10s)
session=pry_openSession(0:3,0,1);
disp(session.analogue.session);

%% Cell
% Set the output rate to 20KHz. This determines the precision of the PWM
session.analogue.session.Rate=20000;


dpy.maxValue=5; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
dpy.spectra=spectraAll.linterp(:,[1 3 4 5]); %these are the LEDs we are using (i.e. excluding number 2 (465nm))
dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
dpy.backRGB.dir=[1 1 1 1]*1; %  this is the scale applied to the background LEDs. I >think< that 1111 means they all have the same voltage out on them at the midpoint. 
dpy.backRGB.scale=0.5; % This sets the background intensity. Smaller values = darker backgrounds.



%Set the parameters of the trials
expt.blockDurSecs=10; %Duration of stimulus presentation, secs
expt.stim.chrom.stimLMS.theta=pi/2;  %this determines the starting direction of the stimulus
expt.stim.chrom.stimLMS.dir=[cos(expt.stim.chrom.stimLMS.theta) sin(expt.stim.chrom.stimLMS.theta) 0]; %This defines all the colour directions that we want to test
expt.stim.chrom.stimLMS.scale=0.09; % these are the contrasts that correspond to the the above directions
expt.stim.temporal.freq=12; % frequency of flicker (Hz)
expt.stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.
expt.stim.temporal.duration=expt.blockDurSecs; % s 

%scan.trials=expt;
session.analogue.session.Rate=20000;

%*******************************************************************%
%
% This loop generates and loads the first stimulus, and then waits for a keypress to either 
% increase (M) or decrease (Z) theta (which adjusts the LM ratio). It then rapidly
% generates the altered stimuli and reloads.  Once the final adjustment has
% been made, press Y to end the session

% TODO - if the contrast value exceeds what can be used for a given LM ratio, the program is 
% terminated with the following error: "Requested contrast ( 0.040) exceeds
% maximum (0.038)". Need to create a rule so that when the max ratios for a
% given contrast are reached, the stimulus doesn't change any further and
% can only be adjusted in the opposite direction - this will avoid the
% session ending on an error. 

%***while testing with L M' M S, can't use Stockman***
stock=load('stockmanData.mat');
dpy.coneSpectra=stock.stockmanData';

wavelengths=400:2:700;
%disp('Assuming normal trichromat sensors - computing using Baylor nomogram');

%conepeaks=[564 534 437]; %% additional cone peaks can be added here e.g. for additional cones/melanopsin
% disp('using Baylor nomogram, for L Mprime M S')
% dpy.coneSpectra=BaylorNomogram(wavelengths(:),conepeaks(:));
sensors=dpy.coneSpectra; % nWaves x mSensors

%% Theta can vary in steps of 0.05 radians
thetaStepSize=0.05;
thetaStart=0;
allThetaVals=thetaStart:thetaStepSize:2*pi;

% Now compute the max scale for each of these thetas
thisMaxContIndex=1;
for thisTheta=allThetaVals
     stimLMS.dir=[cos(thisTheta) sin(thisTheta) 0];  %update direction using new theta values
     stimLMS.scale=0.04;
    expt.stim.chrom.stimLMS=stimLMS;
    [stimLMS stimRGB] = pry_findMaxSensorScale(dpy,stimLMS,dpy.backRGB,sensors,expt);

    disp(stimLMS.maxScale);
    maxCont(thisMaxContIndex)=stimLMS.maxScale;
    thisMaxContIndex=thisMaxContIndex+1;
end

%%
disp('*****Loading session*****')
ListenChar(0);  %clears previously captured characters so that 'GetChar' doesn't output these queued keypresses
keypressed=0;
led_tetra_doScan(session,dpy,expt,sensors); %load first stimulus and keep running until key pressed
disp('Session loaded')
thetaIndex=1;
      expt.stim.chrom.stimLMS.theta=allThetaVals(thetaIndex);
        expt.stim.chrom.stimLMS.scale=maxCont(thetaIndex);
while(keypressed~='y') %Press y when happy with final adjustment
    disp('Awaiting input...')
    ListenChar(2)  %enables listening (for GetChar) and also suppresses keyboard output to the Matlab command window
    [keypressed,w]=GetChar;
    keypressed;
    if keypressed=='z'; %z
        disp('               Z pressed - decrease theta')
        thetaIndex=thetaIndex-1;
        if(thetaIndex<1)
            thetaIndex=length(allThetaVals);
        end
        expt.stim.chrom.stimLMS.theta=allThetaVals(thetaIndex);
        expt.stim.chrom.stimLMS.scale=maxCont(thetaIndex);
                

    elseif keypressed=='m'; %m
        disp('               M pressed - increase theta')
       thetaIndex=thetaIndex+1;

     if(thetaIndex>length(allThetaVals)) 
         thetaIndex=1;
     end   
        expt.stim.chrom.stimLMS.theta=allThetaVals(thetaIndex);
        expt.stim.chrom.stimLMS.scale=maxCont(thetaIndex);
                
    elseif keypressed=='y';
        disp('               Y pressed. Satisfied with final adjustment.')
    end
    expt.stim.chrom.stimLMS.dir=[cos(expt.stim.chrom.stimLMS.theta) sin(expt.stim.chrom.stimLMS.theta) 0];  %update direction using new theta values
    led_tetra_doScan(session,dpy,expt);   %load new stim and run
    [trialChrom]=expt.stim.chrom.stimLMS.dir; %output the chrom direction of the trial
    disp(['               Stim Direction: ', num2str(trialChrom)])
end

disp ('End of Session')
ListenChar(0); %turn off suppression of keyboard output
closedSession=pry_closeSession(session);

%*********************************************************************%

% TODO - create GUI to allow input of experiment number, session number, and participant number 
 
% filename=['TetraExpt',num2str(ExptID), '_ID', num2str(SubjectID),'_Session', num2str(SessionNum)];  %outputs filename as e.g. 'LEDExpt1_ID1_Scan1'
% 
% %Save data in current folder
% 
% save((filename))
% 
% closedSession=pry_closeSession(session);



