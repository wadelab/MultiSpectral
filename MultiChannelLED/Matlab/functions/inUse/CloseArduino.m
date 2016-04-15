function CloseArduino(s)
%close down arduino connection after setting all values to zero

if (isobject(s)) % This is shorthand for ' if s>0 '
    % Shut down arduino to save the LEDs
      fwrite(s,zeros(5,1),'uint16');
      fwrite(s,zeros(5,1),'int8');
      fwrite(s,zeros(5,1),'uint16');
      fwrite(s,zeros(2,1),'uint16');
      fwrite(s,zeros(5,1),'int8');
      disp('Turning off LEDs');
%       pause(0.5)
      fclose(s);
end
end