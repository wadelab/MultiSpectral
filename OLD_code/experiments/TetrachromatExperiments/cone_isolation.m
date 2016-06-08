function cone_isolation(ExptID,StimCode,SubjectID,SessionNum)
% cone_isolation(ExptID,StimCode,SubjectID,SessionNum)
%
% This function produces cone isolating stimuli for the following:

% StimCode = L    (L cone isolating)
% StimCode = MP   (Mprime cone isolating)
% StimCode = M    (M cone isolating)
% StimCode = MS   (MS cone isolating - a cone between the M and S cone peaks)
% StimCode = S    (S cone isolating)
%
% As the cone peaks used may affect whether or not a particular cone is
% isolated, this function allows the cone peaks to be adjusted until the
% stimuli is minimally flickering. Each cone peak is altered independently,
% it is advised to go through L M and S in turn, adjusting each until the
% flicker is as minised as possible before moving on to the next.  The
% subject can then return to previous cones to re-adjust further if desired.
%
% This function always uses 4 cones. If the StimCode used if L,MP,M or S,
% the cones used are in the following order: L MP M S.  If the StimCode MS
% is used, the cones are: L M MS S.  The code is built to account for this
% when building stimuli, based on the StimCode used.
% 
% Minimum and/or maximum values have been applied to the cone peaks so that
% no cone peak is ever nearer than a specified boundary to the cone that
% is being isolated (e.g. 8nm either side of the isolated cone). The size
% of this boundary can be altered by changing the value of the 'boundary'
% variable.  A beep occurs if the subject tries to alter the cone peak
% beyond this boundary, and the cone peak value does not change (i.e. from
% that point they can only adjust the cone peak in the opposite direction).
%
% The starting values for each cone can be altered by changing the values of
% the Lcone, Mcone, etc variables.
%
% To indicate which cone peak you would like to adjust:  
%
% l = L cone peak
% p = Mprime cone peak
% m = M cone peak
% a = M-S cone peak (a cone between M and S)
% s = S cone peak
%
% The comma and full stop keys (left and right arrows) are used to
% decrease and increase the selected cone peak respectively. By default the 
% cone peak is adjusted by 1nm, but this can be altered by changing the 
% value of the 'adjustNM' variable.  Any cone can be selected at any time 
% to be altered.  Pressing Y ends the adjustment task and outputs the final
% cone peak values.
%
% Written by LW on 14 Aug 2013


clearvars -except ExptID StimCode SubjectID SessionNum %clear all existing variables except for the Session Details created with the GUI

% Load in a set of real calibration data obtained from our Prizmatix box
spectraAll=load('visibleLED_301013.mat');

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
dpy.backRGB.scale=0.1; % This sets the background intensity. Smaller values = darker backgrounds.

%Set the parameters of the trials
expt.blockDurSecs=10; %Duration of stimulus presentation, secs
expt.stim.temporal.freq=2; % frequency of flicker (Hz)
expt.stim.temporal.sampleRate=200; %this is the rate we sample the underlying wave form at. It is not the digitiser frequency.
expt.stim.temporal.duration=expt.blockDurSecs; % s
%The direction and scale of the stimulus are created below based on the StimCode used.
wavelengths=400:2:700; 
TheSensors.conepeaks=[566 541 442];

spectraData=pry_adjustedBaylor(wavelengths,TheSensors.conepeaks);

if strcmp(StimCode,'L'); %L cone isolation
    expt.stim.chrom.stimLMS.dir=[1 0 0]; % M cone isolation, assuming tetrachromat
    expt.stim.chrom.stimLMS.scale=0.06;
 
    disp('Using L cone isolating Stimulus')
elseif strcmp(StimCode,'MP'); % M' cone isolation
    expt.stim.chrom.stimLMS.dir=[1 1 1];
    expt.stim.chrom.stimLMS.scale=0.82;
   
    disp('Using M prime cone isolating Stimulus')
elseif strcmp(StimCode,'M'); %M cone isolation
    expt.stim.chrom.stimLMS.dir=[0 1 0]; % M cone isolation, assuming tetrachromat
    expt.stim.chrom.stimLMS.scale=0.02;
 
    disp('Using M cone isolating Stimulus')

elseif strcmp(StimCode,'S'); %S cone isolation
    expt.stim.chrom.stimLMS.dir=[0 0 1]; % M cone isolation, assuming tetrachromat
    expt.stim.chrom.stimLMS.scale=0.72;

    disp('Using S cone isolating Stimulus')
else error('Please use valid StimCode: L, MP, M, MS, S')
end

%% Generate and load starting stimulus
dpy.coneSpectra=spectraData;
sensors=dpy.coneSpectra';
session.analogue.session.Rate=20000;
disp('*****Loading session*****')
led_tetra_doScan(session,dpy,expt); %load first stimulus and keep running until key pressed
disp('Session loaded')

boundary=8; %sets the boundary width for the isolated cone
adjustNM=1; %sets the size of the adjustment, in nm
% Starting values for each cone
Lcone=570;
Mcone=542;
MPcone=555;
MScone=510;
Scone=442;

ListenChar(0);  %clears previously captured characters so that 'GetChar' doesn't output these queued keypresses
ListenChar(2) %suppress keypresses to the Matlab command window
disp('*******Select first cone to adjust*******')
[keypressed]=GetChar;
if keypressed=='l'
    disp('Starting with L cone peak')
elseif keypressed=='p'
    disp('Starting with M prime cone peak')
elseif keypressed=='m'
    disp('Starting with M cone peak')
elseif keypressed=='a'
    disp('Starting with M-S cone peak')
elseif keypressed=='s'
    disp('Starting with S cone peak')
end

%% Adjustment Loop
%
% This Loop lets the subject select which cone peak they would like to alter by
% by pressing the appropriate key (l, m, s, p(for Mprime) and a(for M-S)).
% The comma and full stop keys (left and right arrows) are then used to
% decrease and increase the selected cone peak respectively. Any cone can be
% selected at any time to be altered.  Pressing Y ends the adjustment task
% and outputs the final cone peak values.

while(keypressed~='y') %Press y when happy with final adjustment
    
    while keypressed=='l'; %L
        [val]=GetChar;
        if val=='.' %right arrow/full stop pressed. Increase the L cone peak
            Lcone=Lcone+adjustNM;
            disp(['L cone peak increased to:   ', num2str(Lcone)])
        elseif val==',' %left arrow/comma pressed. Decrease the L cone peak
            if strcmp(StimCode,'MP')
                if Lcone<=MPcone+boundary %L cone peak min value must be 8nm more than Mprime
                beep;
                warning(['Unable to decrease L cone peak further. L cone peak:  ', num2str(Lcone)])
                elseif Lcone>=MPcone+boundary
                Lcone=Lcone-adjustNM;
                disp(['L cone peak decreased to:   ', num2str(Lcone)])
                end
            elseif ~(strcmp(StimCode,'MP'))
                Lcone=Lcone-adjustNM;
                disp(['L cone peak decreased to:   ', num2str(Lcone)])
            end
        elseif val=='m'
            keypressed='m';
            disp('M cone peak')
        elseif val=='p'
            keypressed='p';
            disp('Mprime cone peak')
        elseif val=='a'
            keypressed='a';
            disp('M-S cone peak')
        elseif val=='s'
            keypressed='s';
            disp('S cone peak')
        elseif val=='y'
            keypressed='y';
        end
        
        TheSensors.conepeaks=[Lcone  Mcone Scone];
      
        
        spectraData=pry_adjustedBaylor(wavelengths,TheSensors.conepeaks);
        dpy.coneSpectra=spectraData;
        sensors=dpy.coneSpectra';
        led_tetra_doScan(session,dpy,expt);   %load new stim and run
    end
    
    
    while keypressed=='m'; %M
        [val]=GetChar;
        if val=='.' %right arrow/full stop pressed. Increase the m cone peak
            if strcmp(StimCode,'MP')
                if Mcone>=MPcone-boundary %M cone peak max value must be 8nm less than Mprime
                beep
                warning(['Unable to increase M cone peak further. M cone peak:  ', num2str(Mcone)])
                elseif Mcone<=MPcone-boundary
                Mcone=Mcone+adjustNM;
                disp(['M cone peak increased to:   ', num2str(Mcone)])
                end
            elseif ~(strcmp(StimCode,'MP'))
                Mcone=Mcone+adjustNM;
                disp(['M cone peak increased to:   ', num2str(Mcone)])
            end
        elseif val==',' %left arrow/comma pressed. Decrease the m cone peak
            if strcmp(StimCode,'MS')
                if Mcone<=MScone+boundary %M cone peak min value must be 8nm more than M-S
                beep
                warning(['Unable to decrease M cone peak further. M cone peak:  ', num2str(Mcone)])
                elseif Mcone>=MScone+boundary
                Mcone=Mcone-adjustNM;
                disp(['M cone peak decreased to:   ', num2str(Mcone)])
                end
            elseif ~(strcmp(StimCode,'MS'))
                Mcone=Mcone-adjustNM;
                disp(['M cone peak decreased to:   ', num2str(Mcone)])                
            end
        elseif val=='l'
            keypressed='l';
            disp('L cone peak')
        elseif val=='p'
            keypressed='p';
            disp('Mprime cone peak')
        elseif val=='a'
            keypressed='a';
            disp('M-S cone peak')
        elseif val=='s'
            keypressed='s';
            disp('S cone peak')
        elseif val=='y'
            keypressed='y';
        end
        
        if strcmp(StimCode,'L'); %L cone isolation
            TheSensors.conepeaks=[Lcone MPcone Mcone Scone];
        elseif strcmp(StimCode,'MP'); % M' cone isolation
            TheSensors.conepeaks=[Lcone MPcone Mcone Scone];
        elseif strcmp(StimCode,'M'); % M cone isolation
            TheSensors.conepeaks=[Lcone MPcone Mcone Scone];
        elseif strcmp(StimCode,'MS'); % MS cone isolation
            TheSensors.conepeaks=[Lcone Mcone MScone Scone];
        elseif strcmp(StimCode,'S'); % S cone isolation
            TheSensors.conepeaks=[Lcone MPcone Mcone Scone];
        end
        
        spectraData=pry_adjustedBaylor(wavelengths,TheSensors.conepeaks);
        dpy.coneSpectra=spectraData;
        sensors=dpy.coneSpectra;
        led_tetra_doScan(session,dpy,expt,sensors);   %load new stim and run
    end
    
    while keypressed=='p'; %Mprime
        [val]=GetChar;
        if val=='.' %right arrow/full stop pressed. Increase the Mprime cone peak
            if MPcone>=Lcone-boundary %Mprime cone peak max value must be 8nm less than Mprime
                beep
                warning(['Unable to increase Mprime cone peak further. Mprime cone peak:  ', num2str(MPcone)])
            elseif MPcone<=Lcone-boundary
                MPcone=MPcone+adjustNM;
                disp(['Mprime cone peak increased to:   ', num2str(MPcone)])
            end
        elseif val==',' %left arrow/comma pressed. Decrease the Mprime cone peak
            if MPcone<=Mcone+boundary %Mprime cone peak min value must be 8nm more than M
                beep
                warning(['Unable to decrease Mprime cone peak further. Mprime cone peak:  ', num2str(MPcone)])
            elseif MPcone>=Mcone+boundary
                MPcone=MPcone-adjustNM;
                disp(['Mprime cone peak decreased to:   ', num2str(MPcone)])
            end
        elseif val=='l'
            keypressed='l';
            disp('L cone peak')
        elseif val=='m'
            keypressed='m';
            disp('M cone peak')
        elseif val=='a'
            keypressed='a';
            disp('M-S cone peak')
        elseif val=='s'
            keypressed='s';
            disp('S cone peak')
        elseif val=='y'
            keypressed='y';
        end
        
           TheSensors.conepeaks=[Lcone  Mcone Scone];
        
        
        
        spectraData=pry_adjustedBaylor(wavelengths,TheSensors.conepeaks);
        dpy.coneSpectra=spectraData;
        sensors=dpy.coneSpectra;
        led_tetra_doScan(session,dpy,expt);   %load new stim and run
    end
    
    while keypressed=='a'; %M-S
        [val]=GetChar;
        if val=='.' %right arrow/full stop pressed. Increase the M-S cone peak
            if MScone>=Mcone-boundary %M-S cone peak max value must be 8nm less than M
                beep
                warning(['Unable to increase M-S cone peak further. M-S cone peak:  ', num2str(MScone)])
            elseif MScone<=Mcone-boundary
                MScone=MScone+adjustNM;
                disp(['M-S cone peak increased to:   ', num2str(MScone)])
            end
        elseif val==',' %left arrow/comma pressed. Decrease the M-S cone peak
            if MScone<=Scone+boundary %L cone peak min value must be 8nm more than Mprime
                beep
                warning(['Unable to decrease M-S cone peak further. M-S cone peak:  ', num2str(MScone)])
            elseif MScone>=Scone+boundary
                MScone=MScone-adjustNM;
                disp(['M-S cone peak decreased to:   ', num2str(MScone)])
            end
        elseif val=='l'
            keypressed='l';
            disp('L cone peak')
        elseif val=='m'
            keypressed='m';
            disp('M cone peak')
        elseif val=='p'
            keypressed='p';
            disp('Mprime cone peak')
        elseif val=='s'
            keypressed='s';
            disp('S cone peak')
        elseif val=='y'
            keypressed='y';
        end
        
   
            TheSensors.conepeaks=[Lcone  Mcone Scone];
      
        
        spectraData=pry_adjustedBaylor(wavelengths,TheSensors.conepeaks);
        dpy.coneSpectra=spectraData;
        sensors=dpy.coneSpectra;
        led_tetra_doScan(session,dpy,expt,sensors);   %load new stim and run
    end
    
    while keypressed=='s'; %S
        [val]=GetChar;
        if val=='.' %right arrow/full stop pressed. Increase the M-S cone peak
            if strcmp(StimCode,'MS')
                if Scone>=MScone-boundary %S cone peak max value must be 8nm less than M-S
                beep
                warning(['Unable to increase S cone peak further. S cone peak:  ', num2str(Scone)])
                elseif Scone<=MScone-boundary
                Scone=Scone+adjustNM;
                disp(['S cone peak increased to:   ', num2str(Scone)])
                end
            elseif ~(strcmp(StimCode,'MS'))
                Scone=Scone+adjustNM;
                disp(['S cone peak increased to:   ', num2str(Scone)])
            end
        elseif val==',' %left arrow/comma pressed. Decrease the L cone peak
            Scone=Scone-adjustNM;
            disp(['S cone peak decreased to:   ', num2str(Scone)])
        elseif val=='l'
            keypressed='l';
            disp('L cone peak')
        elseif val=='m'
            keypressed='m';
            disp('M cone peak')
        elseif val=='p'
            keypressed='p';
            disp('Mprime cone peak')
        elseif val=='a'
            keypressed='a';
            disp('MS cone peak')
        elseif val=='y'
            keypressed='y';
        end
        
            TheSensors.conepeaks=[Lcone  Mcone Scone];
       
        spectraData=pry_adjustedBaylor(wavelengths,TheSensors.conepeaks);
        dpy.coneSpectra=spectraData;
        sensors=dpy.coneSpectra;
        led_tetra_doScan(session,dpy,expt);   %load new stim and run
    end
end

%Output final cone peaks and end of session notification
disp('               Y pressed. Satisfied with final adjustment.')
if strcmp(StimCode,'L'); %L cone isolation
    disp(['Cone Peaks:  ', num2str(Lcone), '  ', num2str(MPcone), '  ', num2str(Mcone), '  ', num2str(Scone)]);
elseif strcmp(StimCode,'MP'); % M' cone isolation
    disp(['Cone Peaks:  ', num2str(Lcone), '  ', num2str(MPcone), '  ', num2str(Mcone), '  ', num2str(Scone)]);
elseif strcmp(StimCode,'M'); % M cone isolation
    disp(['Cone Peaks:  ', num2str(Lcone), '  ', num2str(MPcone), '  ', num2str(Mcone), '  ', num2str(Scone)]);
elseif strcmp(StimCode,'MS'); % MS cone isolation
    disp(['Cone Peaks:  ', num2str(Lcone), '  ', num2str(Mcone), '  ', num2str(MScone), '  ', num2str(Scone)]);
elseif strcmp(StimCode,'S'); % S cone isolation
    disp(['Cone Peaks:  ', num2str(Lcone), '  ', num2str(MPcone), '  ', num2str(Mcone), '  ', num2str(Scone)]);
end
disp ('              End of Session')
ListenChar(0); %turn off suppression of keyboard output

%% Save data in current folder
filename=['TetraExpt',num2str(ExptID), '_StimCode_', (StimCode), '_ID', num2str(SubjectID),'_Session', num2str(SessionNum)];  %outputs filename as e.g. 'TetraExpt1_StimCode_M_ID1_Session1'
FinalConepeaksFilename=['TetraExpt',num2str(ExptID),'_ID', num2str(SubjectID),'_Session', num2str(SessionNum),'_ConeIsolated_',(StimCode)]; %outputs filename as e.g. 'TetraExpt1_ID1_Session1_FinalSetting_M'

save((filename)) % save out full session
%save((FinalConepeaksFilename),TheSensors.conepeaks) %this doesn't work....

%% Close Session
closedSession=pry_closeSession(session);
disp(closedSession);
clear all;
