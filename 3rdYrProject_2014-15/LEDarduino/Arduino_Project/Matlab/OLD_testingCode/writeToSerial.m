s=serial('COM4');
fopen(s);
for t=1:9
fprintf(s,int2str(t));
pause(1);
end

fclose(s);
