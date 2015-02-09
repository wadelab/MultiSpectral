% writeToSerial_modulation1SecPulse_012715_1

s=serial('/dev/tty.usbmodem5d11');%,'BaudRate',9600);
fopen(s);

pause(1);
disp('Running');
LEDamps=uint8([0,0,0,0,0,0,0]);
LEDbaseLevel=uint8([0,0,0,0,0,0,0]); % THis is convenient and makes sure that everything is off by default
nLEDs=length(LEDamps);
LEDBackground=128;



% This version of the code shows how to do two things:
% Ask Lauren's code for a set of LED amplitudes corresponding to a
% particular direction and contrast in LMS space
% 2: Present two flicker intervals with a random sequence

LMSDirection=[1 1 1]; % [1 1 1] is a pure achroamtic luminance modulation
LMSContrast = 2;
LEDsToUse=[2 4 7]; % Which LEDs we want to be active in this expt

signalInterval=fix(rand(1,1)*2)+1 % 1 or 2

LEDbaseLevel(LEDsToUse)=LEDBackground; % Set just the LEDs we're using to be on a 50%

for thisTrial=1:3
    
    for thisInterval= 1:2
        sound(sin(linspace(1,500*2*pi,2000))); % Do a beep
        pause(.5);
        
        if (thisInterval == signalInterval) % Is this is the interval with the modulation
            % 1111
            % Compute the LED levels we want
            LEDvals=ArduinoConeIsolationLMS(LMSContrast,LMSDirection,LEDsToUse)
            LEDoutputAmps=(LEDvals-LEDBackground);
            LEDoutput=LEDamps;
            LEDoutput(LEDsToUse)=LEDoutputAmps;
            
            
        else
            LEDoutput=LEDamps; % Just zero
        end
        
        fprintf('Led output levels = %d,%d,%d,%d,%d,%d,%d',LEDoutput);
        fwrite(s,LEDoutput,'uint8');
        fwrite(s,LEDbaseLevel,'uint8');
        
        disp(s.ValuesSent);
        
        
        pause(4);
    end
    
    
    % Now poll the keybaord and get a response (1 or 2)
    
    a=GetChar;
    if (str2num(a) == thisInterval)
        disp('Right!')
    else
        disp('Wrong');
    end
     % Here you can feed back answers to QUest or whatever and compute the
     % next contrast to use
    
  
     
end % Next trial


fclose(s);

