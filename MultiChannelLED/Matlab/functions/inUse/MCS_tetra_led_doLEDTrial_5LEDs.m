function [response,dpy]=MCS_tetra_led_doLEDTrial_5LEDs(dpy,stim,serialObject,dummyFlag)
% function [response,dpy]=MCS_tetra_led_doLEDTrial_5LEDs(dpy,stim,serialObject,dummyFlag)
% Returns 0 or 1 for wrong/right
% LEW

ListenChar(2) %so keyboard presses are not outputted in the command window
if (nargin < 5)
    dummyFlag=0;
end

signalInterval=fix(rand(1,1)*2)+1; % 1 or 2
fprintf('\nCorrect response is %d\n',signalInterval);
try
dpy.TargetInterval(dpy.theTrial,1)=signalInterval; %save out the interval containing target
catch %if dummy run don't save it - dpy.theTrial only specified after dummy
end

for thisInterval= 1:2

    
    if (thisInterval == signalInterval) % Is this is the interval with the modulation
     
        % Compute the LED levels we want
        stimOne=stim;
        stimOne.stimLMS.dir=stimOne.stimLMS.dir; 
        [stimTarget,dpy]=tetra_led_arduinoConeIsolationLMS(dpy,stimOne.stimLMS);
        try
        dpy.contrastLevelTested(dpy.theTrial,1)=dpy.stimLMS.scale; %don't save if just the dummy
        catch
        end
               
        LEDoutputAmps=round(((stimTarget.dir)*(stimTarget.scale)*(2^(dpy.bitDepth))))';
        LEDoutput=LEDoutputAmps/2;
        %save out the amp values into dpy
        dpy.targetLEDoutput(dpy.theTrial,:)=LEDoutput;
        dpy.targetLEDdir(dpy.theTrial,:)=stimTarget.dir';
        dpy.targetStimLMSdir(dpy.theTrial,:)=stimOne.stimLMS.dir;
        dpy.led2llms=stimTarget.led2llms;
        dpy.llms2led=stimTarget.llms2led;
        
    else
        LEDoutput=zeros(dpy.nLEDsTotal,1)';
    end
        
    
    
    if (isobject(serialObject))
            sound(sin(linspace(1,400*2*pi,1000))/3,4000); % Do a slightly different beep to indicate a response is required
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
                
                 % write the low and high value LED amps to arduino    
                 fwrite(serialObject,int8(thisLowVal),'int8');
                 fwrite(serialObject,int8(thisHighVal),'int8');
            end % Next LED value for modulation
            
            
            fwrite(serialObject,int8(LEDampSign),'int8'); %indicates whether each LED amp is pos (0) or neg (1)
            fwrite(serialObject,int16(dpy.LEDbaseLevel),'int16'); %the baselevels amps
            fwrite(serialObject,int16(dpy.modulationRateHz*256),'int16'); %the modulation rate
            fwrite(serialObject,int8(dpy.baselevelsLEDS),'int8'); %send the scaling info for the noise - rename this eventually
                  
            %output the values used
            disp(serialObject.ValuesSent);
            disp(LEDoutput);
            disp(dpy.LEDbaseLevel);
            disp(dpy.modulationRateHz);                        
            
            if thisInterval==1;
                pause(0.8)
            else continue
                %no pause if end of stim presentation and awaiting response
                %sound(sin(linspace(1,800*2*pi,1000))/4,4000); % Do a slightly different beep to indicate a response is required
            end
       
    end
    
end
% Now poll the keyboard and get a response (1 or 2)
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
        sound(sin(linspace(1,650*2*pi,1000))/3,8000);
        %sound(sin(linspace(1,400*2*pi,1000))/5,5000); % Do a slightly different beep to indicate a response is required
        dpy.Response(dpy.theTrial,1)=1; %1=hit, 0=miss

    else
        disp('Wrong');
        sound(sin(linspace(1,50*2*pi,1000))/3,8000); % Do a slightly different beep to indicate a response is required
        dpy.Response(dpy.theTrial,1)=0; %0=miss

    end
    
    pause(.5)
else % If this was a dummy trial then don't require a key press
    response = -1;
end
