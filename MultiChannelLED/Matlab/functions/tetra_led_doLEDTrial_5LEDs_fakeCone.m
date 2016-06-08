function response=tetra_led_doLEDTrial_5LEDs_fakeCone(dpy,stim, q,serialObject,dummyFlag)
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
        stim.stimLMS.dir=stim.stimLMS.dir; %add a value to all cones for a lum element
        stim.stimLMS.scale=stim.stimLMS.scale;
        stim.LEDvals=tetra_led_arduinoConeIsolationLMS_fakeCone(dpy,stim.stimLMS);
        
        
        
        LEDoutputAmps=round(((stim.LEDvals.dir)*(stim.LEDvals.scale)*(2^(dpy.bitDepth)-1)))';
        LEDoutput=LEDoutputAmps/2;
        
    else

        LEDoutput=zeros((dpy.nLEDsToUse),1)'; % Just zero
    end
    
    
    if (isobject(serialObject))

            sound(sin(linspace(1,650*2*pi,1000))/4,8000);
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
                pause(1)
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
        
        response=(str2num(a) == signalInterval);
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
