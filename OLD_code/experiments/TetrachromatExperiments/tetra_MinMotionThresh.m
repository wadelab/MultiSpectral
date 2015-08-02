function tetra_MinMotionThresh(ExptID,StimCode,SubjectID,SessionNum)
% tetra_MinMotionThresh(ExptID,StimCode,SubjectID,SessionNum)
%
% A minimum motion detection task, which allows the subject to alter either the 
% ratio of L & M (StimCode = M) or L & Mprime (StimCode = MP). Use Z and M
% to adjust to ratio, and Y to end the task. 

clearvars -except ExptID StimCode SubjectID SessionNum %clear all existing variables except for the Session Details created with the GUI

% Load in a set of real calibration data obtained from our Prizmatix box
spectraAll=load('visibleLED_180713.mat');

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
%disp(session.analogue.session);
session.analogue.session.IsContinuous = false;

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
expt.stim.chrom.stimLMS.scale=0.09; % these are the contrasts that correspond to the the above directions
expt.stim.temporal.freq=12; % frequency of flicker (Hz)
expt.stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.
expt.stim.temporal.duration=expt.blockDurSecs; % s 

%The stimulus used is dependent on the StimCode entered (M or MP)
if StimCode=='MP'; % L and M'
    expt.stim.chrom.stimLMS.dir=[cos(expt.stim.chrom.stimLMS.theta) sin(expt.stim.chrom.stimLMS.theta) 0 0]; % L and M' direction
elseif StimCode=='M'; %L and M
    expt.stim.chrom.stimLMS.dir=[cos(expt.stim.chrom.stimLMS.theta) 0 sin(expt.stim.chrom.stimLMS.theta) 0]; % L and M direction
else error('Please use valid StimCode: M or MP (M prime)')
end

session.analogue.session.Rate=20000;

%*******************************************************************%
%
% This loop generates and loads the first stimulus, and then waits for a keypress to either 
% increase (M) or decrease (Z) theta (which adjusts the LM ratio). It then rapidly
% generates the altered stimuli and reloads.  Once the final adjustment has
% been made, press Y to end the session


%***if testing with L M' M S, can't use Stockman***
% stock=load('stockmanData.mat');
% dpy.coneSpectra=stock.stockmanData';

coneSensors.wavelengths=400:2:700;
coneSensors.conepeaks=[570 555 542 442];
%disp('Assuming normal trichromat sensors - computing using Baylor nomogram');

%conepeaks=[564 534 437]; %% these are the cone peaks used in SL study
disp('using Baylor nomogram, for L Mprime M S')
dpy.coneSpectra=BaylorNomogram(coneSensors.wavelengths(:),coneSensors.conepeaks(:));
sensors=dpy.coneSpectra; % nWaves x mSensors

%% Theta can vary in steps of 0.05 radians
thetaStepSize=0.05;
thetaStart=0;
allThetaVals=thetaStart:thetaStepSize:2*pi;


% Now compute the max scale for each of these thetas - this max scale will
% then be used for each of the theta values
thisMaxContIndex=1;
for thisTheta=allThetaVals
    %Use the Stimulus direction specified in stimulus Code of GUI
    if StimCode=='MP';
        stimLMS.dir=[cos(thisTheta) sin(thisTheta) 0 0]; % L and M' direction.  update direction using new theta values
    elseif StimCode=='M';
        stimLMS.dir=[cos(thisTheta) 0 sin(thisTheta) 0]; % L and M direction.  update direction using new theta values
    end
    
    stimLMS.scale=0.04;
    expt.stim.chrom.stimLMS=stimLMS;
    [stimLMS stimRGB] = pry_findMaxSensorScale(dpy,stimLMS,dpy.backRGB,sensors);

    %disp(stimLMS.maxScale);
    maxCont(thisMaxContIndex)=stimLMS.maxScale;
    thisMaxContIndex=thisMaxContIndex+1;
end

%%
disp('*****Loading session*****')
ListenChar(0);  %clears previously captured characters so that 'GetChar' doesn't output these queued keypresses
keypressed=0;
led_tetra_doScan(session,dpy,expt,sensors); %load first stimulus and keep running until key pressed
disp('Session loaded')
if StimCode=='MP'; % L and M'
    disp('Using L and Mprime Stimulus')
elseif StimCode=='M'; %L and M
    disp('Using L and M Stimulus')
end
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
    
    %Update the direction using new theta values - direction used depends
    %on the StimCode of the experiment, i.e. L and M' or L and M.
    if StimCode=='MP';
        expt.stim.chrom.stimLMS.dir=[cos(expt.stim.chrom.stimLMS.theta) sin(expt.stim.chrom.stimLMS.theta) 0 0]; %update direction using new theta values
    elseif StimCode=='M';
        expt.stim.chrom.stimLMS.dir=[cos(expt.stim.chrom.stimLMS.theta) 0 sin(expt.stim.chrom.stimLMS.theta) 0]; %update direction using new theta values
    end
    
    led_tetra_doScan(session,dpy,expt,coneSensors);   %load new stim and run
    [trialChrom]=expt.stim.chrom.stimLMS.dir; %output the chrom direction of the trial
    [trialScale]=expt.stim.chrom.stimLMS.scale;
    disp(['               Stim Direction: ', num2str(trialChrom)])
end
finalSetting.(StimCode).dir=trialChrom
finalSetting.(StimCode).scale=trialScale
disp ('End of Session')


%*********************************************************************%
 
filename=['TetraExpt',num2str(ExptID), '_StimCode_', (StimCode), '_ID', num2str(SubjectID),'_Session', num2str(SessionNum)];  %outputs filename as e.g. 'TetraExpt1_StimCode_M_ID1_Session1'
FinalSettingFilename=['TetraExpt',num2str(ExptID),'_ID', num2str(SubjectID),'_Session', num2str(SessionNum),'_FinalSetting_',(StimCode)]; %outputs filename as e.g. 'TetraExpt1_ID1_Session1_FinalSetting_M'
% 
% %Save data in current folder

save((filename)) % save out full session
%save((FinalSettingFilename),finalSetting) %this doesn't work....
% 
ListenChar(0); %turn off suppression of keyboard output
closedSession=pry_closeSession(session);



