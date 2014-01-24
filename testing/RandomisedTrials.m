clear all;

% Load in a set of real calibration data obtained from our Prysmatix box
spectraAll=load('visibleLED.mat');
figure(1);
h=plot(400:2:700,spectraAll.linterp(:,[1 3 5]));
set(h(1),'Color',[0 0 1]);
set(h(2),'Color',[0 1 0]);
set(h(3),'Color',[1 0 0]);

session=pry_openSession(1:3,0,1);
disp(session.analogue.session);

%%
session.analogue.session.Rate=1000;



for x=1:5   % no of trials
    
    t=rand %Creates random number between 0 and 1
    if t<0.5   % 50% of the time
        for f=[5, 15]  
            stim.temporal.freq=f; % freq = 5 then 15
            stim.temporal.duration=5; % s
            stim.chrom.stimLMS.dir=[0 0 1]; % S cone isolating
            stim.chrom.stimLMS.cont=0.5; % 10% contrast

            dpy.maxValue=4.9; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
            dpy.baseValue=2.5;

            dpy.spectra=spectraAll.linterp(:,[1 3 5]);
            dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
            dpy.backRGB.dir=[0 0 1];
            dpy.backRGB.scale=1;

            stimulus=pry_makeAnalogueStim(dpy,session,stim);

            stimulus.data;
            stimulus.data(end,:)=5.5;
            max(stimulus.data(:))
            min(stimulus.data(:))
            max(stimulus.LEDContrast)
            session.analogue.session.queueOutputData(stimulus.data);
            session.analogue.session.startForeground();
            pause(1)
        end
    else     % rest of the time
        for f=[15, 5];      %There is probably a neater way to do this without copying all this code
            stim.temporal.freq=f; % freq = 15 then 5
            stim.temporal.duration=5; % s
            stim.chrom.stimLMS.dir=[0 0 1]; % S cone isolating
            stim.chrom.stimLMS.cont=0.5; % 10% contrast

            dpy.maxValue=4.9; % These values are specific to  the pkm device: they are the biggest voltage and the voltage we want to modulate around
            dpy.baseValue=2.5;

            dpy.spectra=spectraAll.linterp(:,[1 3 5]);
            dpy.spectra=dpy.spectra./(max(dpy.spectra(:)));
            dpy.backRGB.dir=[0 0 1];
            dpy.backRGB.scale=1;

            stimulus=pry_makeAnalogueStim(dpy,session,stim); 

            stimulus.data;
            stimulus.data(end,:)=5.5;
            max(stimulus.data(:))
            min(stimulus.data(:))
            max(stimulus.LEDContrast)
            session.analogue.session.queueOutputData(stimulus.data);
            session.analogue.session.startForeground();
            pause(1)
        end
    end
    

   

pause(2)
end






%%



closedSession=pry_closeSession(session);
    