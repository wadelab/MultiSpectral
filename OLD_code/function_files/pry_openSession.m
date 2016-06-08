function session=pry_openSession(channels,digitalFlag,analogueFlag)
% session = pry_openSession(channels,digitalFlag,analogueFlag)
% 
% Opens a session on the NI board.
% ARW, LW 040313
% Use 1 (Yes) and 0 (No) to indicate whether or not to add digital and analogue
% channels (at least one of these needs to be selected). 
% 'channels' must be entered as (e.g.) 1:3 for 3 channels
% 
% For example, to add 3 channels that are analogue only, enter: 
% 
% session = pry_openSession(1:3,0,1)


   

%% Check that a valid number of channels has been entered. Error messages will appear if zero channels, or more than the available number of channels, is entered.
if length(channels)<=0
    error('Must enter more than one channel')
elseif length(channels)>5
    error('You have selected more channels than are available. Maximum 5 channels.')
end
    
if ((digitalFlag~=1)&&(analogueFlag~=1))
    error('You must select one digital and/or analogue session by entering 1 in digitalFlag and/or analogueFlag for: session=pry_openSession(channels,digitalFlag,analogueFlag)')
end

%% If a correct number of channels is entered (i.e. 1 to 5 channels), create the analogue and/or digital channels specified by '1' at the appropriate point of the function.
try
    
    if digitalFlag
        session.digital.session = daq.createSession('ni');
        session.digital.channel = session.digital.session.addCounterOutputChannel('cDAQ1Mod1',channels,'PulseGeneration');
    end
    
catch
    error('Cannot assign digital channels');
    
end

try
    
    if analogueFlag
        session.analogue.session = daq.createSession('ni');
        session.analogue.channel = session.analogue.session.addAnalogOutputChannel('cDAQ1Mod2',channels, 'Voltage');
        session.analogue.session.IsContinuous = false;
    end
catch
    error('Cannot assign analogue channels - clearing all sessions');
    if (digitalFlag)
        session.digital.session.release();
    end
    
end


