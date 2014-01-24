function runstim=pry_runStim(analogue,digital)

% runstim = pry_runStim(analogue,digital)

% Loads analogue and/or digital stimulus onto the board then run
% simultaneously.

% Use 1 to indicate the stimulus that is to be initiated, or 0 if that stimulus is not present. 

if (analogue==1 && digital==1)
    s.queueOutputData(stimAnalogue);
    s.queueOutputData(stimDigital);
    runstim.analoguedigital = s.startForeground(:); %check this will simultaneously run both sessions
elseif (analogue==1 && digital==0)
    s.queueOutputData(stimAnalogue);
    runstim.analogue = s.startForeground(stimAnalogue);
elseif (analogue==0 && digital==1)
    s.queueOutputData(stimDigital);
    runstim.digital = s.startForeground(stimDigital);
elseif (analogue~=1 && digital~=1)
    error('Please select an analogue and/or digital stimulus to run')
end

end


