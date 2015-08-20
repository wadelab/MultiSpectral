function s=ConnectToArduino
% ConnectToArduino

CONNECT_TO_ARDUINO = 1; % For testing on any computer

if(~isempty(instrfind))
   fclose(instrfind);
end

if (CONNECT_TO_ARDUINO)  
        system('say connecting to arduino');

    s=serial('/dev/tty.usbmodem5d11');%,'BaudRate',9600);q
    fopen(s);
    disp('*** Connecting to Arduino');
    
else
    s=0;
end
end