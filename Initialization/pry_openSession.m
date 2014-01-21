function session=pry_openSession(channels,digitalFlag,analogueFlag)
%  session=pryOpenSession(channels,digitalFlag,analogueFlag)
% Opens a session on the NI board. Can have multiple sessions open at once.
% ARW, LW 040313

% To add: try, catch. Check for already open session. Think about adding
% digital lines as well. 
% Note: Must haver release function..

if (analogueFlag)
    session.analogue.session = daq.createSession('ni');
    session.analogue.channel= session.analogue.session.addAnalogOutputChannel('cDAQ1Mod2', channels, 'Voltage');
end

