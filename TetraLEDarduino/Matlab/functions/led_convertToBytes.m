function [lowByte,highByte]=led_convertToBytes(inputVal)
% Enter a 16bit signed input, returns that number converted to lower and
% upper bytes

    %remove sign
    inputVal = abs(inputVal);
    
    Bytes = typecast(inputVal,'int8');
    lowByte = Bytes(1);
    highByte = Bytes(2);
end

% %Use 'typecast' here to convert the int16 inputVal into the two int8 bytes
% Bytes=typecast(inputVal,'int8');
% lowByte = Bytes(1);
% highByte = Bytes(2);
% 
% end
    
%  highByte=uint8(fix(int16(abs(inputVal)),-8))
%  lowByte=uint8(bitand(uint16(inputVal),255));
% % Sign?
% if (sign(inputVal)==-1)
%                       % Set the high bit on the high byte to 1
%      highByte=bitor(uint8(highByte), uint8(128));
%      disp('neg')
% end
% 
%                