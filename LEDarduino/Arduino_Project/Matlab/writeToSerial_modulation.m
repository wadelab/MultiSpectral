
s=serial('COM4');
fopen(s);



pause(2);

LEDamps=[255,0,0,0,0,0,0];

nLEDs=length(LEDamps);

for thisLED=1:nLEDs % Write out 7 values on the serial port. The arduino is expecting this...
    
    disp(thisLED);
    fwrite(s,char(LEDamps(thisLED)));
    pause(.1);
end

fclose(s);
