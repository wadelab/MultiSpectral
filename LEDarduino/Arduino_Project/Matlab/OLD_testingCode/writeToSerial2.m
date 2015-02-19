
s=serial('COM4');
fopen(s);



pause(2);


for t=1:9
    disp(t);
    fwrite(s,char(t+47));
    pause(1);
end

fclose(s);
