function response=tetra_led_doLEDTrial_5LEDs(dpy,stim, q,serialObject,dummyFlag)
% function response=led_doLEDTrial(dpy,stimLMS, q,serialObject)
% Returns 0 or 1 for wrong/right
%


if (nargin < 5)
    dummyFlag=0;
end

%randomly select the interval containing target. N.B. interval 1 always
%contains a burst of stim for PR adaptation
signalInterval=fix(rand(1,1)*2)+2; % 2 or 3
fprintf('\nCorrect response is %d\n',signalInterval);


for thisInterval= 1:3
    pause(.5);
    %sound(sin(linspace(1,650*2*pi,1000))/4,8000); % Do a beep
    %pause(.4); %pause after beep
        
    if thisInterval == 1 
        %if first interval, set to the adapting stim
        % Compute the LED levels we want
        adaptStim.stimLMS=stim.stimLMS; %we don't want to override the stimLMS values
        adaptStim.stimLMS.dir=[1,0,1,0]; % set adaptation to L and M isolating stim
        adaptStim.stimLMS.scale=0.015; % 2% contrast for now
        dpy.PulseDuration=3; %3seconds of adapt stim
        stim.LEDvals=tetra_led_arduinoConeIsolationLMS(dpy,adaptStim.stimLMS);
        LEDoutputAmps=round(((stim.LEDvals.dir)*(stim.LEDvals.scale)*(2^(dpy.bitDepth)-1)))';
        LEDoutput=LEDoutputAmps/2;
        
        sound(sin(linspace(1,650*2*pi,5000))/4,8000);

        
    elseif (thisInterval == signalInterval) % Is this is the interval with the modulation
       
        % Compute the LED levels we want
        stim.stimLMS.dir=stim.stimLMS.dir+dpy.noiseLevel; %add a value to all cones for a lum element
        dpy.PulseDuration=1; %1second of adapt stim
        stim.stimLMS.scale=stim.stimLMS.scale;
        stim.LEDvals=tetra_led_arduinoConeIsolationLMS(dpy,stim.stimLMS);
        
        LEDoutputAmps=round(((stim.LEDvals.dir)*(stim.LEDvals.scale)*(2^(dpy.bitDepth)-1)))';
        LEDoutput=LEDoutputAmps/2;
        sound(sin(linspace(1,650*2*pi,1000))/4,8000);

        
    else
        %for non-target interval add noise
        dpy.PulseDuration=1; %1second of adapt stim

        stimNonTarget.stimLMS=stim.stimLMS; %we don't want to overide anything in stim.stimLMS
        stimNonTarget.stimLMS.dir=[0 0 0 0]+dpy.noiseLevel; %make the dir of the non-target a low level lum value
        stimNonTarget.stimLMS.scale=dpy.noiseScale; %use same as for target
        stim.LEDvals=tetra_led_arduinoConeIsolationLMS(dpy,stimNonTarget.stimLMS);
        
        LEDoutputAmps=round(((stim.LEDvals.dir)*(stim.LEDvals.scale)*(2^(dpy.bitDepth)-1)))';
        LEDoutput=LEDoutputAmps/2;
        
        sound(sin(linspace(1,650*2*pi,1000))/4,8000);

    end
    
    
    if (isobject(serialObject))

            % We are going to send data out byte by byte to avoid any
            % issues with endianness
            for thisLed=1:dpy.nLEDsToUse
                % break each value in LEDoutput into a 16 bit int with a
                % high and low end. Send the signed high and low bit
                % separately.
                inputVal=int16(LEDoutput(thisLed));
                %record the sign of the output
                if (sign(LEDoutput(thisLed))==-1) 
                    LEDampSign(thisLed)=1;
                else
                    LEDampSign(thisLed)=0;
                end
                %save out two bytes from the 16-bit integer (using absolute
                %unsigned value - it will get converted in arduino if
                %necessary)
                [thisLowVal,thisHighVal]=led_convertToBytes(inputVal);
                
                     
                 fwrite(serialObject,int8(thisLowVal),'int8');
                 fwrite(serialObject,int8(thisHighVal),'int8');
            end % Next LED value for modulation
            
            fwrite(serialObject,int8(LEDampSign),'int8'); %indicates whether number is pos (0) or neg (1)
            fwrite(serialObject,int16(dpy.LEDbaseLevel),'int16');
            fwrite(serialObject,int16(dpy.modulationRateHz*256),'int16');
            fwrite(serialObject,int8(dpy.PulseDuration),'int8');

            %pause(.1)
            

            
%             %disp(serialObject.ValuesSent);
%             fprintf('\nfirst 5bytes sent %d',LEDoutput)
%             %disp(LEDoutput);
%             fprintf('\nsecond set of 5 bytes %d',dpy.LEDbaseLevel);
%             fprintf('\nmodulation rate %d',dpy.modulationRateHz*256);
%             
            disp(serialObject.ValuesSent);
            disp(LEDoutput);
            disp(dpy.LEDbaseLevel);
            disp(dpy.modulationRateHz);
                        
            
            if thisInterval==1;
                pause(2)
            elseif thisInterval==2;
                pause(0.5)
            else continue
                %no pause if end of stim presentation and awaiting response
                %sound(sin(linspace(1,800*2*pi,1000))/4,4000); % Do a slightly different beep to indicate a response is required
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
        
        response=(str2num(a) == signalInterval-1);
    end
    
    if (response==1)
        disp('Right!')
        sound(sin(linspace(1,400*2*pi,1000))/5,5000); % Do a slightly different beep to indicate a response is required
        
    else
        disp('Wrong');
        sound(sin(linspace(1,200*2*pi,1000))/5,3000); % Do a slightly different beep to indicate a response is required
        
    end
    
    pause(.2)
    % Here you can feed back answers to Quest or whatever and compute the
    % next contrast to use
else % If this was a dummy trial then don't require a key press
    response = -1;
end
