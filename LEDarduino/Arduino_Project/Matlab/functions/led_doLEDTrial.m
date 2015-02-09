function response=led_doLEDTrial(dpy,stim, q,serialObject)
% function response=led_doLEDTrial(dpy,stimLMS, q,serialObject)
% Returns 0 or 1 for wrong/right
%



signalInterval=fix(rand(1,1)*2)+1; % 1 or 2
fprintf('\nCorrect response is %d\n',signalInterval);


for thisInterval= 1:2
    pause(.5);
    sound(sin(linspace(1,500*2*pi,1000))/4,8000); % Do a beep
    pause(.4);
    
    if (thisInterval == signalInterval) % Is this is the interval with the modulation
        % 1111
        % Compute the LED levels we want
        
        stim.LEDvals=led_arduinoConeIsolationLMS(dpy,stim.stimLMS);
        
        
        LEDoutputAmps=((stim.LEDvals.dir)*(stim.LEDvals.scale)*(2^(dpy.bitDepth)-1)*dpy.backLED.scale);
        LEDoutput=dpy.LEDamps; % Set everything to the default level
        LEDoutput(dpy.LEDsToUse)=LEDoutputAmps;
        
        
    else
        LEDoutput=dpy.LEDamps; % Just zero
    end
    
    fprintf('Led output levels = %d,%d,%d,%d,%d,%d,%d',LEDoutput);
    
    if (isobject(serialObject))
        
           
            fwrite(serialObject,LEDoutput,'uint8');
            fwrite(serialObject,dpy.LEDbaseLevel,'uint8');
            disp(serialObject.ValuesSent);
            %disp(LEDoutput);
            %disp(dpy.LEDbaseLevel);
            pause(1.0);
            
        
    end
    
end

sound(sin(linspace(1,650*2*pi,1000))/4,8000); % Do a slightly different beep to indicate a response is required
% Now poll the keybaord and get a response (1 or 2)
% Flush the keyboard buffer first
FlushEvents;
a=GetChar;
response=(str2num(a) == signalInterval)
if (response)
    disp('Right!')
    sound(sin(linspace(1,700*2*pi,1000))/4,8000); % Do a slightly different beep to indicate a response is required

else
    disp('Wrong');
        sound(sin(linspace(1,200*2*pi,1000))/4,8000); % Do a slightly different beep to indicate a response is required

end
pause(.2);
% Here you can feed back answers to Quest or whatever and compute the
% next contrast to use
