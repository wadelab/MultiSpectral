function response=tetra_led_doLEDTrial(dpy,stim, q,serialObject,dummyFlag)
% function response=led_doLEDTrial(dpy,stimLMS, q,serialObject)
% Returns 0 or 1 for wrong/right
%


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
        
        stim.LEDvals=tetra_led_arduinoConeIsolationLMS(dpy,stim.stimLMS);
        
        
        
        LEDoutputAmps=round(((stim.LEDvals.dir)*(stim.LEDvals.scale)*(2^(dpy.bitDepth)-1)))';
        LEDoutput=LEDoutputAmps/2;
        
    else
        LEDoutput=zeros((dpy.nLEDsToUse),1)'; % Just zero
    end
    
    
    if (isobject(serialObject))

            fwrite(serialObject,uint8(LEDoutput),'uint8');
            fwrite(serialObject,uint8(dpy.LEDbaseLevel),'uint8');
            %pause(.1)
            sound(sin(linspace(1,650*2*pi,1000))/4,8000);
            
            disp(serialObject.ValuesSent);
            disp(LEDoutput);
            disp(dpy.LEDbaseLevel);
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
