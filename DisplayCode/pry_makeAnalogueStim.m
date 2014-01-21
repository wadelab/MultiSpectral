function stim=pry_makeAnalogueStim(session,display,stim)
%  stim=pry_makeAnalogueStim(session,stim)
% The heart of our code right now. 
% stim should already have a stim.params field
% stim.params.temporal
% stim.params.color
% stim.params.type (='analogue','PWM')
% Session must be defined so that we have access to channel information =
% e.g. refresh rate
% Display will contain information on the LEDs. It will already have the
% cone2LED matrix defined.
% These things can be faked to test the makeAnalogueStim function
% This function simply returns a set of LED voltage sequences (and array
% nTimepoints x nChannels)
% This, in turn, defines a single instance of the stimulus. It will last
% for a certain number of seconds (stim.temporal.duration)
% Modulate at a certain rate (stim.temporal.rate)
% Modulation will be either square or sine wave (stim.temporal.flickerType)
% Modulation will be along a particular cone contrast direction
% (stim.params.color.stimLMS.dir)
% With a particular RMS amplitude (stim.params.color.stimLMS.scale)

