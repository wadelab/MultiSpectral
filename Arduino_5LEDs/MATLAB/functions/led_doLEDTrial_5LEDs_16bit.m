function response=led_doLEDTrial_5LEDs(dpy,stim, q,serialObject,dummyFlag)
% function response=led_doLEDTrial(dpy,stimLMS, q,serialObject)
% Returns 0 or 1 for wrong/right
% Example of how to call:
%     response=led_doLEDTrial_5LEDs(dpy,stim,q,s); % This should return 0 for an incorrect answer and 1 for correct
% 05/2015: LEW and ARW Wrote it.


if (nargin < 5)
    dummyFlag=0;
end

signalInterval=fix(rand(1,1)*2)+1; % 1 or 2
fprintf('\nCorrect response is %d\n',signalInterval);


for thisInterval= 1:2
    pause(.5);
    %sound(sin(linspace(1,650*2*pi,1000))/4,8000); % Do a beep
    %pause(.4); %pause after beep
    
    if (thisInterval == signalInterval) % Is this is the interval with the modulation
       
        % Compute the LED levels we want
        
        stim.LEDvals=led_arduinoConeIsolationLMS(dpy,stim.stimLMS);
        
        
        
        LEDoutputAmps=round(((stim.LEDvals.dir)*(stim.LEDvals.scale)*(2^(dpy.bitDepth)-1)))';
        LEDoutput=LEDoutputAmps/2; % Because we modulate about a mean.
        
    else
        LEDoutput=zeros((dpy.nLEDsToUse),1)'; % Just zero
    end
    
    
    if (isobject(serialObject))

            fwrite(serialObject,uint16(LEDoutput),'uint16','le'); % The 'le' says 'little endian'.. In other words, we send the least significant byte first and the most significant byte second.
            fwrite(serialObject,uint16(dpy.LEDbaseLevel),'uint16','le');
            fwrite(serialObject,uint16(dpy.modulationRateHz*256),'uint16','le'); % Because this is now 16 bit we can specify it more precisely
            %pause(.1)
            sound(sin(linspace(1,650*2*pi,1000))/4,8000);
            
            disp(serialObject.ValuesSent);
            disp(LEDoutput);
            disp(dpy.LEDbaseLevel);
            disp(dpy.modulationRateHz);
            pause(.8);
            
            if thisInterval==1;
                pause(.2)
            else
                %no pause if end of stim presentation and awaiting response
                sound(sin(linspace(1,800*2*pi,1000))/4,4000); % Do a slightly different beep to indicate a response is required
            end
       
    end
    
end
% Now poll the keybaord and get a response (1 or 2)
% Flush the keyboard buffer first
if (~dummyFlag) % If this was a dummy trial then don't require a key press
    FlushEvents;
    a=GetChar;
    if (a =='q')
        response=-1;
    else
        
        response=(str2num(a) == signalInterval);
    end
    
    if (response==1)
        disp('Right!')
        sound(sin(linspace(1,400*2*pi,1000))/5,4000); % Do a slightly different beep to indicate a response is required
        
    else
        disp('Wrong');
        sound(sin(linspace(1,900*2*pi,1000))/6,4000); % Do a slightly different beep to indicate a response is required
        
    end
    
    pause(.2);
    % Here you can feed back answers to Quest or whatever and compute the
    % next contrast to use
else % If this was a dummy trial then don't require a key press
    response = -1;
end
