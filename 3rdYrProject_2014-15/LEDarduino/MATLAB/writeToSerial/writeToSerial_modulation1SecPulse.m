
s=serial('/dev/cu.usbmodem5d11');%,'BaudRate',9600);
fopen(s);

pause(1);
disp('Running');
LEDamps=uint8([0,0,0,128,128,0,0]);
LEDbaseLevel=uint8([0,0,0,128,128,0,0]);
nLEDs=length(LEDamps);


for r= 1:2
    sound(sin(linspace(1,500*2*pi,2000))); 
    pause(.5);
   fwrite(s,LEDamps,'uint8'); 
   fwrite(s,LEDbaseLevel,'uint8'); 

   disp(s.ValuesSent);
   
   pause(4);
end

fclose(s);
