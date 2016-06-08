function s=ConnectToArduino
% ConnectToArduino

CONNECT_TO_ARDUINO = 1; % For testing on any computer

if(~isempty(instrfind))
   fclose(instrfind);
end

if (CONNECT_TO_ARDUINO)  
        Speak('Connecting','Daniel');

    s=serial('/dev/cu.usbmodem411');%,'BaudRate',9600);q
    fopen(s);
    disp('*** Connecting to Arduino');
    
else
    s=0;
end
end