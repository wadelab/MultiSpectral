onsetArray = zeros(1,10);
for a=1:10
    onsetArray(1,a) = scan.trials(a).onsetTime;     %onsetArray = list of onset times
end

par.onset=sort(onsetArray);     %Onset times in chronological order
par.cond=trialOrder;            %Corresponding trial numbers

labelArray = ['lum0hz   '; 'lum4hz   '; 'lum8hz   '; 'lum16hz  '; 'lum32hz  '; 'sCone0hz '; 'sCone4hz '; 'sCone8hz '; 'sCone16hz'; 'sCone32hz']; 


for f=1:10
    par.label(f)=cellstr(labelArray(par.cond(f),:));   %Corresponding condition label
end

    
writeParfile(par)